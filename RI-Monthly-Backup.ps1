#RI-Monthly-Backup
#
#This script takes a monthly incremental backup and a full backup in December using Beyond Compare to get the differences.
#Drives on the backup servers need to be switched out to facilitate the full backup - drive size is calculated manually.






function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$logString = 'F:\Data\Scripts\Powershell\LOGS\RI-Monthly-Backup.log'

