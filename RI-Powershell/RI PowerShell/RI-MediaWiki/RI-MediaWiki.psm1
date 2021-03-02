#RI-MediaWiki

function Backup-MediaWikiFiles
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$WebRoot,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)
	
	$zipName = 'webroot.zip'
	
	$zipPath = Join-Path -Path $Path -ChildPath $zipName
	$zipExists = Test-Path -Path $zipPath
	
	if ($zipExists)
	{
		Remove-Item -Path $zipPath
	}
	
	New-ZipFileFromDirectory -Path $WebRoot -FileName $zipPath
}

function Backup-MediaWiki
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$WebRoot,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)	
	
	Backup-MediaWikiDatabase -Webroot $WebRoot -Path $Path
	Backup-MediaWikiFiles -Webroot $WebRoot -Path $Path
}

function Get-MediaWikiLocalSettingsPath
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Webroot)
		
	$localSettingsFile = 'LocalSettings.php'
	$localSettingsPath = Join-Path -Path $WebRoot -ChildPath $localSettingsFile
		
	return $localSettingsPath
}

function Get-MediaWikiLocalSettingsContent
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Webroot)
		
	$localSettingsPath = Get-MediaWikiLocalSettingsPath -Webroot $Webroot
	$localSettings = Get-Content -Path $localSettingsPath
	
	return $localSettings
}

function Backup-MediaWikiDatabase
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Webroot,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)
	
	$xmlFileName = 'database.xml'
	$hostnamePattern = 'wgDBserver'
	$usernamePattern = 'wgDBuser'
	$passwordPattern = 'wgDBpassword'
	$characterSetPattern = 'wgDBTableOptions'
	$databasePattern = 'wgDBname'

	$localSettings = Get-MediaWikiLocalSettingsContent -Webroot $Webroot
	$hostname = Get-ValueFromContent `
		-Content $localSettings `
		-Label $hostnamePattern `
		-RemoveCommonCharacters
	$username = Get-ValueFromContent `
		-Content $localSettings `
		-Label $usernamePattern `
		-RemoveCommonCharacters
	$password = Get-ValueFromContent `
		-Content $localSettings `
		-Label $passwordPattern `
		-RemoveCommonCharacters		
	$characterSet = Get-ValueFromContent `
		-Content $localSettings `
		-Label $characterSetPattern `
		-RemoveCharacters '^.*=','"',';'
	$database = Get-ValueFromContent `
		-Content $localSettings `
		-Label $databasePattern `
		-RemoveCommonCharacters		
	mysqldump `
		--host=$hostname `
		--user=$username `
		--password=$password `
		--default-character-set=$characterSet `
		--xml $database `
		> $Path\$xmlFileName
}