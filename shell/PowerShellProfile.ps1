# Brent's customized PowerShell profile
# Import this from the default PowerShell $PROFILE to use it
# `notepad $PROFILE`
# `. "c:\dev\scripts\shell\PowerShellProfile.ps1"`
# Save then `. $PROFILE`
function Test-ProfileTool {
  param([string]$ToolName)
  if ($null -eq (Get-Command $ToolName -ErrorAction SilentlyContinue)) {
    Write-Warning "Profile: '$ToolName' was not found on PATH. Skipping related setup."
    return $false
  }
  return $true
}

# activate mise
if (Test-ProfileTool "mise") {
  try {
    $miseActivation = mise activate pwsh | Out-String
    if ([string]::IsNullOrWhiteSpace($miseActivation)) {
      Write-Warning "Profile: 'mise' returned an empty activation script. Skipping setup."
    } else {
      Invoke-Expression $miseActivation
    }
  } catch {
    Write-Warning "Profile: failed to initialize 'mise'. $($_.Exception.Message)"
  }
}

# Add pretty icons
Import-Module -Name Terminal-Icons

# Add posh-git
Import-Module 'C:\dev\resources\posh-git\src\posh-git.psd1'

# Add oh-my-posh
$env:POSH_GIT_ENABLED = $true
# Import-Module 'oh-my-posh' # Not needed with scoop install
oh-my-posh init pwsh --config "c:\dev\scripts\shell\ohmyposhv3.json" | Invoke-Expression


# Add 1password completions
if (Test-ProfileTool "op") {
  try {
    $opCompletion = op completion powershell | Out-String
    if ([string]::IsNullOrWhiteSpace($opCompletion)) {
      Write-Warning "Profile: 'op' returned empty completion output. Skipping setup."
    } else {
      Invoke-Expression $opCompletion
    }
  } catch {
    Write-Warning "Profile: failed to initialize 'op' completions. $($_.Exception.Message)"
  }
}

# Add gh completions
if (Test-ProfileTool "gh") {
  try {
    $ghCompletion = gh completion -s powershell | Out-String
    if ([string]::IsNullOrWhiteSpace($ghCompletion)) {
      Write-Warning "Profile: 'gh' returned empty completion output. Skipping setup."
    } else {
      Invoke-Expression -Command $ghCompletion
    }
  } catch {
    Write-Warning "Profile: failed to initialize 'gh' completions. $($_.Exception.Message)"
  }
}

# Add herdr completions
if (Test-ProfileTool "herdr") {
  try {
    $herdrCompletion = herdr completion powershell | Out-String
    if ([string]::IsNullOrWhiteSpace($herdrCompletion)) {
      Write-Warning "Profile: 'herdr' returned empty completion output. Skipping setup."
    } else {
      Invoke-Expression -Command $herdrCompletion
    }
  } catch {
    Write-Warning "Profile: failed to initialize 'herdr' completions. $($_.Exception.Message)"
  }
}

# Add gh copilot aliases
Import-Module 'C:\dev\scripts\GithubCopilotAliases.ps1'

# git helpers

# git: Checkout main branch
function gitCheckoutMain { git checkout main }
Set-Alias gitmain gitCheckoutMain

# git: Checkout main branch and pull
function gitCheckoutMainAndPull { git checkout main && git pull}
Set-Alias gitmainp gitCheckoutMainAndPull

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

function Backup-Sql { c:\dev\scripts\sql\Backup-DockerDb.ps1 @args }
function Restore-Sql { c:\dev\scripts\sql\Restore-DockerDb.ps1 @args }
function Copy-Sql { c:\dev\scripts\sql\Copy-DockerDb.ps1 @args }

# GO (requires bkcli installed or linked (npm link))
function Go-To-Shortcut { c:\dev\scripts\goto.ps1 $args }
Set-Alias goto Go-To-Shortcut

# Open DevResults.sln in Visual Studio 2026 (18)
function Open-DevResults {
  $slnDir = if (Test-Path "DevResults.vbproj") { ".." } else { "." }
  $sln = Join-Path $slnDir "DevResults.sln"
  if (Test-Path $sln) {
    Start-Process "C:\Program Files\Microsoft Visual Studio\18\Professional\Common7\IDE\devenv.exe" (Resolve-Path $sln)
  } else {
    Write-Error "DevResults.sln not found in $((Resolve-Path $slnDir).Path)"
  }
}
Set-Alias drvs Open-DevResults

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

# tool shortcuts

function Open-WaidUi { waid ui }
Set-Alias wu Open-WaidUi

