Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
 Where-Object { -not ([string]::IsNullOrEmpty($_.DisplayName)) } |
 Sort-Object DisplayName | 
 Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | 
 Format-Table -AutoSize > "c:\files\InstalledProgramList-$(Get-Date -f yyyy.MM.dd).txt"