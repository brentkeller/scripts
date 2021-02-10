# Helps update npm when you use NVM for Windows

# Solution found in this issue:
# https://github.com/coreybutler/nvm-windows/issues/13#issuecomment-548933570

$starting_path = Get-Location
$node_version = node -v
$node_path = "$env:appdata\nvm\$node_version"
Write-Host "node_version: $node_version"
Write-Host "Path used: $node_path"
cd $node_path
Remove-Item npm
Remove-Item npm.cmd
Remove-Item npx
Remove-Item npx.cmd
cd node_modules
Rename-Item npm -NewName npm-old
cd npm-old\bin
node npm-cli.js install -g npm
cd ../..
Remove-Item -Recurse -Force npm-old
cd $starting_path