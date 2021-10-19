#Get-Folder Permissions

<#
.SYNOPSIS
This script does gets the ACLs of a folder and its subfolders, it will query AD to get users that are in a group

.DESCRIPTION
This script does gets the ACLs of a folder and its subfolders

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\WB_SHEP-FS-001.log
.Parameter ParentFolder
Location of the starting folder

#>
param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='Parent Folder Location')][string]$ParentFolder
    )
<#

.SYNOPSIS
Writes to a log.
.Description
Creates a new log file in the designated location.
.PARAMETER logstring
String of text
#>
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start Get Folder Permissions"

$OutFile = "F:\data\Scripts\Powershell\FolderPermissions\FolderPermissions.csv"
$FolderPath = Get-ChildItem -Directory -Path $ParentFolder -Recurse -Force

$Output = @()
ForEach ($Folder in $FolderPath) {
    $ACL = Get-Acl -Path $Folder.FullName
    ForEach ($ACE in $ACL.Access) {
        $Properties = [ordered]@{'Folder Name'=$Folder.FullName;'Group/User'=$ACE.IdentityReference;'Permissions'=$ACE.FileSystemRights;'Inherited'=$ACE.IsInherited}
        $Output += New-Object -TypeName PSObject -Property $Properties
        $Group = Get-ADObject -Filter "SamAccountName" -eq '$ACE.IdentityReference.Value.Split('\')[1]'"
        IF ($Group.ObjectClass = "group") {
            $GroupMembers = Get-ADGroupMember -Identity $Group.name
            Write-Log $GroupMembers
        }        
    }
}

$Output | Export-Csv $OutFile


Write-Log "End Get Folder Permissions"








