#requires -Version 7

# Runs a T-SQL query inside the sql2025 container via sqlcmd.
# Password resolution order: -SaPassword param, $env:SA_PASSWORD, then prompt.

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Query,
    [string] $Container = 'sql2025',
    [string] $Database  = 'master',
    [string] $SaPassword
)

if (-not $SaPassword) { $SaPassword = $env:SA_PASSWORD }
if (-not $SaPassword) {
    $sec = Read-Host -AsSecureString "SA password for $Container"
    $SaPassword = [System.Net.NetworkCredential]::new('', $sec).Password
}

# -C trusts the self-signed cert the image ships with; -b makes sqlcmd return
# a non-zero exit code on T-SQL errors so $LASTEXITCODE is meaningful.
docker exec -i $Container /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $SaPassword -C -b -d $Database -Q $Query

if ($LASTEXITCODE -ne 0) {
    throw "sqlcmd failed against $Container (exit $LASTEXITCODE)"
}
