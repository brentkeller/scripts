# Writes a .nvmrc file with the current node version

# Check for .nvmrc file in current directory, if not then exit
$version = node -v

# Remove the "v" prefix for compatibility with the .Mismatched property on the node segment in oh-my-posh
if ("v" -eq $version.Substring(0, 1)) {
  $version = $version.Substring(1, $version.Length - 1)
}

"$version" | Out-File -FilePath .nvmrc -NoNewline

Write-Output ".nvmrc updated to $version"



