# Backup File Rename

<#
.SYNOPSIS
Many vendors\developers create a backup files of there programs but add a date on the file.
After a time these files will build up and need to be cleaned up.
As well it creates additional files in backup which are duplicated due to incremental and monthly backups.
Possible to add code to clean up vendor backup files.

.DESCRIPTION
This script removes the date from the file name and copies the file to a designated directory for backup.
The script will keep 30 days of the vendors backups and deleting anything older.
There should NOT be any other files in this directory than the backup files.
Backup scripts should excempt the vendors backup directory from the client backup.

Sample file name:
    Back_Office_Database_2018-09-04--03-00-12.7z

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\BackupRename.log
.PARAMETER DBFilePath
The location of the database to be renamed
IE. 'F:\Sandbox\ClientServer\ACE\ACE-FS-001\Data\ACT\Backup'
.PARAMETER DBNewLocation
The location of the renamed database
IE. 'F:\Sandbox\ClientServer\ACE\ACE-FS-001\Data\Backup\ACT'
.PARAMETER DBFileNameSearch
The part of the name of the database which will be used to find the correct file.
IE. "Act! Ace_Manufacturing*.txt"
.PARAMETER NewDBName
The new name of the database
IE. 'ACT_Backup.txt'

#>
param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='DB FIle Path')][string]$DBFilePath,
        [Parameter(Mandatory=$true,HelpMessage='DB New Location Path')][string]$DBNewLocation,
        [Parameter(Mandatory=$true,HelpMessage='DB FileNameSearch')][string]$DBFileNameSearch,
        [Parameter(Mandatory=$true,HelpMessage='New DB Name')][string]$NewDBName
    )

#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

<# 
.Synopsis
Adds a leading zero to date for months of single digits
.PARAMETER ModDate
The day, month or year that requires a leading zero if single digit
#>

#Functions
function ModDate
{
    Param(
        [string]$Date)
    if ($Date.length -eq 1) {
        $date = '0' + $Date
    }
 return $date
}
#>

#Script Starts

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

Write-Log "Backup Rename Begins"

$backupFilePath = $DBFilepath
#$backupFIlePath = 'F:\Sandbox\ClientServer\ACE\ACE-FS-001\Data\ACT\Backup'
$backupFileDir = $DBNewLocation
#$backupFileDir = 'F:\Sandbox\ClientServer\ACE\ACE-FS-001\Data\Backup\ACT'
$backupFileNameSearch = $DBFileNameSearch
#$backupFileNameSearch = "Act! Ace_Manufacturing*.txt"
$backupFileName = $NewDBName
#$backupFileName = 'ACT_Backup.txt'

#Date-Time
$curDate = Get-Date -Uformat "%m/%d/%Y"

Get-ChildItem -Recurse -Path $BackupFIlePath -Filter $backupFileNameSearch |
ForEach-Object {

    $backupFileFullPath = $_.FullName
    $dbName = $_.Name
    $lastAccessed =  $_.LastAccessTime
    $lastAccessed = (Moddate $lastAccessed.Month), (Moddate $lastAccessed.Day), (Moddate $lastAccessed.Year) -join "/"
    IF ($curDate -eq $lastAccessed)
    {
        Copy-Item -Path $backupFileFullPath -Destination "$backupFileDir\$backupFileName" -Force
        Write-Log ($dbName + " Database Renamed and Copied")
    }

}

Write-Log "Backup Rename Ends"