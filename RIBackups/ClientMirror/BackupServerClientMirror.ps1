#BackupServerClientMirror

#This script uses Beyond Compare to mirror the client data on the backup server with the client server, keeping newer files on the backup server at specified date.
#This script can be run after:
#a) The yearly backup of the client is done
#b) The BCSS of the client server is done
#Requirements: A Beyond Compare Snapshot of the client server, note the date as it is required to keep newer files on the backup server





function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$appPath = "F:\Data\Scripts\Powershell\RIBackups\ClientMirror"
#$appPath = "D:\Backups\RIBackup\ClientMirror"

$logFile = "$appPath\Logs\ClientMirror.log"

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start Client Mirror"


#Add server list and csv file pull
$ClientsList = "$appPath\ClientsList.csv"
$Clients = Import-CSV -Path $ClientsList -Delimiter ','
$bcApp = "C:\Program Files\Beyond Compare 4\BCompare.exe"
$bcScptMirror = "$appPath\BCMirrorScript.txt"

ForEach ($client in $Clients)
{
    $clientName = $client.Client
    $serverName = $client.ServerName
    $backupDir = $client.ClientDir
    $TargetDir = $client.TargetDir
    $BCSSDir = $client.BCSSDir
    $bcssFile = $client.bcssFile
    $CutOffDate = $client.CutOffDate
    $bcClientSnapshot = "$BCSSDir\$bcssFile"
    $ClientDir = "$backupDir\$clientName\$servername\$TargetDir"

    $bcLog = "$appPath\Logs\$serverName-Mirror.Log"

    Write-Log "Starting Mirroring of $servername"
    $argsBCSS = "@$bcScptMirror /closescript $ClientDir $bcClientSnapshot $bcLog $CutOffDate"
    Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
    Write-Log "Completed mirroring of $servername. See $servername-Mirror.log for details"

    
}
Write-Log "Finished Client Mirror"
