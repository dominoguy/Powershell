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
        [Parameter(Mandatory=$False,HelpMessage='Volumes to backup')][string]$volumesToBackup,
        [Parameter(Mandatory=$False,HelpMessage='Windows Server Drive')][string]$BackupTarget
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
$LogLocation = "D:\Data\Scripts\Logs\WSBVM.log"
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

#need baremetal which should include critical volumes and need systemstate
$WBPolicy = Get-WBPolicy
If ($null -eq $WBPolicy)
{
#Create a Windows Backup Policy
$WBPolicy = New-WBPolicy

#Set the WBVssBackupOption
#On first Saturday of the month do a full backup, otherwise, incremental
if ($date.Day -le 7 -and $date.DayOfWeek -eq "Saturday")
{
    Set-WBVssBackupOption -Policy $WBPolicy -VssFullBackup
    Set-WBPerformanceConfiguration -OverallPerformanceSetting AlwaysFull
}
else {
    Set-WBVssBackupOption -Policy $WBPolicy -VssCopyBackup
    Set-WBPerformanceConfiguration -OverallPerformanceSetting AlwaysIncremental
}
#Add System Sate into the policy
Add-WBSystemState -Policy $WBPolicy

#Add Baremetal Backup
Add-WBBareMetalRecovery -Policy $WBPolicy

#Add Volumes to backup
$volumes = $volumesToBackup -split ","
$FileSpecArray = Foreach ($vol in $volumes)
{
    New-WBFilespec -FileSpec $vol
}
Add-WBFileSpec -Policy $WBPolicy $FileSpecArray

#Set the backup location for the backup policy
$backupLocation = New-WBBackupTarget -VolumePath "$BackupTarget"

#Add the backup location into the policy
Add-WBBackupTarget -Policy $WBPolicy -Target $backupLocation
}

#
#Run the backup
Start-WBBackup -Policy $WBPolicy