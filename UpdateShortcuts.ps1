
# Update target path for chrome shortcuts
$folder = 'H:\My Drive\Brent\SP8\shortcuts'
$from = 'Files (x86)\Google\Chrome\'
$to = 'Files\Google\Chrome\'

# Most files in the folder are shortcuts, skip .ahk files
$files = Get-ChildItem -Path $folder -File | Where-Object -Property Extension -ne ".ahk"
$obj = New-Object -ComObject WScript.Shell 

Write-Host $files.Length

ForEach($file in $files){ 
  Write-Host $file.Name
	 $link = $obj.CreateShortcut($file) 
   # Only consider shortcuts with a legacy Chrome path
   if ($link.TargetPath -like '*Files (x86)\Google\Chrome*')
   {
     Write-Host $link.TargetPath -ForegroundColor green
     Write-Host $link.TargetPath.Replace($from,$to)
     $link.TargetPath = $link.TargetPath.Replace($from,$to)
     $link.Save() 
   }
} 
