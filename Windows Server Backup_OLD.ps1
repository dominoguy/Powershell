#Windows Server Backup

<#
.SYNOPSIS
This script does a Windows Server Backup of the System State and critical directories for a server restore.

.DESCRIPTION
This script creates a Windows Backup Policy which is used to run the backup against.

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\ADInfo.log

#>
param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation
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

Function RunWBBackup
{
#need baremetal which should include critical volumes and need systemstate

#Create a Windows Backup Policy
$WBPolicy = New-WBPolicy

#Add System Sate into the policy
Add-WBSystemState -Policy $WBPolicy

#Add Baremetal Backup
Add-WBBareMetalRecovery -Policy $WBPolicy
#$BackupDir = "M:\Backups\RI\RI-HDC-001"
$BackupDir = "M:"

#Set the backup location for the backup policy
#$backupLocation = New-WBBackupTarget -networkpath $BackupDir
$backupLocation = New-WBBackupTarget -VolumePath M:

#Add the backup location into the policy
Add-WBBackupTarget -Policy $WBPolicy -Target $backupLocation

#Run the backup
Start-WBBackup -Policy $WBPolicy
}

#Set the backup target and run the backup
$BackupDrive = "M:"
$TestPath = Test-Path -Path $backupDrive
IF ($TestPath) {
    Remove-SMBMapping -Force -LocalPath 'M:'
    New-SMBMapping -LocalPath 'M:' -RemotePath '\\ri-dt-019.ri.ads\l$' -UserName  'ri\backupservice' -password 'sYlhmMh62dNRuP74Sl03'
    RunWBBackup
}
Else {
    New-SMBMapping -LocalPath 'M:' -RemotePath '\\ri-dt-019.ri.ads\l$' -UserName  'ri\backupservice' -password 'sYlhmMh62dNRuP74Sl03'
    RunWBBackup
}

#Close the mapped drive 
Remove-SMBMapping -Force -LocalPath 'm:'