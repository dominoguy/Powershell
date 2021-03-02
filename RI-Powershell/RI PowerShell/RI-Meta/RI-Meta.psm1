#RI-Meta

function Get-AboutRIPowerShellPath
{
	param(
		[switch]$Development)

	$aboutFile = 'Resources\about.txt'

	if ($Development)
	{
		$riPowerShellPath = Get-DevelopmentPath
	}
	else
	{
		$riPowerShellPath = Get-RIPowerShellPath
	}

	$aboutPath = Join-Path -ChildPath $aboutFile -Path $riPowerShellPath

	return $aboutPath
}

function Get-RIPowerShellPath
{
	$childPath = 'Program Files\RI PowerShell'
	
	$systemDrive = $env:SystemDrive
	$path = Join-Path -Path $systemDrive -ChildPath $childPath

	return $path
}

function Get-RIPowerShellResourcesPath
{
	param(
		[Parameter(Mandatory=$true)][string]$ChildPath)
	
	$resourcesFolder = 'Resources'
	$riPowerShellPath = Get-RIPowerShellPath
	$resourcesPath = Join-Path -ChildPath $resourcesFolder -Path $riPowerShellPath
	$fullPath = Join-Path -ChildPath $ChildPath -Path $resourcesPath

	return $fullPath
}

function Get-RIPowerShellUserSettingsPath
{
	$childPath = 'RI PowerShell\Settings'
	$localAppDataPath = $env:localappdata
	$settingsPath = Join-Path -ChildPath $childPath -Path $localAppDataPath

	return $settingsPath
}

function Write-HighlightedMessage
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Message,
		[string]$Delimiter = '~',
		[string]$HighlightColor = 'Yellow')

	$defaultColor = $host.UI.RawUI.ForegroundColor
	$highlight = $false
	$chunkList = $Message.Split($Delimiter)

	foreach ($chunk in $chunkList)
	{
		if ($highlight)
		{
			$color = $HighlightColor
		}
		else
		{
			$color = $defaultColor
		}

		Write-Host -Object $chunk -ForegroundColor $color -NoNewline
		$highlight = !$highlight
	}

	Write-Host -Object "`r"
}

function Get-RIPowerShellInstalledBuild
{
	param(
		[switch]$Development)

	$aboutPath = ''

	if($Development)
	{
		$aboutPath = Get-AboutRIPowerShellPath -Development
	}
	else
	{
		$aboutPath = Get-AboutRIPowerShellPath
	}

	$buildCVAR = 'Build '
	
	$buildLine = Select-String -Path $aboutPath -Pattern $buildCVAR `
		-SimpleMatch -List | ForEach-Object {$_.Line}
	[int]$build = $buildLine -replace $buildCVAR,''

	return $build
}

function Get-RIPowerShellInstalledVersion
{
	$versionCVAR = 'Version '

	$aboutPath = Get-AboutRIPowerShellPath
	$versionLine = Select-String -Path $aboutPath -Pattern $versionCVAR `
		-SimpleMatch -List | ForEach-Object {$_.Line}
	$version = $versionLine -replace $versionCVAR,''

	return $version
}

function Get-RIPowerShellInstalledChannel
{
	$cvar = 'Channel '
	
	$aboutPath = Get-AboutRIPowerShellPath
	$cvarLine = Select-String -Path $aboutPath -Pattern $cvar `
		-SimpleMatch -List | ForEach-Object {$_.Line}
	$channel = $cvarLine -replace $cvar,''

	return $channel
}

function Get-RIPowerShellSessionChannel
{
	$channel = $env:RIPOWERSHELLCHANNEL

	return $channel

}
function Get-RIPowerShellSessionBuild
{
	$build = $env:RIPOWERSHELLBUILD

	return $build
}

function Get-RIPowerShellSessionVersion
{
	$version = $env:RIPOWERSHELLVERSION

	return $version
}

function Set-RIPowerShellBuild
{
	if (Test-ShellElevation)
	{
		$buildCVAR = "Build.*"
		
		$aboutPath = Get-AboutRIPowerShellPath -Development
		$aboutFile = Get-Content -Path $aboutPath
		$newContent = @()
		$build = Get-RIPowerShellInstalledBuild -Development
		$build++

		foreach ($line in $aboutFile)
		{
			$newLine = "Build " + $build
			$line = $line -replace $buildCVAR,$newLine
			$newContent += $line
		}

		Set-Content -Path $aboutPath -Value $newContent
	}
}

function Get-RIPowerShellVerboseVersion
{
	param(
		[ValidateSet('Installed','Session')]$Scope)

	$version = ''
	$channel = ''
	$build = ''

	if($Scope -eq 'Installed')
	{
		$version = Get-RIPowerShellInstalledVersion
		$channel = Get-RIPowerShellInstalledChannel
		$build = Get-RIPowerShellInstalledBuild
	}

	if($Scope -eq 'Session')
	{
		$version = Get-RIPowerShellSessionVersion
		$channel = Get-RIPowerShellSessionChannel
		$build = Get-RIPowerShellSessionBuild
	}

	if ($channel -eq 'Release')
	{
		$channel = $null
		$build = $null
	}
	else
	{
		$channel = ("-$channel").ToLower()
		$build = "+$build"
	}

	$verboseVersion = "v$version$channel$build"
		
	return $verboseVersion
}

function New-RIPowerShellModuleManifest
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Name,
		[string]$Path='.\',
		[Parameter(Mandatory=$true)][string]$Author,
		[Parameter(Mandatory=$true)][string[]]$FunctionsToExport)

	$minPowerShellVersion = '3.0'
	
	$moduleVersion = Get-RIPowerShellSessionVersion
	$moduleFileName = "$Name.psd1"
	$moduleFilePath = Join-Path -Path $Path -ChildPath $moduleFileName
	New-ModuleManifest `
		-Author $Author `
		-PowerShellVersion $minPowerShellVersion `
		-ModuleVersion $moduleVersion `
		-Path $moduleFilePath `
		-RootModule $Name `
		-FunctionsToExport $FunctionsToExport
}

function Show-DeprecationWarning
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Command)
		
	$message = "$Command is deprecated and will be removed in the next major version of RI PowerShell."
	Write-MetaMessage -Message "DEPRECATED: $Message"
	New-RIPowerShellMetaEvent -Message $message -EntryType Warning -EventId 500
}

function Show-DeprecatedBehaviourWarning
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Message)

	Write-MetaMessage -Message "DEPRECATED: $Message"
	New-RIPowerShellMetaEvent -Message $Message -EntryType Warning -EventId 501
}

<#
.SYNOPSIS
Verifies the version consistency of the RI PowerShell session.

.DESCRIPTION
Verifies that all module versions match the session version of RI PowerShell.
#>
function Test-RIPowerShellVersionConsistency
{
	$modulePrefix = 'RI-'
	
	$consistent = $true
	$sessionVersion = Get-RIPowerShellSessionVersion
	$moduleList = Get-Module -Name "$modulePrefix*" -ListAvailable

	for ($i = 0; $i -lt $moduleList.Count; $i++)
	{
		$module = $moduleList[$i]
		$name = $module.Name
		$version = $module.Version

		if ($version -ne $sessionVersion)
		{
			$consistent = $false
		}
		
		$activity = 'Test-RIPowerShellVersionConsistency' 
		$status = "Checking version for module $name"
		$percentComplete = ($i/$moduleList.Count*100)
		Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
	}

	return $consistent
}