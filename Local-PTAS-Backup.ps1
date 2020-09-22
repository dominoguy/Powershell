#Local-PTAS-Backup

<#
.SYNOPSIS
Creating a set of local CDAT backups in addition to shadowcopies and offsite backups
This set is x number of days worth with the oldest being deleted.
It will create a folder for each backup labeled by 1 to x. (each file will be named the same)

.DESCRIPTION
This script checks if is x number of copies and if so then deletes the oldest one, then copies the newest one.

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\PTAS-Local-Backup.log
.PARAMETER DBFilePath
The current location of the database to be copied
IE. 'F:\Data\Server\CDATSW\database_backup'
.PARAMETER DBBackupLocation
The location of the new backup database
IE. 'F:\Backups\CDAT-LocalBackup'
.PARAMETER DBFileNameSearch
The part of the name of the database which will be used to find the correct file.
IE. 'PTAS.dmp'

#>

param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='DB FIle Path')][string]$DBFilePath,
        [Parameter(Mandatory=$true,HelpMessage='DB New Location Path')][string]$DBBackupLocation,
        [Parameter(Mandatory=$true,HelpMessage='DB FileNameSearch')][string]$DBFileNameSearch

    )

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
    
    Write-Log "Local PTAS Backup Begins"

#Get the current date 
$curDate = Get-Date -Uformat "%m/%d/%Y"

Get-ChildItem -Recurse -Path $DBBackupLocation -Filter $DBFileNameSearch |
ForEach-Object {

    $DBBackupLocation= $_.FullName
    $dbName = $_.Name
    $lastAccessed =  $_.LastAccessTime
    $lastAccessed = (Moddate $lastAccessed.Month), (Moddate $lastAccessed.Day), (Moddate $lastAccessed.Year) -join "/"
    IF ($curDate -eq $lastAccessed)
    {
        Copy-Item -Path $backupFileFullPath -Destination "$backupFileDir\$backupFileName" -Force
        Write-Log ($dbName + " Database Renamed and Copied")
    }

}