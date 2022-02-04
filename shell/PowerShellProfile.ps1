# Brent's customized PowerShell profile
# Import this from the default PowerShell $PROFILE to use it
# `notepad $PROFILE`
# `. "c:\dev\scripts\shell\PowerShellProfile.ps1"`
# Save then `. $PROFILE`


# Print current version of node.js
function Get-NodeVer { 
	try {
		$ver = node -v
		#Write-Output ''node:$ver
		Write-Output ''$ver
	}
	catch {}
}

# Add pretty icons
Import-Module -Name Terminal-Icons

# Add posh-git
Import-Module 'C:\dev\resources\posh-git\src\posh-git.psd1'
#Import-Module posh-git
# $GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-Date -f "H:mm:ss")$(Get-NodeVer) '
# $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = 'Orange'

# Add oh-my-posh
$env:POSH_GIT_ENABLED = $true
# Import-Module 'oh-my-posh' # Not needed with scoop install
oh-my-posh --init --shell pwsh --config "c:\dev\scripts\shell\ohmyposhv3.json" | Invoke-Expression


# Add gh completions
Invoke-Expression -Command $(gh completion -s powershell | Out-String)


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

# Add support for .nvmrc file in project folder: https://gist.github.com/danpetitt/e87dabb707079e1bfaf797d0f5f798f2
function callnvm() {
  # Always use argument version if there is one
  $versionDesired = $args[0]

  if (($versionDesired -eq "" -Or $versionDesired -eq $null) -And (Test-Path .nvmrc -PathType Any)) {
    # if we have an nvmrc and no argument supplied, use the version in the file
    $versionDesired = $(Get-Content .nvmrc).replace( 'v', '' );
  }
  Write-Host "Requesting version '$($versionDesired)'"

  if ($versionDesired -eq "") {
    Write-Host "A node version needs specifying as an argument if there is no .nvmrc"
  } else {
    $response = nvm use $versionDesired;
    if ($response -match 'is not installed') {
      if ($response -match '64-bit') {
        $response = nvm install $versionDesired x64
      } else {
        $response = nvm install $versionDesired x86
      }
      Write-Host $response

      $response = nvm use $versionDesired;
    }

    Write-Host $response
  }
}
Set-Alias nvmu -value "callnvm"