#RI-Logging

function Get-FormattedVerboseDate
{
	$format = 'yyyy-MM-dd HH:mm:ss'
	$time = Get-Date -Format $format
	
	return $time
}

function Get-FormattedDate
{
	$format = 'yyyy-MM-dd'
	$time = Get-Date -Format $format
	
	return $time
}

function New-RIPowerShellEvent
{
	[CmdletBinding()]
	
	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][string]$Source,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	#PowerShell Core ----------------------------------------------------------
	if (!(Test-IsPowerShellCore))
	{
		$logName = 'RI PowerShell'
		$defaultCategory = 1

		if (Test-RIPowerShellLogExists)
		{
			Write-EventLog `
			-LogName $logName `
			-Source $Source `
			-Message $Message `
			-EntryType $EntryType `
			-EventId $EventId `
			-Category $defaultCategory `
			-ErrorAction SilentlyContinue
		}
	}
}

function Test-RIPowerShellLogExists
{
	$logName = 'RI PowerShell'
	$logExists = $true

	try
	{
		Get-EventLog -LogName $logName -Newest 1 -ErrorAction SilentlyContinue
	}
	catch
	{
		$logExists = $false
	}

	return $logExists
}

function New-RIPowerShellApplicationEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Application'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellBackupEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Backup'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellEngineEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Engine'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellMetaEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Meta'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellShellEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Shell'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellUpdateEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Update'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellWindowsUpdateEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Windows Update'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellUserProfilesEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell User Profiles'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellVirtualizationEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell Virtualization'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}

function New-RIPowerShellWsusEvent
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true)][string]$Message,
		[Parameter(Mandatory=$true)][ValidateSet('Error','Information','Warning')][string]$EntryType,
		[Parameter(Mandatory=$true)][Int32]$EventId)

	$source = 'RI PowerShell WSUS'
	New-RIPowerShellEvent -Message $Message -EntryType $EntryType -EventId $EventId -Source $source
}


function Get-RIPowerShellEventSources
{
	$configFile = 'Modules\RI-Logging\eventsources.cfg'
	$resourcePath = Get-RIPowerShellResourcesPath -ChildPath $configFile
	$sourceList = Get-Content -Path $resourcePath

	return $sourceList
}

function Register-RIPowerShellEventSource
{
	#PowerShell Core ----------------------------------------------------------
	if ((Test-ShellElevation) -and !(Test-RemoteSession) -and !(Test-IsPowerShellCore))
	{
		$logName = 'RI PowerShell'	
		$sourceList = Get-RIPowerShellEventSources

		foreach ($source in $sourceList)
		{
			New-EventLog -LogName $logName -Source $source -ErrorAction SilentlyContinue
		}

		$sourceListSummary = $sourceList -join "`n"
		$message = "Registered the following log sources: `n$sourceListSummary"
		New-RIPowerShellEngineEvent -Message $message -EntryType Information -EventId 100
	}
}

function Unregister-RIPowerShellEventSource
{
	if (Test-ShellElevation)
	{
		$logName = 'RI PowerShell'	
		$sourceList = Get-RIPowerShellEventSources

		foreach ($source in $sourceList)
		{
			Remove-EventLog -Source $source
		}

		Remove-EventLog -LogName $logName
	}
}