#Client Server BCSS

#This script runs Beyond Compare to get a snapshot of the files on the client server
#Requirements: Beyond Compare to be installed
#BCSS file name = <ServerName-Year-Month-Day.bcss

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"
$ServerName = $env:computername

$LogLocation = "F:\Data\Scripts\Powershell\RIMonthly\Logs\$ServerName-$curdate.log"
#$LogLocation = "D:\Backups\RIBackup\RIMonthly\Logs\$ServerName-$curdate.log"
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

Write-Log "Start BCSS for $ServerName"

$bcApp = "C:\Program Files\Beyond Compare 4\BCompare.exe"
$bcSnap = "F:\Data\Scripts\Powershell\RIMonthly\BCSnap.txt"
#$bcSnap = "D:\Backups\RIBackup\RIMonthly\BCSnap.txt"
$DataDir = "D:Data"

$argsBCSS = "@$bcSnap /closescript $BackupsDir $bcssCurDate $BaselinesDir $bcssExceptions"
Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
Write-Log "Completed: New BCSS snapshot of $ServerName\$DataDir"
