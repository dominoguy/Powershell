#Windows Server Backup of VMS on Hyper-V

<#
.SYNOPSIS
This script does a Windows Server Backup of the System State and critical directories for a list of VMs on a Hyper-V server.
Currently the script only uses one set of creds. So as long as the cred can modify a location then the location can be used.
Script could be modified to use diff creds. would need to specify which password.txt file to use
A log file is also placed at the target location
Items to check on the HVS:
test-wsman
enable-psremoting
Install-WindowsFeature Windows-Server-Backup 
Get-Item wsman:localhost\client\trustedhosts
Set-Item wsman:\localhost\client\trustedhosts -value 'RI-TESTBCL-001,RI-HVS-001' -Force (Where the value are the vms to be backed up)

.DESCRIPTION
This script creates Windows Server Backups of selected VMs using the HOST.

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\WB_SHEP-FS-001.log

#>
param(
        [Parameter(Mandatory=$False,HelpMessage='Location of Log file')][string]$LogLocation
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
$LogLocation = "D:\Data\Scripts\Logs\WB-Hyper-V-VMs.log"
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Begin of WSB of VMs"

#Get a list of VMs and their WSB Targets
$ListVMs = "$PSScriptroot\WSB-Hyper-V-VMs-ListofVMS.csv"
$VMs = Import-CSV $ListVMs  | select-object -Property vmName,TargetPath,User

Foreach ($VMInfo in $VMs) 
{ 
    $VM = $VMInfo.VMName
    $vmBackupTarget = $VMInfo.TargetPath
    $User = $VMInfo.User
    $passwordLocation = "$PSScriptRoot\Password.txt"
    $password = Get-Content $passwordLocation | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
    
    #Create a Windows Backup Policy
    $WBPolicy = New-WBPolicy
    #Add System State into the policy
    Add-WBSystemState -Policy $WBPolicy
    #On first Saturday of the month do a full backup, otherwise, incremental
    if ($date.Day -le 7 -and $date.DayOfWeek -eq "Saturday")
    {
        Set-WBVssBackupOption -Policy $WBPolicy -VssFullBackup
        Set-WBPerformanceConfiguration -OverallPerformanceSetting AlwaysFull
    }
    else 
    {
        Set-WBVssBackupOption -Policy $WBPolicy -VssCopyBackup
        Set-WBPerformanceConfiguration -OverallPerformanceSetting AlwaysIncremental
    }
    #Add Baremetal Backup
    Add-WBBareMetalRecovery -Policy $WBPolicy
    #Finish the WBPolicy for the VM
    Get-WBVirtualMachine | Where-Object VMName -eq $VM | Add-WBVirtualMachine -Policy $WBPolicy

    New-PSDrive -Name "G" -Root $vmBackupTarget -PSProvider "FileSystem" -Credential $Cred

    $StatusDrive = Test-Path -Path "G:"
    If ( $StatusDrive -eq $True)
    {
        Write-Log "Backup location verified."
        Write-log "Start WSB of $VM"
        $backupLocation = New-WBBackupTarget -NetworkPath $vmBackupTarget -Credential $Cred
        #Add the backup location into the policy
        Add-WBBackupTarget -Policy $WBPolicy -Target $backupLocation
        #Run the backup
        Start-WBBackup -Policy $WBPolicy
        Write-Log "Did the WSB of $VM complete: $?"
        Write-log "Exit code $LASTEXITCODE"
        $Backups = Get-WBBackupSet -BackupTarget $BackupLocation
        Write-log "The result of WSB is $Backups"
        Write-Log "Finished WSB of $VM"
    }
    else
    {
        Write-log "Backup location is unavailable"
    }
    #Put a copy of the log in target directory
    Copy-Item $Loglocation -Destination "G:"
    #Remove the PS Drive
    Get-PSDrive G | Remove-PSDrive
}
Write-Log "Finished WSB of VMs"