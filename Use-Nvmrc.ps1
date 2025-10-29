# Tells nvm to use the version of node in the .nvmrc file for this directory

# Add this line to your PowerShell profile to enable the command:
# function Use-Nvmrc { C:\dev\scripts\Use-Nvmrc.ps1 }

# Check for .nvmrc file in current directory, if not then exit
$hasNvmrc = Test-Path -Path ".\.nvmrc" -PathType Leaf
if ($false -eq $hasNvmrc) {
  Write-Output "No .nvmrc file found"
  return
}

# Get desired version from .nvmrc file
Get-Content .nvmrc | Foreach-Object{
  Set-Variable -Name version -Value $_
}
# If the file didn't have a version, exit
if ($null -eq $version -or $version.Length -lt 1) {
  Write-Output "No version available from .nvmrc"
  return
}
else {
  Write-Output "Switching to node $version"
  nvm use $version
}