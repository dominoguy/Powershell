#Create Scheduled Task

<#
.SYNOPSIS
This script creates a Scheduled Task

.DESCRIPTION
Scheduled Tasks creation may be an issue on servers without the GUI. This script creates a scheduled task with the appropriate input.
check to see if scheduled task is created
    Get-ScheduledTask
To delete task after modifications
    Unregister-ScheduledTask -TaskName "Create Add USB Drive Scheduled Task"

.PARAMETER LogLocation
Location of log file and its name
IE. D:\Data\Scripts\LOGS\Create-Sched-Task.log

#>



$TaskName ="Add VM Backup USB Drive"
$Trigger = '-Daily -At 4pm'

$STA = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass D:\Data\Scripts\ACEVM-Attach-USB-Drive.ps1"
$STT = New-ScheduledTaskTrigger -Daily -At 4pm
$STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Taskname $TaskName -Action $STA -Trigger $STT -Principal $STPrin

