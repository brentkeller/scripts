$name = $args[0]
# Get stored path from bkcli
$path = bk go $name
if (!$path) {
  Write-Host "No shortcut found for $name"
  exit
}
# Go to short directory
Set-Location $path