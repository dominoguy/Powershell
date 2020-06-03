#ServerConfigInfo-HVS


#list of all vhdx on hv host
#date and time
#schedule tasks on hvs host

#send data to RI-FS-001

<#
.SYNOPSIS
This script returns server configuration information from Hyper V servers with regards to the VMs

.DESCRIPTION
This script returns the following: name of the VM, its VHDXs attached, its network adapter and its vlan information.
It will also list all of the virtual  disks (VHDX) on the host (date, size)
It will take a backup of the scheduled tasks 
It will check the replication health of VMs


.PARAMETER OutPutLocation
The local save location of data
IE. F:\Data\ServerConfigInfo
.PARAMETER RemoteSave
The remote save location of data. Must be in an UNC Path
IE. \\RI-FS-001.ri.ads\d$\data\ServerConfigInfo
#>

param(
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath,
        [Parameter(Mandatory=$False,HelpMessage='Remote Save Location, must be in an UNC path')][string]$RemoteSave
    )
<#
.SYNOPSIS
Writes to a log.
.Description
Creates a new log file in the designated location.
.PARAMETER logstring
String of text
#>

$ServerName = get-content env:computername
$SaveLocation = $OutPutFilePath + "\" + $ServerName
function Write-Log
{
    Param(
            [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}
$LogLocation =$SaveLocation + "\" + 'ServerConfig.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

function Write-Text
{
    Param(
        [string]$Textstring)

    $Time=Get-Date
    Add-Content $Textfile -value "$Textstring"
}



Write-Log 'Starting ServerConfig'

$SchedTaskFolderPath =  $SaveLocation + "\" + 'SchedTasks'


$SaveLocationExists = Test-Path -path $SaveLocation
if ( $SaveLocationExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $SaveLocation
}

$SchedPathExists = Test-Path -path $SchedTaskFolderPath
if ($SchedPathExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $SchedTaskFolderPath
}

#$sb= New-Object System.Text.StringBuilder
#$VMList = New-Object System.Collections.Generic.List[Stystem.String]
$VMs = Get-VM | Select-Object -ExpandProperty Name

foreach($VM in $VMs)
{   
    $Savefile = $SaveLocation + "\" + $VM + ".txt"
   
    "VM General Info" | Out-File -FilePath $Savefile
    Get-VM $VM | Select-Object VMName,VMID,State,Uptime,ReplicationState | Out-File -FilePath $Savefile -NoClobber -Append

    "VM Disk Info" | Out-File -FilePath $Savefile -NoClobber -Append
    Get-VM $VM | Get-VMHardDiskDrive | Select-Object  VMName,ControllerType,ControllerNumber,ControllerLocation,DiskNumber,Path | Out-File -FilePath $Savefile -NoClobber -Append

    "VM Network Adapter Info" | Out-File -FilePath $Savefile -NoClobber -Append
    Get-VM $VM | Get-VMNetworkAdapter | Select-Object Name,SwitchID,Connected,MACAddress,Status,IPAddresses | Out-File -FilePath $Savefile -NoClobber -Append

    "VM VLAN Info" | Out-File -FilePath $Savefile -NoClobber -Append
    Get-VM $VM | Get-VMNetworkAdapterVlan |  Out-File -FilePath $Savefile -NoClobber -Append
}

#Remote Save
If ($RemoteSave -eq "" -or $null -eq $RemoteSave)
{
    Write-Log "Not Saving remotely"
}
else 
{
    Write-Log "Saving remotely"
    #Test Conection to target server
    $RemoteServer = [regex]::match($RemoteSave,'^\\\\(.*?)\\').Groups[1].Value
    If (Test-connection -Cn $RemoteServer -BufferSize 16 -count 1 -ea 0 -quiet)
    {
        Write-Log "Copying to remote save location"
        $RemoteSavePathExists = Test-Path -path $RemoteServer
        if ($RemoteSavePathExists -eq $False)
        {
            New-Item -ItemType Directory -Force -Path $RemoteSave
        }
        Copy-Item -Path $SaveLocation -Destination $RemoteSave -Recurse -Force
    }
    else 
    {
        Write-Log "Target Server is not available"
    }
}


