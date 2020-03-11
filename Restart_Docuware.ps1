#Restart Docuware 2.0
#Brian Long February 21, 2020
<#
.SYNOPSIS
Stops the Docuware Desktop service executable and restarts the Docuware service based on a trigger file.
DocuwareRestart.hta
Scheduled task
Program
    Powershell.exe
Arguments
-ExecutionPolicy Bypass F:\Data\Scripts\Powershell\Restart_Docuware.ps1 -TriggerLocation 'F:\Data\Scripts\Docuware\Reset.txt' -LogLocation 'F:\Data\Scripts\Docuware\Logs\DocuwareRestart.log'

.DESCRIPTION
Users request a restart by running the Docuware_Rest.hta which creates a trigger file.
This script checks every 5 minutes for the existence of the file and if so stops the Docuware Desktop service executable and restarts the service, then deletes the trigger document

.PARAMETER TriggerLocation
Location of the list of psts in CSV format
IE. F:\Data\Scripts\Docuware\Reset.txt

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\DocuwareReset.log
#>

param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage='Location of Trigger File')][string]$TriggerLocation,
        [Parameter(Mandatory=$true,Position=2,HelpMessage='Location of Log file')][string]$LogLocation
   )

<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logstring
String of text
#>
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
function Restart-Docuware
{
    $Arguments = "/f /fi ""Username eq blongadmin"" /im notepad.exe"
    start-process taskkill -ArgumentList $Arguments
    #maybe required if the taskkill is still running when service is restarted
    #start-sleep -Seconds 10
    Start-Service -Name "Xbox Live Game Save"
    Remove-item $strTrigger
  
#taskkill /F /FI "Username eq docuwareservice" /IM "DocuWare.DesktopService.exe *32"
}

#temp Variables
#$strTrigger = "F:\Data\Scripts\Docuware\Reset.txt"
$strTrigger = $TriggerLocation
#$logFile = "F:\Data\Scripts\Docuware\Logs\DocuwareRestart.log"
$logFile = $LogLocation

If (Test-Path -Path $strTrigger -PathType Leaf)
{
    $logFileExists = Test-Path -path $logFile
        if ( $logFileExists -eq $False)
        {
         New-Item -ItemType File -Force -Path $logFile
        }

Restart-Docuware
Write-Log "Docuware has been restarted"
}