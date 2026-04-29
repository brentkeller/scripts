#requires -Version 7

<#
.SYNOPSIS
  Restore a .bak from the bind-mounted backup folder into the sql2025 container.

.EXAMPLE
  ./Restore-DockerDb.ps1 -Database dev-export -BakName dev-export-2025.12.23-sql2019.bak

.EXAMPLE
  # Pick the newest bak matching a prefix
  ./Restore-DockerDb.ps1 -Database dev-export -Latest
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Database,
    [string] $BakName,
    [switch] $Latest,
    [string] $Container        = 'sql2025',
    [string] $HostBackupDir    = 'C:\sql\docker\sql2025\backup',
    [string] $ContainerBakDir  = '/var/opt/mssql/backup',
    [string] $ContainerDataDir = '/var/opt/mssql/data',
    [int]    $CompatLevel,
    [string] $SaPassword
)

$ErrorActionPreference = 'Stop'

if (-not $BakName -and -not $Latest) {
    throw "Specify -BakName <file.bak> or -Latest"
}

if ($Latest) {
    $candidate = Get-ChildItem -Path $HostBackupDir -Filter "$Database-*.bak" |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $candidate) { throw "No $Database-*.bak files in $HostBackupDir" }
    $BakName = $candidate.Name
    Write-Host "Latest backup: $BakName"
}

$hostPath      = Join-Path $HostBackupDir $BakName
$containerPath = "$ContainerBakDir/$BakName"

if (-not (Test-Path $hostPath)) {
    throw "Backup file not found: $hostPath"
}

$invoke = Join-Path $PSScriptRoot 'Invoke-DockerSql.ps1'

if (-not $SaPassword) { $SaPassword = $env:SA_PASSWORD }
if (-not $SaPassword) {
    $sec = Read-Host -AsSecureString "SA password for $Container"
    $SaPassword = [System.Net.NetworkCredential]::new('', $sec).Password
}

# Read the logical file names out of the .bak so MOVE clauses are correct
# regardless of what the source DB was named.
Write-Host "Reading file list from $BakName..."
$fileListSql = "RESTORE FILELISTONLY FROM DISK = N'$containerPath';"
$fileListRaw = docker exec -i $Container /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $SaPassword -C -b -h -1 -W -s '|' `
    -Q $fileListSql 2>&1
if ($LASTEXITCODE -ne 0) { throw "RESTORE FILELISTONLY failed:`n$fileListRaw" }

$dataLogical = $null; $logLogical = $null
foreach ($line in $fileListRaw) {
    $cols = $line -split '\|'
    if ($cols.Count -lt 3) { continue }
    $logical = $cols[0].Trim()
    $type    = $cols[2].Trim()
    if ($type -eq 'D' -and -not $dataLogical) { $dataLogical = $logical }
    elseif ($type -eq 'L' -and -not $logLogical) { $logLogical = $logical }
}
if (-not $dataLogical -or -not $logLogical) {
    throw "Could not parse FILELISTONLY output:`n$fileListRaw"
}
Write-Host "  data: $dataLogical    log: $logLogical"

$dataTarget = "$ContainerDataDir/$Database.mdf"
$logTarget  = "$ContainerDataDir/${Database}_log.ldf"

$compatSql = if ($CompatLevel) {
    "ALTER DATABASE [$Database] SET COMPATIBILITY_LEVEL = $CompatLevel;"
} else { '' }

$tsql = @"
IF DB_ID(N'$Database') IS NOT NULL
    ALTER DATABASE [$Database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE [$Database] FROM DISK = N'$containerPath'
WITH FILE = 1,
     MOVE N'$dataLogical' TO N'$dataTarget',
     MOVE N'$logLogical'  TO N'$logTarget',
     NOUNLOAD, REPLACE, STATS = 5;

ALTER DATABASE [$Database] SET MULTI_USER;
ALTER DATABASE [$Database] SET RECOVERY SIMPLE WITH NO_WAIT;
$compatSql

USE [$Database];
DBCC SHRINKFILE (N'$logLogical', 0, TRUNCATEONLY);
"@

Write-Host "Restoring [$Database] from $BakName..."
& $invoke -Container $Container -SaPassword $SaPassword -Query $tsql
Write-Host "Done."
