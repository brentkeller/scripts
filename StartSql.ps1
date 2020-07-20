param([switch] $NoWait)
$srvName = "SQL Server (SQL2019)"
"Starting " + $srvName
Start-Service $srvName
# PowerShell cmdlet to check a service's status
$serviceAfter = Get-Service $srvName
$srvName + " is now " + $serviceAfter.status	
    
if (!$NoWait) {
    Write-Host "Press any key to continue ..."
    $_unused = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
