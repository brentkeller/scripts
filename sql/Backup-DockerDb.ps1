#requires -Version 7

<#
.SYNOPSIS
  Back up a database running in the sql2025 container, landing the .bak in the
  bind-mounted Windows backup folder.

.DESCRIPTION
  SQL Server's BACKUP makes a final DiskChangeFileSize call that fails against
  Docker Desktop bind mounts ('OS error 31'), so we back up to a path on the
  container's named volume, then `docker cp` the file out to Windows.

.EXAMPLE
  ./Backup-DockerDb.ps1 -Database dev-export
  # writes C:\sql\docker\sql2025\backup\dev-export-2026.04.29-sql2025.bak

.EXAMPLE
  ./Backup-DockerDb.ps1 -Database dev-export -BakName custom.bak
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Database,
    [string] $BakName,
    [string] $Container       = 'sql2025',
    [string] $HostBackupDir   = 'C:\sql\docker\sql2025\backup',
    [string] $StagingDir      = '/var/opt/mssql/backup-staging',
    [string] $SaPassword,
    [switch] $ShrinkLogFirst,
    [switch] $KeepInternalCopy
)

$ErrorActionPreference = 'Stop'

if (-not $BakName) {
    $stamp   = Get-Date -Format 'yyyy.MM.dd'
    $BakName = "$Database-$stamp-sql2025.bak"
}

$hostPath      = Join-Path $HostBackupDir $BakName
$stagingPath   = "$StagingDir/$BakName"

if (Test-Path $hostPath) {
    throw "Backup file already exists: $hostPath  (pass a different -BakName or delete it first)"
}
if (-not (Test-Path $HostBackupDir)) {
    throw "Host backup dir not found: $HostBackupDir"
}

# Ensure the staging dir exists on the named volume (writable by the mssql user).
docker exec -u root $Container mkdir -p $StagingDir | Out-Null
docker exec -u root $Container chown mssql:root $StagingDir | Out-Null

$invoke = Join-Path $PSScriptRoot 'Invoke-DockerSql.ps1'

if ($ShrinkLogFirst) {
    Write-Host "Shrinking log for [$Database]..."
    $logName = "${Database}_log"
    & $invoke -Container $Container -Database $Database -SaPassword $SaPassword -Query @"
DBCC SHRINKFILE (N'$logName', 0, TRUNCATEONLY);
"@
}

Write-Host "Backing up [$Database] -> $stagingPath (staging)"
& $invoke -Container $Container -SaPassword $SaPassword -Query @"
BACKUP DATABASE [$Database] TO DISK = N'$stagingPath'
WITH NOFORMAT, NOINIT, NAME = N'$Database-Full Database Backup',
     SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10;
"@

Write-Host "Copying $BakName to $HostBackupDir..."
docker cp "${Container}:$stagingPath" $hostPath
if ($LASTEXITCODE -ne 0) { throw "docker cp failed (exit $LASTEXITCODE)" }

if (-not $KeepInternalCopy) {
    docker exec $Container rm -f $stagingPath | Out-Null
}

if (-not (Test-Path $hostPath)) {
    throw "docker cp reported success but file not visible at $hostPath"
}

$size = '{0:N1} MB' -f ((Get-Item $hostPath).Length / 1MB)
Write-Host "Done. $hostPath ($size)"
