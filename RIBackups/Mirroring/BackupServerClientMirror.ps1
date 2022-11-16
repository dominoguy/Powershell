#BackupServerClientMirror

#This script uses Beyond Compare to mirror the client data on the backup server with the client server, keeping newer files on the backup server at specified date.
#Requirements: A Beyond Compare Snapshot of the client server, note the date it is started as the snapshot may take days to complete.
#Note: Any files, created on or newer than the start date of the snapshot or the last date of a completed daily backup whichever is the oldest, are to be kept.




function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = "F:\Data\Scripts\Powershell\Backups\Mirroring\ClientMirror.log"
$logFile = $LogLocation

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}

#Add server list and csv file pull


Write-Log "Start Client Mirror"

$bcApp = "C:\Program Files\Beyond Compare 4\BCompare.exe"
$bcClientSnapshot = "F:\Data\Scripts\Powershell\Backups\Mirroring\TEST2_2022-11-16.bcss"
#$bcClientSnapshot = ""
$bcScptMirror = "F:\Data\Scripts\Powershell\Backups\Mirroring\BCMirrorScript.txt"
#$bcMirror = ""

$ClientDir = "F:\TEST1"
$bcLog = "F:\Data\Scripts\Powershell\Backups\Mirroring\Mirror.Log"
$CutOffDate = "11/16/2022"

$argsBCSS = "@$bcScptMirror /closescript $ClientDir $bcClientSnapshot $bcLog $CutOffDate"
Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
Write-Log "Completed mirroring of client data on backup server. See Mirror.log for details"

Write-Log "Finished Client Mirror"
