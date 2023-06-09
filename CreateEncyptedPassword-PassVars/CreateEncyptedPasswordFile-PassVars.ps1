#CreateEncryptedPasswordFile
#This script creates an encrypted file contain a user's password
#pass in the username and password
#Password file is created in the same directory as the location of the script.

#function to Save Credentials to a file
param(
        [Parameter(Mandatory=$True,HelpMessage='Username')][string]$UserName,
        [Parameter(Mandatory=$True,HelpMessage='Password')][string]$PassW
    )
Function EncryptPassword([string]$UserName,[String]$PassW,[string]$FilePath)
{
    #Create directory for Key file
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
    #store password encrypted in file
    $Pword = ConvertTo-SecureString -String $PassW -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $PWord
    $Credential.Password | ConvertFrom-SecureString | Set-content $FilePath
}
 
#Get credentials and create an encrypted password file 
EncryptPassword -UserName $UserName -PassW $PassW -FilePath "$PSScriptRoot\Password.txt"