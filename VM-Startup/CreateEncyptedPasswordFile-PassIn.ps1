#CreateEncyptedPasswordFile-PassIn
param(
        [Parameter(Mandatory=$true,HelpMessage='Enter Password')][string]$Password
    )

$FilePath = "$PSScriptRoot\Password.txt"
$FilePathExists = Test-Path -path $FilePath
if ( $FilePathExists -eq $True)
{
    Remove-Item $FilePath
    New-Item -ItemType File -Force -Path $FilePath
}
else
{

    New-Item -ItemType File -Force -Path $FilePath
}

$SecurePassword = ConvertTo-SecureString "$Password" -AsPlainText -Force 
$SecurePassword | ConvertFrom-SecureString | Set-content $FilePath