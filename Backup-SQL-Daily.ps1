#Backup-SQL-Daily

<#
.SYNOPSIS
Creates an SQL backup of all databases on the SQL Server instance


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


Set-Location "SQLSERVER:\SQL\Computer\Instance\Databases"
foreach ($database in (Get-ChildItem )) {
    $dbName = $database.Name
    Backup-SqlDatabase -Database $dbName -BackupFile "\\mainserver\databasebackup\$dbName.bak" }