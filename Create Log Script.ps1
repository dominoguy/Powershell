#Logging Script
Function LogWrite
{
    Param ([string]$logstring)
    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#Replaces the existing log or creates a new one if does not exist
$logFile = 'F:\Data\Scripts\Powershell\LOGS\PSTCopy.log'
$logPFileExists = Test-Path -path $logFile
If ( $logFileExists -eq $True) {
    Remove-Item $LogFile
    New-Item -ItemType File -Force -Path $LogFile
} 
Else {
    New-Item -ItemType File -Force -Path $LogFile}

#Calling the Function
LogWrite "PSTBackup Begins"