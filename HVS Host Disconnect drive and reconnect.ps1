
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
#IF there are an  equal number of start files end files then we can proceed 
#get the IP address of the vm
$IPResult = Get-VM $VMName | Select-object -ExpandProperty networkadapters | select-Object ipaddresses
$VMIP =$IPResult.Ipaddresses
Write-Log "The IPAddress of $VMName is $VMIP"

#get the credentials to access the read share on the vm
$Username = "ri\bakreadservice"
$Password = "VreBkE7PSC8yUfM5xKu1"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

#get into the share to access the read file of the vm


#Get the domain for the guest
#$Result = Invoke-Command $VMName -Credential $cred -ScriptBlock {Get-WmiObject -class win32_computersystem}
#$Domain = $Result.Domain
#Write-Log "The domain is $Domain"

#this may require a net use using the bacreadservice
New-PSDrive -Name "Q" -Root "\\$VMIP\$VMName-Status$" -Persist -PSProvider "FileSystem" -Credential $cred

#$StatusPath = "\\$VMIP\$VMName-Status$"

$StatusPathExists = Test-Path -Path $StatusPath
IF ($StatusPathExists -eq $True)
    {
        $StatusStarts = Invoke-Command $VMName -Credential $cred -ScriptBlock {(get-ChildItem -Path "\\$VMIP\$VMName-Status$" *Start.txt | Measure-Object).count}
        $StatusFinish = Invoke-Command $VMName -Credential $cred -ScriptBlock {(get-ChildItem -Path "\\$VMIP\$VMName-Status$" *Finish.txt | Measure-Object).count}

        Write-Log "$VMName Number of Starts is $StatusStarts"
        Write-Log "$VMName Number of Finish is $StatusFinish"
        
        If ($StatusStarts -eq $StatusFinish)
        {
            write-log "We can Checkpoint $VMName"
            #Remove WSB drive from VM
            #Do the Rolling Checkpoint on the VM
            #Attach the WSB drive to the VM 
        }
        else
        {
            write-log "Error: Cannot CheckPoint: a process is still unfinished"
        }
    }
    else 
    {
        Write-Log "$VMName-Status$ share is not visible" 
    }
    
} 

