# Reset the credential helper after installing a new version of git from scoop

Write-Host "Updating git system credential.helper"
Write-Host "Before:"
git config --show-origin --get-all credential.helper

# it might be helpful to use a "remove all" call here before setting the new one?

# Set to manager
git config --system credential.helper manager

Write-Host "After:"
git config --show-origin --get-all credential.helper
