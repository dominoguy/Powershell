#DirectoryAccessByGroupMembership

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


#get the current date in the format of  month-day-year
#$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = "F:\Data\Scripts\Powershell\Logs\DirectoryAccessByGroup.log"
#$LogLocation = "D:\Data\Scripts\Logs\DirectoryAccessByGroup.log"
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

Write-Log "Start Directory Access by Group Name"

$directoryPath = "F:\Backups"
$GroupName = "RI\Domain Admins"

#$directoryPath = "H:\public\HUMAN RESOURCES"
#$GroupName = "Human Resources"

$folders = Get-ChildItem -Directory -Path $directoryPath

ForEach ($folder in $folders)
{
    $ACL= Get-ACL -Path $Folder.FullName
    ForEach ($access in $ACL.Access)
    {
        ForEach ($item in $access)
        {
            $identityReference = $Item.identityreference
            $FileSystemRights =  $item.filesystemrights
            $AccessControlType = $item.accesscontroltype

            IF ($identityReference -eq $GroupName)
            {
                $folderFullPath = $folder.FullName
                Write-Log "The directory is $folderFullPath"
                Write-Log "     The Identity Reference is $identityReference"
                Write-Log "     The File System Rights are  $FileSystemRights"\
                write-log "     The Access Control Type is $AccessControlType"
            }
        }
    }
}
Write-Log "End Directory Access by Group Name"