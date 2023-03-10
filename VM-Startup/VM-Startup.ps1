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
$logFile = "$ScriptPath\Logs\VM-Startup-$curdate.log"
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
    $Timeout = 300
    #VM-Settings create a csv options file, include timeout
	Wait-VM -Name $VMName -For Heartbeat -Delay 5 -Timeout $Timeout
    $heartbeat = (Get-VM $VMName | Select-Object Heartbeat).Heartbeat
    if (($heartbeat -eq 'OkApplicationsHealthy') -or ($heartbeat -eq 'OkApplicationsUnknown'))
    {
        Write-Log "$VMName is started, it has a Hearbeat"
        Return ("True")
    }
    else
    {
        Write-Log "**** $VMName has no Heartbeat after $Timeout seconds. Exiting Startup VMS, no other VMs will be started ****"
        Return ("False")
    }
}

Write-Log "---------- Starting VMs ----------"

#Check to see if VMMS Service is running if not wait
While ((Get-Service VMMS).Status -NE "Running")
{
    Write-Log "Waiting for the VMMS Service"
    Start-Sleep -Seconds 2
    #need to break out also
}

$StartupFile = "$Scriptpath\VMSettings.csv"
$VMList = Import-CSV -Path $StartupFile
#if file is not here end
#check vm if autostart is set, set it to nothing
#test when a vm has autostart and if it collides with boot script
#email log after boot
#compare existing vms on server vs in startup vm list and notifiy in separate email if there is a mix match
#Get a list of primary servers (start first)
$VMBootOrder = $VMList.Where({$PSItem.BootOrder -ne ""}) | Sort-Object BootOrder

:BootOrder ForEach ($VM in $VMBootOrder)
{
    $VMName = $VM.VMName
    $VMBootOrder = $VM.BootOrder
    $VMDependencies = $VM.Dependencies
    Write-Log "$VMName - Performing pre-start check"
    Write-Log "The VM Boot order is $VMBootOrder"
    $ArrVMDepend = $VMDependencies.Split(',')
    $VMStart = "True"
    #for each vm in dependencies check to see if it is up
    IF($ArrVMDepend -Ne "")
    {
        Write-Log "The VM Dependencies are $VMDependencies"
        ForEach($VMD in $ArrVMDepend)
        {
         $State = (Get-VM $VMD | Select-Object State).State
         If ($State -ne "Running")
         {
              $VMStart = "False"
              Write-Log "**** Error ****"
              Write-Log "**** $VMName is NOT started, it needs $VMD to be started first ****"
          }
         }
    }
    else
    {
        Write-Log "There are no dependencies for this VM"
    }
    #If true then start target vm
    IF ($VMStart -eq "True")
    {
        Write-Log "Pre-check OK. Starting $VMName"
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
        $CheckVM = Check-VM -VMName $VMName
        IF($CheckVM -eq "False")
        {
            Break BootOrder
        }

    }

}
Write-Log "---------- End VM Start Up ----------"
