# Backup Server Cleanup Ver 1.0

<#
.SYNOPSIS
This process will remove older data on the backup server which no longer exists on the client server.
Do only after the yearly baseline (complete copy) of the client data has been completed.


.DESCRIPTION
Requirements
    BCSS of data directory on client server
    Ensure that there are no errors in the BCSS log

Run the client server BCSS against the client data on the backup server
This process will delete anything on client data on the backup server that is not part of the BCSS (orphaned on the backupserver side) and is older than the BCSS.
You should be left with what is on the client server and anything same/newer than the time of when the client BCSS was taken.
Check the Cutoff Date
Check the BCSS Year

.PARAMETER ServerList
Location of the list of client server directories in csv format
IE. F:\Data\Scripts\Powershell\RIMonthly\serverslist.csv
G:\Backups\RIBackup\RIMonthly\serverslist.csv

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\2019_BackupCleanUp.log
G:\Backups\RIBackup\RIMonthly\LOGS\BC_Comparison.log
#>

param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage='Location of CSV ServerList')][string]$ServerList,
        [Parameter(Mandatory=$true,Position=2,HelpMessage='Location of Log file')][string]$LogLocation
    )

<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logText
Text added to log
#>
function Write-Log
{
    Param(
        [String]$logText)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logText"
}

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

Write-Log "Backup Server Clean Up Begins"

$date = Get-Date
$currentMonth = $date.Month
$currentYear = $date.Year
$bcssYear = 2018
$bcssCutOffDate = "12/17/2018"
$runPath = $PSScriptRoot
$bcApp="C:\Program Files\Beyond Compare 4\BCompare.exe"
$bcBackupCleanupOptions = "@$runPath\BackupCleanupOptions.txt"

$list = Import-Csv $ServerList

foreach ($row in $list)
{
    $ClientDIr = $row.ClientDIr
    $Path = $ClientDIr.split("\")
    $drive = $Path[0]

    $Folder1 = $Path[1]
    $Folder2 = $Path[2]
    $dirFolder = $Path[3]
    $dirClient = $Path[4]
    $dirServer = $Path[5]
    $dirBackupDir = 'Backups'
    

    #$dirFolder = $Path[1]
    #$dirClient = $Path[2]
    #$dirServer = $Path[3]

    $dirData = "$drive\$folder1\$folder2\$dirBackupDir\$dirClient\$dirServer\Data"
    #$dirData = "$drive\$dirBackupDir\$dirClient\$dirServer\Data"

    $bcssFileDir  = "$drive\$folder1\$folder2\$dirBackupDir\$dirClient\$dirServer\Data\Backups\BCSS"
    #$bcssFileDir  = "$drive\$dirBackupDir\$dirClient\$dirServer\Data\Backups\BCSS"
  

    $bcssFile = "$drive\$folder1\$folder2\$dirBackupDir\$dirClient\$dirServer\Data\Backups\BCSS\Baseline_" + $dirServer + "_" + $bcssYear + ".bcss"
    #$bcssFile = "$drive\$dirBackupDir\$dirClient\$dirServer\Data\Backups\BCSS\Baseline.bcss"

    $bcsslog = "$drive\$folder1\$folder2\$dirBackupDir\$dirClient\$dirServer.log"
    #$bcsslog = "$drive\$dirBackupDir\$dirClient\$dirServer.log"

    write-Log "*** Running the cleanup for $dirserver ***"
    Start-Process $bcApp -argumentlist "$bcBackupCleanupOptions $dirData $bcssFile $bcssCutOffDate $bcssLog" -NoNewWindow -Wait
    write-Log "*** Completed the cleanup for $dirserver ***"
}

Write-Log "Backup Server Clean Up Ends"