
<#
.SYNOPSIS
HVS Host Disconnect drive and reconnect drive

.DESCRIPTION

#Used in conjunction with WSB where a backup VHDX drive is mounted for a vm and then WSB runs its backup to it.
#We want to disconnect this drive before checkpoints are run so that we are not checkpointing the WSB backup
#For Each VM
#This script will check a hidden share on the VM called $Checkpoint where it will look for a <process>-start file and a corresponding <process>-Finish file
#The script will count the number of starts and finish files and if there is not an equal number of starts and finishes then checkpoints will not run.

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
if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}
#Get a list of VMs that are checkpointing
Write-Log "Starting Checkpoints"
$CheckpointVMs = 'c:\programdata\ri powershell\settings\ri-virtualization\rollingcheckpoints.csv'
$VMs = Import-CSV $CheckpointVMs | select-object -Property vmName,maxCheckpoints,diskLocation
Foreach ($VM in $VMs) 
{
$VMName = $VM.vmName
$NumberofCPs = $VM.maxCheckpoints
$diskLocation = $VM.diskLocation
Write-Log "Checking $VMName ...."

#get the IP address of the vm
$IPResult = Get-VM $VMName | Select-object -ExpandProperty networkadapters | select-Object ipaddresses
$VMIP =$IPResult.Ipaddresses
Write-Log $VMName": IPAddress is $VMIP"

#get the credentials to access the read share on the vm
$Username = "ri\bakreadservice"
$Password = "VreBkE7PSC8yUfM5xKu1"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

#get into the share to access the read file of the vm
$StatusPath = "\\$VMIP\$VMName-Status$" 
Write-Log $VMName": Checking share $StatusPath"
try
    {If (Test-Path -Path $StatusPath -ErrorAction Stop)
        {
            $StatusPathExists = $true
        }
    Else
        {
            $StatusPathExists = $False
            Write-Log $VMName": $VMName-Status$ share is not visible"
        }
    }
    Catch [UnauthorizedAccessException]
    {
        $StatusPathExists = $true
    }
#IF there are an  equal number of start files end files then we can proceed 
IF ($StatusPathExists -eq $True)
    {
        New-PSDrive -Name "Q" -Root $StatusPath -PSProvider "FileSystem" -Credential $cred
        $StatusStarts = (get-ChildItem -Path "Q:" *Start.txt | Measure-Object).count
        $StatusFinish = (get-ChildItem -Path "Q:" *Finish.txt | Measure-Object).count

        Write-Log $VMName": Number of Starts is $StatusStarts"
        Write-Log $VMName": Number of Finish is $StatusFinish"
        
        If ($StatusStarts -eq $StatusFinish)
        {
            write-log $VMName": We can do a Checkpoint"
            #check to see if there is a backup drive attached to the vm
            #IF there is a drive capture the path, in case the drive is VHD and not a usb drive
            #Is the drive going to be mounted onto the hvs or directly to the vm
            If (Get-VM $VMName | Get-VMHardDiskDrive -ControllerType SCSI -controllernumber 0 -controllerlocation 0)
            {
                    Write-Log "$VMName has a backup drive"
                    #Remove WSB drive from VM
                    #We need to grab the disk number for usb drive or the path for a vhdx before unmounting the drive from the vm
                    $VMDrive = Get-VM $VMName | Get-VMHardDiskDrive -ControllerType SCSI -controllernumber 0 -controllerlocation 0
                    $VMDrivePath = $VMDrive.Path
                    #Unmount the drive
                    Get-vm $VMName | get-vmharddiskdrive -controllertype SCSI -controllernumber 0 -controllerlocation 0 | remove-vmharddiskdrive
            }
            else {
                Write-Log "$VMName has no backup drive"
            }
            
            #If the drive cannot be unmounted email alert
                #exit
            #Do the Rolling Checkpoint on the VM
                #Create the VM CSV file list for function New-RollingVMCheckpoint
                <#
               $CSVFile = "C:\ProgramData\RI PowerShell\Settings\RI-Virtualization\$VMName-rollingcheckpoints.csv"
               $CSVFileExists = Test-Path -path $CSVFile
               $headers = 'vmName,maxCheckpoints,diskLocation'
               if ( $CSVFileExists -eq $True)
               {
                   Remove-Item $CSVFile
                   New-Item -ItemType File -Force -Path $CSVFile
                   Set-Content -Path $CSVFile - Value $headers
                   $A = Get-Content -Path $CSVFile
                   $A = $A[1..($A.Count - 1)]
                   $A | Out-File -FilePath $CSVFile
               }
               else
               {
                   New-Item -ItemType File -Force -Path $CSVFile
               }
            #>
        
                # after checkpoint is done - how is this returned?
                # if the checkpoint guid id can be  returned then i can be searched on the eventvwr on host
            #Attach the WSB drive to the VM
            #add-VMHardDiskDrive -VMName $VMName -controllertype SCSI -controllernumber 0 -controllerlocation 0 -path D:\Virtual\SHEP-EXCH-001\SHEP-EXCH-001-Backup.Vhdx
            Get-VM $VMName | Add-VMHardDiskDrive -ControllerType SCSI -ControllerNumber 0 -controllerlocation 0 -path $VMDrivePath
        }
        else
        {
            write-log $VMName": Error: Cannot CheckPoint: a process is still unfinished"
        }
        Remove-PSDrive -Name "Q"
    }
    
} 

#After checking all vms and unmounting backup drives call existing rolling checkpoint function using the list of vms check

