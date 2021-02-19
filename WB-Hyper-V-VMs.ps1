#Windows Server Backup of VMS on Hyper-V

<#
.SYNOPSIS
This script does a Windows Server Backup of the System State and critical directories for a slist of VMs on a Hyper-V server.

.DESCRIPTION
This script creates a Windows Backup Policy which is used to run the backup against.

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\WB_SHEP-FS-001.log

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

Write-Log "Start WB VM Backup"

#List of VMs to backup
$VMS = "RI-TestBCL-001"

Set-WBPerformanceConfiguration -OverallPerformanceSetting AlwaysIncremental

#Create a Windows Backup Policy
$WBPolicy = New-WBPolicy

#Add System State into the policy
Add-WBSystemState -Policy $WBPolicy

#Add Baremetal Backup
Add-WBBareMetalRecovery -Policy $WBPolicy

#Add a list of VMs to be backed up
#Add-WBVirtualMachine -Policy $WBPolicy -VirtualMachine $VMS
Get-WBVirtualMachine | Where-Object VMName -eq $VMS | Add-WBVirtualMachine -Policy $WBPolicy

#Set the backup location for the backup policy
#Volume Backup Location
$backupLocation = New-WBBackupTarget -VolumePath "F:"
#change to network path so we are able to change to a subdirectory under f:, volumepath only allows the volume name f: not f:\backups

#Network Backup Location w/ Alias
#$User = "RI-TESTBCL-001\administrator"
#$PWord = ConvertTo-SecureString -String 'Nomatt3r20' -AsPlainText -Force
#$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
#New-PSDrive -Name "G" -Root "\\RI-TESTBCL-001\F$\NetworkBackup\RI-TESTBCL-001" -PSProvider "FileSystem" -Credential $Cred

#$backupLocation = New-WBBackupTarget -NetworkPath "G:"



#Add the backup location into the policy
Add-WBBackupTarget -Policy $WBPolicy -Target $backupLocation

#Run the backup
Start-WBBackup -Policy $WBPolicy

Write-Log "Finish WB VM Backup"

