# Backup File Rename

<#
.SYNOPSIS
Many vendors\developers create a backup files of there programs but add a date on the file.
After a time these files will build up and need to be cleaned up.
As well it creates additional files in backup which are duplicated due to incremental and monthly backups.

.DESCRIPTION
This script removes the date from the file name and copies the file to a designated directory for backup.
The script will keep 30 days of the vendors backups and deleting anything older.
There should be any other files in this directory than the backup files.
Backup scripts should excempt the vendors backup directory from the client backup.

Sample file name:
    Back_Office_Database_2018-09-04--03-00-12.7z

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\BackupRename.log

#>
param(
        [Parameter(Mandatory=$true,Position=2,HelpMessage='Location of Log file')][string]$LogLocation
    )

#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

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

$backupFIlePath = 'F:\Sandbox\Server\Data\Group\Backup'
$backupFileNameSearch = 'Back_Office_Database*.txt'
$backupFileName = 'Back_Office_Database.txt'
$backupFileExtension = ".txt"

#Date-Time
$curDate = Get-Date -Uformat "%Y-%m-%d"
$curDate2 = Get-Date -Uformat "%m/%d/%Y"

Write-Log $curDate
Write-Log $curDate2
Write-Log $curdate2.get-type

#Get-ChildItem -Path $BackupFIlePath -Filter *.txt |
Get-ChildItem -Path $BackupFIlePath -Filter $backupFileNameSearch |
ForEach-Object {
    Write-Log $_.FullName
    Write-Log $_.Name
    $backupFileFullPath = $_.FullName
    $lastAccessed =  $_.LastAccessTime
    $lastAccessed = $lastAccessed.Month, $lastAccessed.Day, $lastAccessed.Year -join "/"
    Write-Log $lastAccessed
    IF ($curDate2 = $lastAccessed )
    {
        Copy-Item -Path $backupFileFullPath -Destination "$backupFIlePath\$backupFileName" -Force
        Write-Log "Database Renamed and Copied"
    }
   
}


#Rename the File
#Rename-item -Path "" -NewName ""
#Copy-Item -Path <full path of the file> -Destination <full path of target location of file, with file rename>

Write-Log "Backup Rename Ends"