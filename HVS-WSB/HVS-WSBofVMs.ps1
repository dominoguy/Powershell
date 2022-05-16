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

$Loglocation = 'D:\Data\Scripts\HVS-WSB\Logs\HVS-WSBofVMs.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start WB VM Backups"

#Get the credentials to access the vms
#$username = "ri-testbcl-001\administrator"
#$password = ConvertTo-SecureString "Generic123" -AsPlainText -Force
#$passwordLocation = "D:\Data\Scripts\HVS-WSB\EncryptedFile\Password.txt"

#$password = Get-Content $passwordLocation | ConvertTo-SecureString 
#$credential = New-Object System.Management.Automation.PsCredential($username,$password)

#Get a list of VMs that are checkpointing
$ListVMs = 'D:\Data\Scripts\HVS-WSB\WSB-VMs.csv'
$VMs = Import-CSV $ListVMs  | select-object -Property vmName,vhdxDrivePath,volumesToBackup,vmBackupTargetDrive,numberofBackups

Foreach ($VM in $VMs) 
{ 
    $vmName = $vm.vmName
    $vmVHDXDrive = $vm.vhdxDrivePath
    $vmVolumesToBackup = $vm.volumesToBackup
    $vmBackupTarget = $vm.vmBackupTargetDrive
    $vmNumberOfBackups = $vm.numberofBackups
   
    $vmState = Get-vm $vmName | Select-Object -Property State

    If ($vmState.State -eq "Running")
    {
        Write-Log "Starting WSB Procedure for $vmName"
        Write-Log "Getting $vmName Drive Info"

        #check to see if the VHDX drive exists according to our standards
        $PathExists = Test-Path -path $vmVHDXDrive
        if ($PathExists -eq $True)
        {   
            $vmDrives = Get-VM $vmName | Get-VMHarddiskDrive
            $vhdxCheck = $False
            ForEach ($Drive in $vmDrives)
            {
                $DriveName = $Drive.Name
                $Controller = $Drive.ControllerType
                $ControllerNumber = $Drive.ControllerNumber
                $ControllerLocation = $Drive.ControllerLocation
                $Path = $Drive.Path
                $DiskNumber = $Drive.DiskNumber

                #look for the last SCSI device attached to the vm to use as a reference
                If ($Controller -eq "SCSI" -And $controllerNumber -eq 0)
                {
                        $scsiControllerNumber = $Drive.ControllerNumber
                        $scsiControllerLocation = $Drive.ControllerLocation
                }
                #Check to see if the VHDX is attached to the VM   
                If ($Path -eq $vmVHDXDrive)
                {
                    Write-Log "vhdx drive is already attached at $Path"
                    #Capture drive information so we can remove the drive later
                    $vhdxController = $Drive.ControllerType
                    $vhdxControllerNumber = $Drive.ControllerNumber
                    $vhdxControllerLocation = $Drive.ControllerLocation
                    $vhdxPath = $Drive.Path
                    $vhdxCheck = $true
                }
            }
             #Attach the vhdx to the vm
             If ($vhdxCheck -eq $False)
             {
                $vhdxControllerNumber = $scsiControllerNumber
                $vhdxControllerLocation = $scsiControllerLocation + 1

                Write-Log "Attaching vhdx drive at $Path"
                add-VMHardDiskDrive -VMName $vmName -controllertype SCSI -controllernumber $vhdxControllerNumber -controllerlocation $vhdxControllerLocation -path $vmVHDXDrive
             }
                
                write-host "The backupdrive controller is $vhdxController"
                write-host "The backupdrive controller number is $vhdxControllerNumber"
                write-host "The backupdrive controller location is $vhdxControllerLocation"
                write-host "The backupdrive VHDX path is $vhdxPath"
                write-host "The last SCSI Controller Number is $scsiControllerNumber"
                write-host "The last SCSI Controller Location is $scsiControllerLocation"
                #Start the WSB Process
                #$session = New-PSSession -ComputerName $vmName -Credential $credential
                
                #is there a wsb already running continue if no
                #Remove old backups
                #handled like wsb. separate powerscipt file, need to create the policy then run the remove
        
                #need to test the remove
                 #Invoke-Command -Session $session -FilePath "F:\Data\Scripts\Powershell\WSB-CleanUp-KeepVersions.ps1" -ArgumentList $vmVolumesToBackup,$vmBackupTarget,$vmName,$vmNumberOfBackups
        
       
                 #Invoke-Command -Session $session -ScriptBlock {Remove-WBBackupSet -BackupTarget $Using:vmBackupTarget -MachineName $Using:vmName -KeepVersions $Using:vmNumberofBackups}

                 #this is working
                 #run the wsb
                 Write-Log "Running Windows Server backup on $vmName"
                #Invoke-Command -Session $session -FilePath "F:\Data\Scripts\Powershell\Windows Server Backup.ps1" -ArgumentList $vmVolumesToBackup,$vmBackupTarget
        


                #Exit-PSSession
                #Unmount the wsbdrive
                Get-vm $vmName | get-vmharddiskdrive -controllertype SCSI -controllernumber $vhdxControllerNumber -controllerlocation $vhdxControllerLocation | remove-vmharddiskdrive
                Write-Log "Finished WSB for $vmName"
               
        }
        Else
        {
            Write-log "Backup VHDX drive at $vmVHDXDrive is not accessible"
        }
    }   
    Else
    {
        Write-Log "The vm $vmName is not Running"
    }
Write-Log "Finished WSB for all VMS"
}

