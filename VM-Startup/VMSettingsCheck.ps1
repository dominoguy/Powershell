#VMSettingsCheck

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"
$OutPutFilePath = "F:\Data\Scripts\Powershell\VM-Startup"
$logFile = "$OutPutFilePath\Logs\VMSettingsCheck.log"
#$logFile = "D:\Backups\RIBackup\RIMonthly\Logs\VMSettingsCheck.log"

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

Write-Log "Start VM Settings Check for $curDate"
$HyperVlist = 'F:\Data\Scripts\Powershell\ServerList\HVSServerList.csv'
$HyperVServers = Import-Csv $HyperVlist

ForEach ($HVS in $HyperVServers)
{   
    $HVSName = $HVS.Name
    $HVSDomain = $HVS.Domain
    $HVSFQDN = "$HVSName.$HVSDomain"
    $Client = $HVSName.Split("-")[0]
    Write-Log "Getting VM Settings for $HVSName"

    IF (Test-Connection -ComputerName $HVSFQDN -Quiet)
    {
        $ResultsCSV = "D:\Data\Scripts\Clients\$Client\$HVSName\VMCurrentSettings.csv"
        #Create results file
        $ResultsExists = Test-Path -path $ResultsCSV
        $Headers = '"VMName","Status","State","AutomaticStartAction","AutomaticStartDelay","AutomaticStopAction"'
        if ( $ResultsExists -eq $True)
        {
            Remove-Item $ResultsCSV
            New-Item -ItemType File -Force -Path $ResultsCSV
            Add-Content -Path $ResultsCSV -Value $Headers
        }
        else
        {
            New-Item -ItemType File -Force -Path $ResultsCSV
            Add-Content -Path $ResultsCSV -Value $Headers
        }
        Write-Log "A Results File has been created for $HVSName"

        #$VMS = Get-VM -ComputerName "$HVSName.ri.ads" | Select-Object Name,Status,State,AutomaticStartAction,AutomaticStartDelay,AutomaticStopAction
        $VMS = Invoke-Command -Computername $HVSFQDN -ScriptBlock{param($var1) get-vm | Select-Object Name,Status,State,AutomaticStartAction,AutomaticStartDelay,AutomaticStopAction}
        ForEach ($VM in $VMS)
        {
            $VMName = $VM.Name
            $VMStatus = $VM.Status
            $VMState = $VM.State
            $VMStartAction = $VM.AutomaticStartAction
            $VMStartDelay = $VM.AutomaticStartDelay
            $VMStopAction = $VM.AutomaticStopAction
            Write-Log "  Checking $VMName"
            $Results = [PSCustomObject]@{
                VMName = $VMName
                Status = $VMStatus
                State = $VMState
                AutomaticStartAction = $VMStartAction
                AutomaticStartDelay = $VMStartDelay
                AutomaticStopAction = $VMStopAction
            } 
            $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
        }
        Write-Log "Finished Checking VMs on $HVSName"
    }
    else {
        Write-Log "**** $HVSFQDN is not reachable ****"
    }
}
Write-Log "Finished VMSettings Check"







