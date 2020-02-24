# Manual Backups
<#
.SYNOPSIS
When the regular client backups do not finish, it may be advantages to run the backup during the day.
This script can run mulitple client backups asynchronously

.DESCRIPTION
This script runs Powershell Jobs for each client server in CSV file. Each Job will be tracked so it can be manually stopped or restarted as necesarry.

.PARAMETER LogLocation
Location of script log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\BackupRename.log
.PARAMETER ServerLog
The location of the list of client servers being backed up
IE. 'F:\Data\Scripts\Powershell\ManualBackup\Logs\ServersWorking.log'
#>

#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

function BuildRsync
{
    
}

$LogLocation = "F:\Data\Scripts\Powershell\ManualBackups\Logs\ManualBackup.log"

$logFile = $LogLocation
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


Write-Log "Manual Backup Begins"

#Get list of servers to manually backup
$serverListLocation = "F:\Data\Scripts\Powershell\ManualBackups\ServerList.csv"
$serverList = Import-Csv $serverListLocation

foreach ($row in $serverList)
{#Get list of parameters to build the RSync command
    $DoBackup = $row.DoBackup
    $ServerName = $row.ServerName
    $LogVerbosity = $row.LogVerbosity
    $StopTime = $row.StopTime
    $RSyncLogFIle = $row.RSyncLogFIle
    $ExcludeFile = $row.ExcludeFile
    $RSyncCommand = $row.RSyncCommand
    $BackupLocation = $row.BackupLocation
    $RedirectLog = $row.RedirectLog

    IF ($DoBackup -eq "Y")
    {
    $List = $DoBackup + " " + $ServerName + " " + $LogVerbosity + " " + $StopTime + " " + $RSyncLogFIle + " " + $ExcludeFile + " " + $RSyncCommand + " " + $BackupLocation + " " + $RedirectLog
    Write-Log $List
    }
}


Write-Log "Manual Backup Ends"


#For each item in the list
    #If checked 'Y' then the entry is to be backed up
    #Build the rsync command
    #create a friendly name for the job
    #Start a PS Job
       
        #track its Job name
        #log its progress
        #notify if completed or failed
