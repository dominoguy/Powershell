#RI-Local-Backup
<#
.SYNOPSIS
RSYNC backup from client to the backup location

.DESCRIPTION
This script rsyncs data from client and sends the data to a backup location.
There 7 days of logs kept.

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\LOGS\RILocalBackup.log
.PARAMETER Clientname
The name of client
IE. SHEP
.PARAMETER ClientServer
Name of the server to be backed up
IE. SHEP-MEM-001
.PARAMETER BackupLocation
The location of backup
IE. 192.168.112.12 
.PARAMETER IsDataDir
Determining the root of the backup on the client.
RI setup will have the data under D:\Data
Other setups may have the data starting under the root of D:\
IE. $True for D:\Data and $False for D:\
.PARAMETER RSYNCLogDir
Location of RSYNC logs, organized by day of the week
IE. F:\Data\Scripts\Logs
.PARAMETER RSYNCExceptionPath
Location of the RSYNCException file
IE. F:\Data\Scripts
File name format = ExcludeFilter_<servername>.txt
IE. ExcludeFilter_SHEP-MEM-001.txt
#>

param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
       # [Parameter(Mandatory=$true,HelpMessage='Client Name')][string]$Clientname,
       # [Parameter(Mandatory=$true,HelpMessage='Name of computer to be backed up')][string]$ClientServer,
        [Parameter(Mandatory=$true,HelpMessage='Location of Backup')][string]$BackupLocation,
        [Parameter(Mandatory=$true,HelpMessage='Is there a data directory $True or $False')][string]$IsDataDir,
        [Parameter(Mandatory=$true,HelpMessage='The directory of RSYNC Backup Logs')][string]$RSYNCLogDir,
        [Parameter(Mandatory=$true,HelpMessage='The directory of the RSYNC Exception List')][string]$RSYNCExcludeDir
    )

function Write-Log
{
 Param(
      [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
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

Write-Log "RiLocal Backup Begins"

$ClientServer = Get-Content env:computername
$ClientName = $ClientServer.Split("-")[0]

If ($IsDataDir -eq $true)
{
#Need to figure the logic for the dir path and adding file names for logs and exclude files
#Need to map drive to target NAS - this is for the log file
}


#Set location of RSYNC Backup Logs
$curDay = (Get-Date).DayOfWeek
$RSYNCLogDir = $RSYNCLogDir + "\" + $curDay
$RSYNCLogFile = $Clientname + "-Backup-" + $ClientServer + "-Incremental.log"
$RSYNCLogDirExist = Test-Path -path $RSYNCLogDir
    If ($RSYNCLogDirExist -eq $true)
     {
        Remove-Item -path $RSYNCLogDir + "\" + $RSYNCLogFile
     }
    else
    {
        New-Item -ItemType "directory" -Path $RSYNCLogDir
    }

#Map drive to target
$Password = ConvertTo-SecureString "RlHrUsPHtPSZjBVeLvY9" -AsPlainText -Force
$cred =New-Object System.Management.Automation.PSCredential ("shep\nasbackupservice",$Password)
New-PSDrive -Name "Backup" -Root "\\192.168.112.12\shep" -PSProvider "Filesystem" -Credential $cred

$env:RSYNC_PASSWORD='2012B@ckup!'

$RSYNCBaseVar = '-vvrt --modify-window=2 --out-format="TransferInfo: %20t %15l %n" --log-file-format="%i %15l %20M %-10o %n" --stats --timeout=300 --contimeout=120'
#$RSYNCExcludeFile = 'F/Data/Scripts/Powershell/RILocal/ExcludeFilter.txt'
$RSYNCExcludeDir = ($RSYNCExcludeDir -replace "[\\]", "/") -replace ":", ""
$RSYNCExcludeVar = ' --exclude-from="/cygdrive/' + $RSYNCExcludeDir + '/ExcludeFilter-' + $ClientServer + '.txt"'
#$RSYNCLogFile = 'F/Data/Scripts/Powershell/RILocal/Incremental.txt'
$RSYNCLogDir = ($RSYNCLogDir -replace "[\\]", "/") -replace ":", ""
$RSYNCLogVar = ' --log-file="/cygdrive/' + $RSYNCLogDir + '/' + $Clientname + '-Backup-' + $ClientServer + '-Incremental.log"'



$Source = ' "/cygdrive/F/Data/"'
$DestPath = 'Backups/RI/RI-dt-008/Data/'

#$Dest = ' "rsync-bkup@10.0.7.79::' + $DestPath +'"'
$Dest = ' "rsync-bkup@' + $BackupLocation + '::' + $DestPath +'"'
$RSYNCVars = $RSYNCBaseVar + $RSYNCExcludeVar + $RSYNCLogVar + $Source + $Dest

Start-Process -FilePath "C:\Program files\icw\bin\rsync.exe" -Argumentlist $RSYNCVars

Write-Log "RiLocal Backup Ends"
















Remove-PSDrive -Name "Backup"