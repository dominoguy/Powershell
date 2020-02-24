#Number of Files and Size of Directory
<#
.SYNOPSIS
This script will calculate the number of files and the size of directories

.DESCRIPTION
The script will access a list of directories to work on from a .csv file. 
It will then calculate the number of files per directory and keep a subtotal for a final total of directories in the list.
Next it will calculate the size of the directories and convert to MG or GB, it will total sub directories and give a final total

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


$logFile = 'F:\Data\Scripts\Powershell\LOGS\DirectoryCount.log'
#$logFile = $LogLocation
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

Write-Log "Directory Count Begins"

