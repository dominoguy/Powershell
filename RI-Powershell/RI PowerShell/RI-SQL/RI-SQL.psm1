#RI-SQL

function Backup-SQLInstance
{
    param(
        [Parameter(Mandatory=$true)][string]$Instance,
        [Parameter(Mandatory=$true)][string]$Destination)
	
	$servername = 'localhost'

	Import-Module -Name 'SQLPS' -ErrorAction SilentlyContinue
	mkdir -Path $Destination -ErrorAction SilentlyContinue
	$dataBasePath = "SQLSERVER:\SQL\$serverName\$Instance\Databases"
	$databaseList = Get-ChildItem -Path $dataBasePath

	foreach($database in $databaseList)
	{
		$backupSuffix = 'bak'
		
		$databaseName = $database.Name
		Backup-SqlDatabase `
			-Path $databasePath `
			-Database $databaseName `
			-BackupFile "$Destination\$databaseName.$backupSuffix"
	}
}

function Get-SQLCommandLineToolPath
{
	param (
		[string]$Version = '11')
	
	if ($Version -eq '11')
	{
		$path = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.exe'
	}
	
	return $path
}

function Start-SQLScript
{
	param(
	    [Parameter(Mandatory=$true)][string]$ChildPath)
	
	$sqlcmdPath = Get-SQLCommandLineToolPath -Version 11
	$scriptPath = Get-RIPowershellResourcesPath -ChildPath $ChildPath
	$argumentList = "-E -S np:\\.\pipe\MICROSOFT##WID\tsql\query -i " + "`"$scriptPath`""
	Start-Process -FilePath $sqlcmdPath -ArgumentList $argumentList -NoNewWindow -Wait
}

function Test-SQLCommandLineTool
{
	param (
		[string]$Version = '11')
	
	if ($Version -eq '11')
	{
		$path = Get-SQLCommandLineToolPath
		$installed = Test-Path -Path $path
	}
	
	return $installed
}