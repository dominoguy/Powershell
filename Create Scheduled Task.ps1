#Create Scheduled Task

<#
.SYNOPSIS
This script creates a Scheduled Task

.DESCRIPTION
Scheduled Tasks creation may be an issue on servers without the GUI. This script creates a scheduled task with the appropriate input.
Command line option: schtasks /create /tn RSYNC-ACAWT-SQL-002 /tr F:\Scripts\ManualBackup-ACAWT-SQL-002.cmd /sc daily /st 19:00 /ru system /rl HIGHEST

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\Create-Sched-Task.log

#>

#>
param(
        [Parameter(Mandatory=$False,HelpMessage='Location of Log file')][string]$LogLocation
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

$logLocation = "F:\Scripts\Logs"
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}


$TaskName ="RSYNC-ACAWT-SQL-002"



Write-Log "Start Creation of $TaskName Scheduled Task"

#$STA = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass D:\Scripts\WB-Hyper-V-VMs.ps1 -LogLocation 'D:\Scripts\Logs\WB-Hyper-VM.log'"
#$STA = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass F:\Data\Scripts\Powershell\WB-Hyper-V-VMs.ps1 -LogLocation 'F:\Data\Scripts\Powershell\Logs\WB-Hyper-VM.log'"
$STA = New-ScheduledTaskAction -Execute "ManualBackup-ACAWT-SQL-002.cmd"
$STT = New-ScheduledTaskTrigger -Daily -At 7pm
$STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Taskname $TaskName -Action $STA -Trigger $STT -Principal $STPrin

Write-Log "Finished Creating $TaskName Scheduled Task"
