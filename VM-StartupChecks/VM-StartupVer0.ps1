#VM Startup 
#This script will start up VMs based on the criteria on a client's vm specs


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"
#$HVSName = HOSTNAME.EXE
#$Client = $HVSName.Split("-")[0]
$ScriptPath = "D:\Data\Scripts\Startup" 
$logFile = "$ScriptPath\Logs\StartVM-$curdate.log"
#$logFile= "D:\Backups\RIBackup\RIMonthly\Logs\StartVM-$curdate.log"

$logFileExists = Test-Path -path $logFile

if ( $logFileExists -ne $True)
{
    New-Item -ItemType File -Force -Path $logFile
}

function Check-VM
#Script will pause until the VM returns a Heartbeat
{
	param($VMName)
	Wait-VM -Name $VMName -For Heartbeat
}

Write-Log "Start VMS"
#Get the Startup List
$RIHomeFQDN = "RI-HDC-001.ri.ads" 
IF (Test-Connection -ComputerName $RIHomeFQDN -Quiet)
{
#get the vm csv file and copy to 
Write-log "Getting lastest Startup File"
}
else {
    Write-Log "Cannot connect to $RIHomeFQDN, using last copied Startup File"
}

$StartupFile = "$Scriptpath\VMSettings.csv"
$VMList = Import-CSV -Path $StartupFile
$Primary = "Primary"
#Get a list of primary servers (start first)
$VMListPrimary = $VMList.Where({$PSItem.Dependencies -eq $Primary})

ForEach ($VM in $VMListPrimary)
{
    $VMName = $VM.VMName
    $VMStart = $VM.Start
    Write-host "The VM primary is $VMName"
    Write-Host "The VM Start status is $VMStart"
    

    IF ($VMStart -eq "True")
    {
        Write-Log "Starting $VMName"
        Start-VM -Name $VMName -WarningVariable WarnMessage -ErrorVariable ErrMessage
        If($WarnMessage)
        {
            Write-Log "**** Warning ****"
            Write-Log "**** $WarnMessage ****"
        }
        If($ErrMessage)
        {
            Write-Log "**** Error ****"
            Write-Log "**** $ErrMessage ****"
        }
            Check-VM -VMName $VMName
        Write-Log "$VMName has a Hearbeat"
    }
}

<#
ForEach ($VM in $VMList)
{
    $VMName = $VM.VMName
    $Depend = $VM.Dependencies
    #Write-Host $VMName
    #Write-Host $Depend
}
#>
#Start the rest of the servers
#foreach($VM in $VMS where dependcies not equal to primary)

<#
check to see if mom is available
    get my startup csv
no mom use my latest startup csv
Startup CSV
name of vm
dependency servers
time delay
Find the first server that should be up
from startup csv use returnrow to get the primary server
check to see if server is up

function to check if a server is up


#>
