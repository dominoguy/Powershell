#VM Startup 
#This script will start up VMs based on the criteria on a client's vm specs


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

function Write-StatusLog
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"
#$Client = $HVSName.Split("-")[0]
$ScriptPath = "D:\Data\Scripts\Startup" 
$logFile = "$ScriptPath\Logs\VM-Startup-$curdate.log"
#$logFile= "D:\Backups\RIBackup\RIMonthly\Logs\StartVM-$curdate.log"
$StatusLog = "$ScriptPath\Logs\VM-StartUpCheck-$curdate.log"

$logFileExists = Test-Path -path $logFile

if ( $logFileExists -ne $True)
{
    New-Item -ItemType File -Force -Path $logFile
}

$StatusLogExists = Test-Path -path $StatusLog
if ($StatusLogExists -ne $True)
{
    New-Item -ItemType File -Force -Path $StatusLog
}

Function TimeOut
{
    [CmdletBinding()]
    Param(
        [String]$ServiceToCheck,
        [String]$TimeOut,
        [String]$SleepPeriod
    )
    #Start Timer
    $timer = [Diagnostics.Stopwatch]::StartNew()
    Write-Log "Waiting for the $ServiceToCheck service check"
    $Condition = $False
    While (($Condition -eq $False) -and ($timer.Elapsed.TotalSeconds -lt $Timeout))
    {
        #Check timer
        $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
        IF ((Get-Service $ServiceToCheck).Status -NE "Running")
        {
            Start-Sleep -Seconds $SleepPeriod
            Write-Host "$ServiceToCheck still not started after $totalSecs seconds."
        }
        elseIf ((Get-Service $ServiceToCheck).Status -eq "Running") {
            $Condition = $True
        }
    }
    #Stop the timer - The action either completed or timed out. 
    $timer.Stop()

    If ($timer.Elapsed.TotalSeconds -gt $Timeout) 
    {
        Return $False,$totalSecs
    } 
    else 
    {
        Return $True,$totalSecs
    }

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

Function SendEmail {
    [CmdletBinding()]
    Param(
        [String]$From,
        [String]$Subject,
        [String]$Body,
        [String]$Attachments
    )

    $SMTPServer = "smtp.4web.ca"
    #$SMTPServer = "ri-exch-002.ri.ads"
    $SMTPUser = "smtp@renatus.ca"
    $SMTPPWD = "Gamma@Echo42"
    $Port = "587"
    #$Port = "25"
    $To = "brianlong@renatus.ca"
    
    $email = New-Object System.Net.Mail.MailMessage
    $email.From = $From
    $email.To.Add($To)
    $email.Subject = $Subject
    $email.Body = $Body
    $email.isBodyhtml = $true
    $smtp = New-Object Net.Mail.SmtpClient $SMTPServer,$Port
    $smtp.Credentials = New-Object System.Net.NetworkCredential ($SMTPUser,$SMTPPWD)
    $smtp.EnableSSL = $False
    $smtp.Port = 587
    $emailAttachment = New-Object Net.Mail.Attachment $Attachments
    $email.Attachments.add($emailAttachment)
    $smtp.Send($email)
    $smtp.Dispose()
}

$HVSName = HOSTNAME.EXE
#Email Settings
$From = "$HVSName@renatus.ca"

Write-Log "---------- Starting VMs ----------"
#Check if StartUp file is present
$StartupFile = "$Scriptpath\VMSettings.csv"

$StartupFileExists = Test-Path -path $StartupFile
If($StartupFileExists -eq $True)
{
    Write-Log "Startup File Exists. VMS STartUp procedure continues."
    #Check to see VMMS is started
    $TimeOut = 30
    $ServiceToCheck = "VMMS"
    $SleepPeriod = 2

    $ServiceStarted = Timeout $ServiceToCheck $TimeOut $SleepPeriod 

    IF($ServiceStarted[0] -eq $True)
    {
        Write-Log "$ServiceToCheck is started after"$ServiceStarted[1]"seconds"
        #VMMS is started - continue starting up VMS
        $VMList = Import-CSV -Path $StartupFile
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
        #VM Check
        #check vm if autostart is set, set it to nothing
        #test when a vm has autostart and if it collides with boot script
        #compare existing vms on server vs in startup vm list and notifiy in separate email if there is a miss match

        #Get a list of VMs on the server
        Write-Log "Checking VM StartAction"
        $VMS = get-vm | Select-Object Name,Status,State,AutomaticStartAction,AutomaticStartDelay,AutomaticStopAction}
        ForEach ($VM in $VMS)
        {
            $VMName = $VM.Name
            $VMStatus = $VM.Status
            $VMState = $VM.State
            $VMStartAction = $VM.AutomaticStartAction
            $VMStartDelay = $VM.AutomaticStartDelay
            $VMStopAction = $VM.AutomaticStopAction
            Write-Log "  Checking $VMName"
            IF ($VMStartAction -NE "Nothing")
            {
                get-vm $VMName | Set-VM -AutomaticStartAction Nothing
                Write-StatusLog "$VMName Automatic Start Action is now set to Nothing"
            }
            else
            { 
                Write-StatusLog "$VMName is OK."
            }
        }


        Write-Log "---------- End VM Start Up ----------"
        $Subject = "$HVSName - VM Startup Procedure Completed"
        $Body = "$HVSName has initiated VM startup procedure. See attached log for details. Check the HVS and VMs for any issues."
        $Attachments = "$logFile"
        SendEmail $From $Subject $Body $Attachments
    }
    ElseIF($ServiceStarted[0] -eq $False)
    {
        Write-Log "$ServiceToCheck did not start before the timeout period of $Timeout seconds"
        Write-Log "---------- End VM Start Up ----------"
        $Subject = "$HVSName - VM Startup Procedure Warning: A Service Did Not Start"
        $Body = "$ServiceToCheck did not start before the timeout period of $Timeout seconds. NO VMs started"
        $Attachments = "$LogFile"
        SendEmail $From $Subject $Body $Attachments
    }
}
else 
{
    Write-Log "$HVSName has no startup file. Startup VMs procedure aborted"
    Write-Log "---------- End VM Start Up ----------"
    $Subject = "$HVSName - VM Startup Procedure Warning: No StartUp VM File"
    $Body = "$HVSName Could not find the startup file for this server. NO VMs started"
    $Attachments = "$LogFile"
    SendEmail $From $Subject $Body $Attachments
}
