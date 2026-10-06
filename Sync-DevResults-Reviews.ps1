<#
.SYNOPSIS
Two-way sync of the .reviews folders between worktrees. Newer files win.
Reviews older than -ArchiveAfterDays are moved into an archive subfolder, which is synced too.

.EXAMPLE
.\Sync-DevResults-Reviews.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Paths = @(
        'C:\dev\dr\devresults\devresults\.reviews',
        'C:\dev\dr\devresults\planning\.reviews'
    ),
    [int]$ArchiveAfterDays = 10,
    [string]$ArchiveFolder = 'archive'
)

function Copy-Newer {
    param([string]$Source, [string]$Destination)

    $copied = 0
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force) {
        $relative = $file.FullName.Substring($Source.Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue

        if ($existing -and $existing.LastWriteTimeUtc -ge $file.LastWriteTimeUtc) { continue }

        if ($PSCmdlet.ShouldProcess($target, "Copy from $($file.FullName)")) {
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            # Copy-Item preserves LastWriteTime, so the reverse pass sees the files as equal.
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
            $copied++
        }
    }
    $copied
}

function Move-ToArchive {
    param([string]$Path, [datetime]$CutoffUtc)

    $archive = Join-Path $Path $ArchiveFolder
    $moved = 0
    # Top-level files only; anything already in a subfolder stays where it is.
    foreach ($file in Get-ChildItem -LiteralPath $Path -File -Force) {
        if ($file.LastWriteTimeUtc -ge $CutoffUtc) { continue }

        $target = Join-Path $archive $file.Name
        if ($PSCmdlet.ShouldProcess($file.FullName, "Move to $archive")) {
            New-Item -ItemType Directory -Path $archive -Force | Out-Null
            $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
            if ($existing -and $existing.LastWriteTimeUtc -gt $file.LastWriteTimeUtc) {
                # The archived copy is newer, so the top-level one is a stale duplicate.
                Remove-Item -LiteralPath $file.FullName -Force
            }
            else {
                Move-Item -LiteralPath $file.FullName -Destination $target -Force
            }
            $moved++
        }
    }
    $moved
}

$resolved = foreach ($path in $Paths) {
    if (-not (Test-Path -LiteralPath $path)) {
        if ($PSCmdlet.ShouldProcess($path, 'Create directory')) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    [System.IO.Path]::GetFullPath($path).TrimEnd('\')
}

foreach ($source in $resolved) {
    foreach ($destination in $resolved) {
        if ($source -eq $destination) { continue }
        if (-not (Test-Path -LiteralPath $source)) { continue }
        $count = Copy-Newer -Source $source -Destination $destination
        Write-Host "$source -> $destination : $count file(s) copied"
    }
}

# Archiving runs after the sync so every folder holds the same files and archives the same set.
$cutoff = (Get-Date).ToUniversalTime().AddDays(-$ArchiveAfterDays)
foreach ($path in $resolved) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $count = Move-ToArchive -Path $path -CutoffUtc $cutoff
    Write-Host "$path : $count file(s) archived"
}
