# Install common global packages

Write-Host "Installing yarn"
npm i -g yarn

Write-Host "Installing serve"
npm i -g serve

Write-Host "Installing azurite"
npm i -g azurite


# Link CLI apps

Write-Host "Linking bkcli"
Set-Location C:\dev\nodejs\bkcli
npm link

Write-Host "Linking devresults-cli"
Set-Location C:\dev\dr\devresults-cli
npm link

# List the global packages to make sure we've got everything

Write-Host "Current global packages:"
npm list -g --depth=0