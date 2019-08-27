# This profile applies only to the current user and the Microsoft.PowerShell shell
# Make changes to "%UserProfile%\My Documents\WindowsPowerShell\profile.ps1" to affect all shells

# Add posh-git
Import-Module posh-git


# SQL Server Management (requires admin shell)
function Start-Sql-NoWait { c:\dev\scripts\StartSql.ps1 -NoWait }
Set-Alias startsql Start-Sql-NoWait

function Stop-Sql-NoWait { c:\dev\scripts\StopSql.ps1 -NoWait }
Set-Alias stopsql Stop-Sql-NoWait

function Toggle-Sql-NoWait { c:\dev\scripts\ToggleSQLServerService.ps1 -NoWait }
Set-Alias togglesql Toggle-Sql-NoWait

