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

#$LogLocation = "F:\Data\Scripts\Powershell\ClientBCSS\Logs\$ServerName-$curdate.log"
$LogLocation = "E:\Data\Scripts\ClientBCSS\Logs\$ServerName-$curdate.log"
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
#$bcSnap = "F:\Data\Scripts\Powershell\ClientBCSS\BCSnap.txt"
#$DataDir = "F:\Data"
#$BCSSDir = "F:\Data\Backups\BCSS"
$bcSnap = "E:\Data\Scripts\ClientBCSS\BCSnap.txt"
$DataDir = "E:\Data"
$BCSSDir = "E:\Data\Backups\BCSS"

$BCSSName = "$ServerName-$curDate"

$BCSSDirExist = Test-Path -path $BCSSDir

If ($BCSSDirExist -eq $False)
{
    New-Item -ItemType "Directory" -Force -Path "$BCSSDir"
}

$argsBCSS = "@$bcSnap /closescript $DataDir $BCSSDir $BCSSName"
Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
Write-Log "Completed: New BCSS snapshot of $ServerName"
