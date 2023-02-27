#DirectoryAccessByGroupMembership

# $DirectoryPath is the path of which you want to check the access
# $Name is the security principle name whose access you are checking


param(
        [Parameter(Mandatory=$true,HelpMessage='Name of User or Group to check')][string]$Name,
        [Parameter(Mandatory=$true,HelpMessage='Directory path to check')][string]$directoryPath
    )


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


#get the current date in the format of  month-day-year
#$curDate = Get-Date -UFormat "%m-%d-%Y"

$Position = $Name.IndexOf("\")
$LogName = $Name.Substring($Position+1)
Write-host $LogName

#$LogLocation = "F:\Data\Scripts\Powershell\DirectoryAccessRights\Logs\DirectoryAccess-$LogName.log"
$LogLocation = "D:\Data\Scripts\Logs\DirectoryAccess-$LogName.log"
$logFile = $LogLocation
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start Directory Access by Security Principle (Username or Group)"

#$directoryPath = "F:\Backups"
#$Name = "RI\Domain Admins"

#$directoryPath = "H:\public\HUMAN RESOURCES"s
#$Name = "Human Resources"

Write-Log "Checking the group $Name's access on the directory of $directoryPath"

#Check permissions on the main directory
write-log "Checking $directoryPath"

$ACL= Get-ACL -Path $directoryPath
$NameFound = $False
ForEach ($access in $ACL.Access)
{
    ForEach ($item in $access)
    {
        $identityReference = $Item.identityreference
        $FileSystemRights =  $item.filesystemrights
        $AccessControlType = $item.accesscontroltype
        $InheritedFlag = $Item.inheritanceflags
        $PropagationFlag = $Item.propagationflags

        IF ($identityReference -eq $Name)
        {
            $folderFullPath = $folder.FullName
            Write-Log "The directory is $directoryPath"
            Write-Log "     The Identity Reference is $identityReference"
            Write-Log "     The File System Rights are  $FileSystemRights"
            write-log "     The Access Control Type is $AccessControlType"
            Write-Log "     The Inherited Flags are $InheritedFlag"
            Write-Log "     The Propagation Flags are $PropagationFlag"
            $NameFound = $true
        }
    }
}
<#
IF ($NameFound -eq $False)
    {
        Write-Log " $Name is not found in the Access of $directoryPath"
    }
#>

#Get the folders under the directory
$folders = Get-ChildItem -Directory -Path $directoryPath -Recurse -Force

ForEach ($folder in $folders)
{
    $FolderName = $folder.Fullname
    write-log "Checking $FolderName"

    $ACL= Get-ACL -Path $Folder.FullName
    $NameFound = $False
    ForEach ($access in $ACL.Access)
    {
        ForEach ($item in $access)
        {
            $identityReference = $Item.identityreference
            $FileSystemRights =  $item.filesystemrights
            $AccessControlType = $item.accesscontroltype
            $InheritedFlag = $Item.inheritanceflags
            $PropagationFlag = $Item.propagationflags

            IF ($identityReference -eq $Name)
            {
                $folderFullPath = $folder.FullName
                Write-Log "The directory is $folderFullPath"
                Write-Log "     The Identity Reference is $identityReference"
                Write-Log "     The File System Rights are  $FileSystemRights"
                write-log "     The Access Control Type is $AccessControlType"
                Write-Log "     The Inherited Flags are $InheritedFlag"
                Write-Log "     The Propagation Flags are $PropagationFlag"
                $NameFound = $true
            }
        }
    }
    <#
    IF ($NameFound -eq $False)
        {
            Write-Log " $Name is not found in the Access of $FolderName"
        }
    #>
}
Write-Log "End Directory Access by Security Principle"