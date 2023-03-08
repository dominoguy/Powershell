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
$logFile = "$OutPutFilePath\Logs\VMSetStartup.log"
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

Write-Log "Start Setting VM Startup on $curDate"
$HyperVlist = 'F:\Data\Scripts\Powershell\ServerList\HVSServerList.csv'
$HyperVServers = Import-Csv $HyperVlist

ForEach ($HVS in $HyperVServers)
{   
    $HVSName = $HVS.Name
    $HVSDomain = $HVS.Domain
    $HVSFQDN = "$HVSName.$HVSDomain"
    $VMStartExempt = $HVS.VMStartExcempt
    $arrVMStartExempt = $VMStartExempt.Split(',')
    Write-Host "The Excemption list is $VMStartExempt"
    $Client = $HVSName.Split("-")[0]
    Write-Log "Setting VM Startup Sequence for $HVSName"

    IF (Test-Connection -ComputerName $HVSFQDN -Quiet)
    {
       
        $VMS = Invoke-Command -Computername $HVSFQDN -ScriptBlock{param($var1) get-vm | Select-Object Name,Status,State,AutomaticStartAction,AutomaticStartDelay,AutomaticStopAction}
        ForEach ($VM in $VMS)
        {
            $VMName = $VM.Name
            $VMStatus = $VM.Status
            $VMState = $VM.State
            $VMStartAction = $VM.AutomaticStartAction
            $VMStartDelay = $VM.AutomaticStartDelay
            $VMStopAction = $VM.AutomaticStopAction
            Write-Log "Checking $VMName"
            Write-Log "     Current Status is $VMStatus"
            Write-Log "     Current State is $VMState"
            Write-Log "     Current AutomaticStartAction is $VMStartAction"
            Write-Log "     Current AutomaticStartDelay is $VMStartDelay"
            Write-Log "     Current AutomaticStopAction is $VMStopAction"
            IF ($arrVMStartExempt -contains $VMname)
            {
                Write-Host "$VMName is Excempt"
                Write-Log "     $VMName is excempt from standard startup rules"
            }
            ElseIF ($VMStartAction -NE "Nothing")
            {
                Write-Log "Changing Startup Sequence on $VMName"
                Invoke-Command -Computername $HVSFQDN -ScriptBlock{param($var1) get-vm $var1 | Set-VM -AutomaticStartAction Nothing} -ArgumentList $VMName
                $Item = Invoke-Command -Computername $HVSFQDN -ScriptBlock{param($var1) get-vm $var1 | Select-Object AutomaticStartAction} -ArgumentList $VMName
                $VMStartAction = $Item.AutomaticStartAction
                Write-Log "     Current AutomaticStartAction is $VMStartAction"
            }
        }
        Write-Log "Finished Setting VM Startup Sequence on $HVSName"
    }
    else {
        Write-Log "**** $HVSFQDN is not reachable ****"
    }
}
Write-Log "Finished VM Startup Settings"







