#HVS-WSBofVMs
<#
.SYNOPSIS
This script does a Windows Server Backup of the System State and critical directories for a list of VMs on a Hyper-V server.

.DESCRIPTION
The script runs a WSB for each VM on a list. It requires that a vhdx is created for the VM of a proper size on a USB drive.
It will find the proper vhdx for the VM and attach the drive to the VM.
It will connect to the vm and tell it to run a wsb
Once the wsb is done the drive will be detached from the vm

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\WB_SHEP-FS-001.log

#>
param(
        [Parameter(Mandatory=$false,HelpMessage='Location of Log file')][string]$LogLocation
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

$Loglocation = 'F:\Data\Scripts\Powershell\HVS-WSB\Logs\HVS-WSBofVMs.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start WB VM Backups"

#Get the credentials to access the vms
$username = "ri-testbcl-001\administrator"
#$password = ConvertTo-SecureString "Generic123" -AsPlainText -Force
$passwordLocation = "F:\Data\Scripts\Powershell\HVS-WSB\EncryptedFile\Password.txt"

$password = Get-Content $passwordLocation | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($username,$password)

#Get a list of VMs that are checkpointing
$ListVMs = 'F:\Data\Scripts\Powershell\HVS-WSB\WSB-VMs.csv'
$VMs = Import-CSV $ListVMs  | select-object -Property vmName,wsbDrive,vhdxDrive,volumesToBackup,backupTarget,numberofBackups

Foreach ($VM in $VMs) 
{ 
    $vmName = $vm.vmName
    $vmWSBDrive = $vm.wsbDrive
    $vmVHDXDrive = $vm.vhdxDrive
    $vmVolumesToBackup = $vm.volumesToBackup
    $vmBackupTarget = $vm.backupTarget
    $vmNumberOfBackups = $vm.numberofBackups
    Write-Host $vmName
    Write-Host $vmWSBDrive
    Write-Host $vmVHDXDrive
    Write-Host $vmVolumesToBackup
    Write-Host $vmBackupTarget
    write-host  $vmNumberOfBackups 
    #$vmState = Get-vm $vmName | Select-Object -Property State
    #If ($vmState -eq "Running")
    #{
        Write-Log "Starting WSB for $vmName"

        Write-Log "  Attaching backup drive for $vmName"
        
        #is the wsbdrive attached, if no attach the wsbdrive

        $session = New-PSSession -ComputerName $vmName -Credential $credential
        #Remove old backups
        #handled like wsb. separate powerscipt file, need to create the policy then run the remove
        Invoke-Command -Session $session -FilePath "F:\Data\Scripts\Powershell\WSB-CleanUp-KeepVersions.ps1" -ArgumentList $vmVolumesToBackup,$vmBackupTarget,$vmName,$vmNumberOfBackups
        #Invoke-Command -Session $session -ScriptBlock {Remove-WBBackupSet -BackupTarget $Using:vmBackupTarget -MachineName $Using:vmName -KeepVersions $Using:vmNumberofBackups}
        #run the wsb
        #Invoke-Command -Session $session -FilePath "F:\Data\Scripts\Powershell\Windows Server Backup.ps1" -ArgumentList $vmVolumesToBackup,$vmBackupTarget
        
        
        
        #Invoke-Command -Session $session -FilePath "F:\Data\Scripts\Powershell\Windows Server Backup.ps1"
        #Invoke-Command -Session $session -ScriptBlock {Get-Culture}
        #Invoke-Command -FilePath c:\scripts\test.ps1 -ComputerName Server01


        Exit-PSSession
        #once wsb is finished unmount the wsbdrive
        Write-Log "  De-attaching backup drive for $vmName"
        Write-Log "Finished WSB for $vmName"
    #}


}

