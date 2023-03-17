#CreateEncryptedPasswordFile
#This script creates an encrypted file contain a user's password
#Password is entered manually
#Password file is created in the same directory as the location of the script.

#function to Save Credentials to a file
Function EncryptPassword([string]$UserName, [string]$FilePath)
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
    $Credential = Get-Credential -Message "Enter the Credentials:" -UserName $UserName
    $Credential.Password | ConvertFrom-SecureString | Set-content $FilePath
}
 
#Get credentials and create an encrypted password file 
EncryptPassword -UserName "" -FilePath "$PSScriptRoot\Password.txt"