#Create Scheduled Task

<#
.SYNOPSIS
This script creates a Scheduled Task

.DESCRIPTION
Scheduled Tasks creation may be an issue on servers without the GUI. This script creates a scheduled task with the appropriate input.

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\Create-Sched-Task.log

#>

#>
param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation
    )
<#

<#
Parameters
TaskName
Trigger (Time)
TaskAction -execute powershell -location of script
Principal
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
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}


$TaskName ="Add VM Backup Drive"
$Trigger = '-Daily -At 4pm'


Write-Log "Start Creation of $TaskName Scheduled Task"

$STA = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass D:\Scripts\WB-Hyper-V-VMs.ps1 -LogLocation 'D:\Scripts\Logs\WB-Hyper-VM.log'"
#$STA = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass F:\Data\Scripts\Powershell\WB-Hyper-V-VMs.ps1 -LogLocation 'F:\Data\Scripts\Powershell\Logs\WB-Hyper-VM.log'"
$STT = New-ScheduledTaskTrigger -Daily -At 6pm
$STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Taskname $TaskName -Action $STA -Trigger $STT -Principal $STPrin

Write-Log "Finished Creating $TaskName Scheduled Task"
