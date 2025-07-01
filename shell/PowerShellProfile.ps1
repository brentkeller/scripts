# Brent's customized PowerShell profile
# Import this from the default PowerShell $PROFILE to use it
# `notepad $PROFILE`
# `. "c:\dev\scripts\shell\PowerShellProfile.ps1"`
# Save then `. $PROFILE`

# Add pretty icons
Import-Module -Name Terminal-Icons

# Add posh-git
Import-Module 'C:\dev\resources\posh-git\src\posh-git.psd1'

# Add oh-my-posh
$env:POSH_GIT_ENABLED = $true
# Import-Module 'oh-my-posh' # Not needed with scoop install
oh-my-posh init pwsh --config "c:\dev\scripts\shell\ohmyposhv3.json" | Invoke-Expression


# Add 1password completions
op completion powershell | Out-String | Invoke-Expression

# Add gh completions
Invoke-Expression -Command $(gh completion -s powershell | Out-String)

# Add gh copilot aliases
Import-Module 'C:\dev\scripts\GithubCopilotAliases.ps1'

# git helpers

# git: Checkout main branch
function gitCheckoutMain { git checkout main }
Set-Alias gitmain gitCheckoutMain

# git: Checkout main branch and pull
function gitCheckoutMainAndPull { git checkout main && git pull}
Set-Alias gitmainp gitCheckoutMainAndPull

# git: Checkout main branch, pull, and run npm ci
function gitCheckoutMainAndPullAndNpmCI { git checkout main && git pull && npm ci}
Set-Alias gitmainpn gitCheckoutMainAndPullAndNpmCI

# git: Checkout previous branch
function gitCheckoutLastBranch { git checkout - }
Set-Alias gitlast gitCheckoutLastBranch


# open commit hash in devresults repo
function Open-Github-Commit { 
  $user = Read-Host -Prompt "Github user/org [DevResults]"
  if ([string]::IsNullOrWhiteSpace($user))
  {
    $user = "DevResults"
  }
  $repo = Read-Host -Prompt "Github repo [DevResults]"
  if ([string]::IsNullOrWhiteSpace($repo))
  {
    $repo = "DevResults"
  }
  $id = Read-Host -Prompt "Commit hash"
  Start-Process -Path "https://github.com/$user/$repo/commit/$id"
}
Set-Alias ghcommit Open-Github-Commit

# Start azurite storage emulator
function Start-Azurite { c:\dev\scripts\StartAzurite.ps1 -NoWait }
Set-Alias azemu Start-Azurite

# SQL Server Management (requires admin shell)
function Start-Sql-NoWait { c:\dev\scripts\StartSql.ps1 -NoWait }
Set-Alias startsql Start-Sql-NoWait

function Stop-Sql-NoWait { c:\dev\scripts\StopSql.ps1 -NoWait }
Set-Alias stopsql Stop-Sql-NoWait

function Toggle-Sql-NoWait { c:\dev\scripts\ToggleSQLServerService.ps1 -NoWait }
Set-Alias togglesql Toggle-Sql-NoWait

# GO (requires bkcli installed or linked (npm link))
function Go-To-Shortcut { c:\dev\scripts\goto.ps1 $args }
Set-Alias go Go-To-Shortcut

# Restore bkc-apps to local MongoDB
function restoreBkcAppsMongo() {
  $backupPath = "C:\data\mongo\backups\bkc-apps-prod-backup\bkc-apps-prod"
  mongorestore -d bkc-apps $backupPath
}
Set-Alias restoremybkc restoreBkcAppsMongo

# NVM helpers
function Update-Nvmrc { C:\dev\scripts\Update-Nvmrc.ps1 }
function Use-Nvmrc { C:\dev\scripts\Use-Nvmrc.ps1 }

# scoop helpers

function Set-GitCredManager { C:\dev\scripts\SetGitCredentialHelper.ps1 }
function Update-ScoopGit { scoop update git && Set-GitCredManager }

function Update-Scoop { scoop update && scoop status }
Set-Alias ss Update-Scoop

function Update-AllScoopApps { scoop update * }
Set-Alias sup Update-AllScoopApps

# winget helpers

function Show-WingetUpgrades { winget list --upgrade-available }
Set-Alias wingets Show-WingetUpgrades

function Update-OhMyPosh { winget upgrade --id JanDeDobbeleer.OhMyPosh --silent }

