#HVS-WSBofVMs
<#
.SYNOPSIS
Version 1.0
This script does a Windows Server Backup of the System State and critical directories for a list of VMs on a Hyper-V server.
Version 2.0 29-05-2023
Changed WSB disk targeting to use disk number instead of volume name
No longer need SetDriveLetter.ps1

.DESCRIPTION
The script runs a WSB for each VM on a list. It requires that a vhdx is created for the VM of a proper size on a USB drive.
It will find the proper vhdx for the VM and attach the drive to the VM.
It will connect to the vm and tell it to run a wsb
Once the WSB is done the drive will be detached from the vm

Pre-requisites to run on the HVS
Value = the FQDN of the VM
Get-Item wsman:localhost\client\trustedhosts
Set-Item wsman:\localhost\client\trustedhosts -value RI-TESTBCL-001

Pre-requisties to run on the VM
Load the powershell modules on the VM
import-module WindowsServerBackup

Enable-PSRemoting?
Windows server backup needs to be installed on the target

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\WB_SHEP-FS-001.log

#>
param(
        [Parameter(Mandatory=$false,HelpMessage='Location of Log file')][string]$LogLocation = "D:\Data\Scripts\HVS-WSB\Logs\HVS-WSBofVMs.log",
        [Parameter(Mandatory=$false,HelpMessage='List of VMs')][string]$ListVMs = "$PSScriptRoot\WSB-VMs.csv"
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

#$Loglocation = 'D:\Data\Scripts\HVS-WSB\Logs\HVS-WSBofVMs.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start WB VM Backups"
#Get a list of VMs that are checkpointing

$VMs = Import-CSV $ListVMs  | select-object -Property vmName,vhdxDrivePath,volumesToBackup,vmBackupTargetDrive,DiskUniqueID,User,FQDN,CheckPath

Foreach ($VM in $VMs) 
{ 
    $vmName = $vm.vmName
    $vmVHDXDrive = $vm.vhdxDrivePath
    $vmVolumesToBackup = $vm.volumesToBackup
    $vmBackupTarget = $vm.vmBackupTargetDrive
    $vmDiskUniqueID = $vm.DiskUniqueID
    $vmFQDN = $vm.FQDN
    $CheckPath = $vm.CheckPath
    
    #Get the credentials to access the vm
    $username = $vm.User
    $passwordLocation = "$PSScriptRoot\Password.txt"
    $password = Get-Content $passwordLocation | ConvertTo-SecureString 
    $credential = New-Object System.Management.Automation.PsCredential($username,$password)

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
                #$DriveName = $Drive.Name
                $Controller = $Drive.ControllerType
                $ControllerNumber = $Drive.ControllerNumber
                $Path = $Drive.Path

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
                    $vmVHDXDrive = $Drive.Path
                    $vhdxCheck = $true
                }
            }
             #Attach the vhdx to the vm
             If ($vhdxCheck -eq $False)
             {
                $vhdxControllerNumber = $scsiControllerNumber
                $vhdxControllerLocation = $scsiControllerLocation + 1

                Write-Log "Attaching vhdx drive at $vmVHDXDrive"
                add-VMHardDiskDrive -VMName $vmName -controllertype SCSI -controllernumber $vhdxControllerNumber -controllerlocation $vhdxControllerLocation -path $vmVHDXDrive
                $driveresults = Get-VM $vmName | Get-VMHarddiskDrive -controllertype SCSI -controllernumber $vhdxControllerNumber -controllerlocation $vhdxControllerLocation
                Write-Log $driveresults
             }
                
                write-Log "The backupdrive VHDX path is $vmVHDXDrive"
                write-Log "The last SCSI Controller Number is $scsiControllerNumber"
                Write-Log "The last SCSI Controller Location is $scsiControllerLocation"
                
                Write-Host "Check 10.0"
                #Start the WSB Process
                $session = New-PSSession -ComputerName $vmFQDN -Credential $credential          

                #In the VM get the disk by UniqueID and assign it a drive letter
                Write-Log "Get the WSB Target Disk Number"
                #$DriveisSet = Invoke-Command -Session $session -FilePath "$PSScriptRoot\SetDriveLetter.ps1" -ArgumentList $vmDiskUniqueID,$vmBackupTarget
                $parameters = @{
                    Session = $Session
                    ScriptBlock = {
                    Param ($vmDiskUniqueID)
                            Get-Disk | Where-Object UniqueId -eq $vmDiskUniqueID
                            }
                    ArgumentList = $vmDiskUniqueID
                }
                $diskInfo = Invoke-Command @parameters
                $diskNumber = $diskInfo.DiskNumber
                Write-host "The disk number is $disknumber"
                If ($Null -ne $diskNumber)
                    {   #run the wsb
                        Write-Log "Disk Number is $diskNumber"
                        Write-Log "Running Windows Server backup on $vmName"
                        Invoke-Command -Session $session -FilePath "$PSScriptRoot\Windows Server Backup.ps1" -ArgumentList $vmVolumesToBackup,$diskNumber

                        $WSBSuccess = Invoke-Command -Session $session -ScriptBlock {Get-WBJob -Previous 1}
                        $JobState = $WSBSuccess.JobState
                        Write-Log "The state of the backup is $JobState"
                        $WSBSummary = Invoke-Command -Session $session -ScriptBlock {Get-WBSummary}
                        $WSBSumLSBT = $WSBSummary.LastSuccessfulBackupTime
                        $WSBSumLBT = $WSBSummary.LastBackupTime
                        $WSBSumDM = $WSBSummary.DetailedMessage
                        $WSBSumLBRHR = $WSBSummary.LastBackupResultHR

                        Write-Log "The last successful Backup Time was $WSBSumLSBT"
                        Write-Log "The last backup time was $WSBSumLBT"
                        Write-Log "If WSB errored, the detailed message is $WSBSumDM"
                        Write-Log "If WSB errored, the Last Backup Result HR code is $WSBSumLBRHR"

                        if ( $JobState -eq "Completed") {
                            Write-Log "Backup was successful."
                        }else {
                            Write-Log "Backup was not successful."
                        }
                       
                        $CheckWSBFile = "$CheckPath\WSBCheck.log"
                        Write-log "The check file for the WSB is located at $CheckWSBFile"
                        $parameters = @{
                            Session = $Session
                            ScriptBlock = {
                            Param ($CheckWSBFile)
                                New-Item -Path $CheckWSBFile -Force
                                    }
                            ArgumentList = $CheckWSBFile
                        }
                        Invoke-Command @parameters
                        If ($JobState -eq 'Completed')
                        {
                            $parameters = @{
                                Session = $Session
                                ScriptBlock = {
                                Param ($CheckWSBFile)
                                    Set-Content -Path $CheckWSBFile -Value "WSB Completed"
                                        }
                                ArgumentList = $CheckWSBFile
                            }
                            Invoke-Command @parameters
                        }
                        elseIf($JobState -ne 'Completed')
                        {
                            $parameters = @{
                                Session = $Session
                                ScriptBlock = {
                                Param ($CheckWSBFile)
                                    Set-Content -Path $CheckWSBFile -Value "WSB Failed"
                                        }
                                ArgumentList = $CheckWSBFile
                            }
                            Invoke-Command @parameters
                        }
                    }
                else {
                    Write-Log "Drive Letter is unavailable for target drive. WSB aborted "
                    Write-Log $DriveisSet[1]
                }
                Exit-PSSession
                #Unmount the wsbdrive
                Get-vm $vmName | get-vmharddiskdrive -controllertype SCSI -controllernumber $vhdxControllerNumber -controllerlocation $vhdxControllerLocation | remove-vmharddiskdrive
                Write-Log "Removing WSB Drive on $vmName"
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

