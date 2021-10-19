#Backup-SQL-Daily

<#
.SYNOPSIS
Creates an SQL backup of all databases on the SQL Server instance
Requires the SQLServer module
Install-Module -name SQLServer
get-sqlinstance requires SQLServer Cloud Adapter service to be running


.DESCRIPTION
This script does a full SQL backup of all the databases of an SQL server instance

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\PTAS-Local-Backup.log
.PARAMETER DBFilePath
The current location of the database to be copied
IE. 'F:\Data\Server\CDATSW\database_backup'
.PARAMETER DBBackupLocation
The location of the new backup database
IE. 'F:\Backups\CDAT-LocalBackup'
.PARAMETER ServerInst
The name of the ServerInst
IE. 'PTAS.dmp'
#>

<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logstring
String of text
#>
<#
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\SQLBackup.log'

param(
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of Log FIle')][string]$LogLocation,
        [Parameter(Mandatory=$False,Position=2,HelpMessage='Location of the SQL DBs')][string]$DBFilePath,
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of the backup')][string]$DBBackupLocation,
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Name of the Server Instance')][string]$ServerInst
    )

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




Write-Log "Starting SQL Backup"
#>

#Set-Location SQLSERVER:\SQL
#cd "D:\Data\Server\SQL\MSSQL14.MSSQLSERVER\MSSQL\DATA"
Set-Location -path "D:\Data\Server\SQL\MSSQL14.MSSQLSERVER\MSSQL\DATA"
foreach ($database in (Get-ChildItem ))
{
    $dbName = $database.Name
    Backup-SqlDatabase -Database $dbName -BackupFile "D:\Temp\$dbName.bak" 
}