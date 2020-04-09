#Change ACL Permissions 1.0
#Brian Long March 11, 2020
<#
.SYNOPSIS
Add modify access to a selected folder

.DESCRIPTION

.PARAMETER TriggerLocation
Location of the list of psts in CSV format
IE. F:\Data\Scripts\Docuware\Reset.txt

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\ChangeACL.log
#>
#The script will change the ACL for the target and child folders/files, but not for any folders that inheritance has been disabled
$Acl = Get-ACL "f:\Temp"
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("ri\blongtest", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl -path "F:\Temp" -AclObject $Acl
