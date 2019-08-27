param([switch] $NoWait)
$srvName = "SQL Server (SQL2017)"
# PowerShell cmdlet to check a service's status
$servicePrior = Get-Service $srvName
$srvName + " is " + $servicePrior.status	

if ($servicePrior.status -eq "Running") {
    "Stopping " + $srvName
    Stop-Service $srvName
}
else {
    "Starting " + $srvName
    Start-Service $srvName
}	
$serviceAfter = Get-Service $srvName
$srvName + " is now " + $serviceAfter.status
    
if (!$NoWait) {
    Write-Host "Press any key to continue ..."
    $_unused = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
