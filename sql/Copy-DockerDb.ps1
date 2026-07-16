#requires -Version 7

<#
.SYNOPSIS
  Copy a database to a new name inside the sql2025 container (backup + restore-as).

.DESCRIPTION
  Backs the source DB up to a staging path on the container's named volume, then
  restores it under a new name with fresh data/log files. Prompts for two choices
  (unless the matching switch is passed):
    1. Persist a .bak of the source to the Windows backup folder?
    2. If the target DB already exists, overwrite (REPLACE) it?

  Pass -PersistBak / -OverwriteTarget (or their :$false forms) to answer
  non-interactively.

.EXAMPLE
  ./Copy-DockerDb.ps1 -SourceDatabase dev-export -TargetDatabase dev-export-copy
  # prompts for both options

.EXAMPLE
  ./Copy-DockerDb.ps1 -SourceDatabase prod-snap -TargetDatabase scratch `
      -PersistBak:$false -OverwriteTarget
  # no prompts: skip the host .bak, overwrite scratch if it exists
#>

[CmdletBinding()]
param(
    [string] $SourceDatabase,
    [string] $TargetDatabase,
    [switch] $PersistBak,
    [switch] $OverwriteTarget,
    [string] $BakName,
    [string] $Container        = 'sql2025',
    [string] $HostBackupDir    = 'C:\sql\docker\sql2025\backup',
    [string] $StagingDir       = '/var/opt/mssql/backup-staging',
    [string] $ContainerDataDir = '/var/opt/mssql/data',
    [int]    $CompatLevel,
    [string] $SaPassword
)

$ErrorActionPreference = 'Stop'

while (-not $SourceDatabase) {
    $SourceDatabase = (Read-Host 'Source database to copy from').Trim()
}
while (-not $TargetDatabase) {
    $TargetDatabase = (Read-Host 'Target database to copy to').Trim()
}

if ($SourceDatabase -eq $TargetDatabase) {
    throw "Source and target are the same database ([$SourceDatabase])."
}

function Confirm-Choice {
    param([string] $Message, [bool] $DefaultYes = $false)
    $suffix = if ($DefaultYes) { '(Y/n)' } else { '(y/N)' }
    $ans = Read-Host "$Message $suffix"
    if ([string]::IsNullOrWhiteSpace($ans)) { return $DefaultYes }
    return $ans -match '^(y|yes)$'
}

if (-not (Test-Path $HostBackupDir)) {
    throw "Host backup dir not found: $HostBackupDir"
}

if (-not $SaPassword) { $SaPassword = $env:SA_PASSWORD }
if (-not $SaPassword) {
    $sec = Read-Host -AsSecureString "SA password for $Container"
    $SaPassword = [System.Net.NetworkCredential]::new('', $sec).Password
}

$invoke = Join-Path $PSScriptRoot 'Invoke-DockerSql.ps1'

# Small scalar-query helper: returns the single value sqlcmd prints (trimmed).
function Get-SqlScalar {
    param([string] $Sql)
    $out = docker exec -i $Container /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P $SaPassword -C -b -h -1 -W `
        -Q "SET NOCOUNT ON; $Sql" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Query failed:`n$out" }
    ($out | Where-Object { $_ -ne '' } | Select-Object -First 1).Trim()
}

# --- Preflight: source must exist -------------------------------------------
if ((Get-SqlScalar "SELECT CASE WHEN DB_ID(N'$SourceDatabase') IS NULL THEN 0 ELSE 1 END;") -ne '1') {
    throw "Source database [$SourceDatabase] not found in $Container."
}

# --- Option 1: persist a .bak of the source ---------------------------------
$persist = if ($PSBoundParameters.ContainsKey('PersistBak')) {
    [bool]$PersistBak
} else {
    Confirm-Choice "Persist a .bak of [$SourceDatabase] to ${HostBackupDir}?"
}

# --- Option 2: overwrite the target if it already exists --------------------
$targetExists = (Get-SqlScalar "SELECT CASE WHEN DB_ID(N'$TargetDatabase') IS NULL THEN 0 ELSE 1 END;") -eq '1'
if ($targetExists) {
    $overwrite = if ($PSBoundParameters.ContainsKey('OverwriteTarget')) {
        [bool]$OverwriteTarget
    } else {
        Confirm-Choice "Target database [$TargetDatabase] already exists. Overwrite/delete it?"
    }
    if (-not $overwrite) {
        Write-Host "Target [$TargetDatabase] exists and overwrite declined. Aborting."
        return
    }
}

# --- Backup source to staging (named volume, writable by mssql) -------------
if (-not $BakName) {
    $stamp   = Get-Date -Format 'yyyy.MM.dd'
    $BakName = "$SourceDatabase-$stamp-sql2025.bak"
}
$stagingPath = "$StagingDir/$BakName"

docker exec -u root $Container mkdir -p $StagingDir | Out-Null
docker exec -u root $Container chown mssql:root $StagingDir | Out-Null

Write-Host "Backing up [$SourceDatabase] -> $stagingPath (staging)"
& $invoke -Container $Container -SaPassword $SaPassword -Query @"
BACKUP DATABASE [$SourceDatabase] TO DISK = N'$stagingPath'
WITH NOFORMAT, NOINIT, NAME = N'$SourceDatabase-Full Database Backup',
     SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10;
"@

# --- Optionally copy the .bak out to Windows --------------------------------
if ($persist) {
    $hostPath = Join-Path $HostBackupDir $BakName
    if (Test-Path $hostPath) {
        throw "Backup file already exists: $hostPath  (pass a different -BakName or delete it first)"
    }
    Write-Host "Copying $BakName to $HostBackupDir..."
    docker cp "${Container}:$stagingPath" $hostPath
    if ($LASTEXITCODE -ne 0) { throw "docker cp failed (exit $LASTEXITCODE)" }
    $size = '{0:N1} MB' -f ((Get-Item $hostPath).Length / 1MB)
    Write-Host "  saved $hostPath ($size)"
}

# --- Read logical file names so MOVE clauses are correct --------------------
Write-Host "Reading file list from $BakName..."
$fileListSql = "RESTORE FILELISTONLY FROM DISK = N'$stagingPath';"
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

$dataTarget = "$ContainerDataDir/$TargetDatabase.mdf"
$logTarget  = "$ContainerDataDir/${TargetDatabase}_log.ldf"

$compatSql = if ($CompatLevel) {
    "ALTER DATABASE [$TargetDatabase] SET COMPATIBILITY_LEVEL = $CompatLevel;"
} else { '' }

# --- Restore as the target name ---------------------------------------------
$tsql = @"
IF DB_ID(N'$TargetDatabase') IS NOT NULL
    ALTER DATABASE [$TargetDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE [$TargetDatabase] FROM DISK = N'$stagingPath'
WITH FILE = 1,
     MOVE N'$dataLogical' TO N'$dataTarget',
     MOVE N'$logLogical'  TO N'$logTarget',
     NOUNLOAD, REPLACE, STATS = 5;

ALTER DATABASE [$TargetDatabase] SET MULTI_USER;
ALTER DATABASE [$TargetDatabase] SET RECOVERY SIMPLE WITH NO_WAIT;
$compatSql
GO

-- Separate batch: USE resolves the target at compile time, so it must run
-- after the RESTORE batch has actually created the database.
USE [$TargetDatabase];
DBCC SHRINKFILE (N'$logLogical', 0, TRUNCATEONLY);
"@

Write-Host "Restoring copy [$SourceDatabase] -> [$TargetDatabase]..."
& $invoke -Container $Container -SaPassword $SaPassword -Query $tsql

# --- Clean up the staging .bak ----------------------------------------------
docker exec $Container rm -f $stagingPath | Out-Null

Write-Host "Done. [$SourceDatabase] copied to [$TargetDatabase]."
