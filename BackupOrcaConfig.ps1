
# Backup config for Orca Slicer to Google Drive
$src = "C:\Users\brent\AppData\Roaming\OrcaSlicer\*"
$date = (Get-Date).ToString("yyyyMMdd")
$dest = "H:\My Drive\3D Printing\OrcaSlicer\configs\$date"


$ValidPath = Test-Path -Path $dest

If ($ValidPath -eq $False){
    New-Item -Path $dest -ItemType directory
}

Write-Host "Copying Orca Slicer config to: $dest"

Copy-Item -Path $src -Recurse -Destination $dest -Force

Write-Host "Finished!"
