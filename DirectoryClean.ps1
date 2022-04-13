#Directory Clean Up
#Brian Long 18March2022
#version 1.0
<#
.SYNOPSIS
Some program backups save their backups by file name plus date and creates a new file each time, thus filling a drive.
This program keeps x amount of files in a designated directory.


.DESCRIPTION
This script keeps a designated amount of files in a directory and deletes the oldest first
Pass in the parameters in single quotes:
.\DirectoryClean.ps1 'F:\Data\Scripts\Powershell\LOGS\DirectoryCleanUp.log' '20' 'F:\Data\TestFolder'

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\FileSizeCheck.log
.PARAMETER NumberOfFilesToKeep
IE. 10

.PARAMETER dirLocation
Location of directory to be cleaned
IE. F:\Data\TestFolder
#>

param(
        [Parameter(Mandatory=$True,Position=1,HelpMessage='Location of Log FIle')][string]$LogLocation,
        [Parameter(Mandatory=$True,Position=2,HelpMessage='Number of files to keep')][String]$NumberFilesToKeep,
        [Parameter(Mandatory=$True,Position=3,HelpMessage='Location of directory to be cleaned')][string]$dirLocation
    )

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

#$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\DirectoryCleanUp.log'
#$NumberFilesToKeep = 20
#$dirLocation = 'F:\Data\TestFolder'

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

Write-Log "Start Directory Clean Up"

$NumberFiles = (Get-ChildItem $dirLocation | Measure-Object).Count
$FileCount = 0
Write-Log "The number of files to keep $NumberFilesToKeep"
Write-Log "The original number of files $NumberFiles"
If($NumberFiles -gt $NumberFilesToKeep)
{
do {
    Get-ChildItem $dirLocation | Sort-Object -Property LastWriteTime | Select-Object -First 1 | Remove-Item -Recurse
    $NumberFiles = (Get-ChildItem $dirLocation | Measure-Object).Count
    $FileCount = $FileCount + 1
} until ($NumberFiles -le $NumberFilesToKeep)

}

Write-Log "Number of files deleted is $FileCount"
Write-Log "End Directory Clean Up"