#RI-Update

function Test-RIPowerShellSessionBuild
{
	[CmdletBinding()]
	
	$installedBuild = Get-RIPowerShellInstalledBuild
	$sessionBuild = Get-RIPowerShellSessionBuild

	if ($sessionBuild -lt $installedBuild)
	{
		$version = Get-RIPowerShellVerboseVersion -Scope Installed
		Write-MetaMessage -Message "RI PowerShell has been updated to $version. Please start a new session."
	}

	if ($sessionBuild -gt $installedBuild)
	{
		$version = Get-RIPowerShellVerboseVersion -Scope Installed
		Write-Warning -Message "RI PowerShell has been reverted to $version. Please start a new session."
	}
}

<#
.SYNOPSIS
Packages and exports RI PowerShell to a deploy path.

.DESCRIPTION
Packages and exports Release and Beta versions of RI PowerShell to a deploy path.

.PARAMETER Channel
Channel to export to. Valid channels are Beta (default) and Release.

.EXAMPLE
Export-RIPowerShell -Channel Release
#>
function Export-RIPowerShell
{
	param(
		[Parameter(Position=1)][ValidateSet('Release', 'Beta')][string]$Channel = 'Beta')
	
	if (Test-ShellElevation)
	{
		if (Test-DevelopmentEnvironment)
		{
			$flatFolder = 'RI PowerShell'
			$fileName = 'RI PowerShell.zip'
			$destinationPath = ''

			if ($Channel -eq 'Beta')
			{
				$destinationPath = Get-RIPowerShellBetaDeployPath
			}
			
			if ($Channel -eq 'Release')
			{
				$destinationPath = Get-RIPowerShellDeployPath
			}

			$developmentPath = Get-DevelopmentPath
			$flatTempFolder = New-TempFolder
			$stagingFolder = Join-Path -Path $flatTempFolder -ChildPath $flatFolder
			Copy-RIPowerShell -Source $developmentPath -Destination $stagingFolder
			$zipTempFolder = New-TempFolder
			$zipFile = Join-Path -Path $zipTempFolder -ChildPath $fileName
			New-ZipFileFromDirectory -Path $stagingFolder -FileName $zipFile
			Copy-Item -Path $zipFile -Destination $stagingFolder
			Copy-RIPowerShell -Source $stagingFolder -Destination $destinationPath
			Remove-Item -Path $flatTempFolder -Recurse
			Remove-Item -Path $zipTempFolder -Recurse
		}
		else
		{
			Write-Warning -Message 'This operation cannot be performed outside a development environment.'
		}
	}
}

<#
.SYNOPSIS
Updates RI PowerShell.

.DESCRIPTION
Updates RI PowerShell by a specified scope, Local by default.

.PARAMETER Scope
Scope of the update. Valid scopes are:

Deploy
Dev
Local

.PARAMETER StartNewSession
Starts a new PowerShell session after completing the update.

.EXAMPLE
Update-RIPowerShell -Scope Local
#>
function Update-RIPowerShell
{
	param(
		[Parameter(Position=1)][ValidateSet('Local', 'Deploy', 'Dev', 'Beta')][string]$Scope = 'Local',
		[switch]$StartNewSession)

	if (Test-ShellElevation)
	{
		$zipFileName = 'RI PowerShell.zip'
		
		$deployPath = Get-RIPowerShellDeployPath
		$betaDeployPath = Get-RIPowerShellBetaDeployPath
		$installPath = Get-RIPowerShellPath

		if ($Scope -eq 'Deploy')
		{
			Show-DeprecatedBehaviourWarning -Message 'Deploy scope is now deprecated. Use Export-RIPowerShell -Channel Release instead.'
		}

		if ($Scope -eq 'Dev')
		{
			Show-DeprecatedBehaviourWarning -Message 'Dev scope is now deprecated. Use Update-RIPowerShellDevelopmentBuild instead.'
		}

		if ($Scope -eq 'Local')
		{
			$accessToDeploy = Test-Path $deploypath -ErrorAction SilentlyContinue

			if ($accessToDeploy)
			{
				$zipFilePath = Join-Path -Path $deployPath -ChildPath $zipFileName
				$zipFileExists = Test-Path -Path $zipFilePath

				if ($zipFileExists)
				{
					Install-RIPowerShellFromZip -Path $deploypath
				}
				else
				{
					Copy-RIPowerShell -Source $deployPath -Destination $installPath
					Update-RIPowerShellProfile
				}
			}
			else
			{
				$taskName = 'Deploy RI PowerShell'

				Start-ScheduledTask -TaskName $taskName
			}
		}

		if ($Scope -eq 'Beta')
		{
			$accessToDeploy = Test-Path $betaDeployPath -ErrorAction SilentlyContinue

			if ($accessToDeploy)
			{
				$zipFilePath = Join-Path -Path $betaDeployPath -ChildPath $zipFileName
				$zipFileExists = Test-Path -Path $zipFilePath

				if ($zipFileExists)
				{
					Install-RIPowerShellFromZip -Path $betaDeployPath
				}
			}
		}

		if ($StartNewSession)
		{
			Start-PowerShell -Exit
		}
	}
}

<#
.SYNOPSIS
Updates a development build of RI PowerShell.

.DESCRIPTION
Updates a development build of RI PowerShell, incrementing the build number by 1.
#>
function Update-RIPowerShellDevelopmentBuild
{
	if (Test-ShellElevation)
	{
		if (Test-DevelopmentEnvironment)
		{
			$developmentPath = Get-DevelopmentPath
			$installPath = Get-RIPowerShellPath
			Set-RIPowerShellBuild
			Copy-RIPowerShell -Source $developmentPath -Destination $installPath
			Update-RIPowerShellProfile
		}
	}
}

function Install-RIPowerShellFromZip
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	$sourceFolder = 'RI PowerShell'
	$zipFileName = 'RI PowerShell.zip'

	$zipFilePath = Join-Path -Path $Path -ChildPath $zipFileName
	$tempFolder = New-TempFolder
	Copy-Item -Path $zipFilePath -Destination $tempFolder
	$tempFilePath = Join-Path -Path $tempFolder -ChildPath $zipFileName
	$sourcePath = Join-Path -Path  $tempFolder -ChildPath $sourceFolder
	Expand-ZipFile -File $tempFilePath -Destination $tempFolder
	$installPath = Get-RIPowerShellPath
	Copy-RIPowerShell -Source $sourcePath -Destination $installPath
	Remove-Item -Path $tempFolder -Recurse
	Update-RIPowerShellProfile
}

function Copy-RIPowerShell
{
	param(
		[string]$Source,
		[string]$Destination)

	robocopy $Source $Destination `
		/MIR /W:0 /R:0 /XD ".git" ".vscode" /XF ".gitignore" ".gitattributes" /NFL /NDL
}

function Update-RIPowerShellProfile
{
	param(
		[ValidateSet('Default','WinPE')][string]$Profile = 'Default')

	$psHomePathList = 'C:\Windows\System32\WindowsPowerShell\v1.0', 'C:\Program Files\PowerShell\6'
	$profileFile = ''

	if ($Profile -eq 'Default')
	{
		$profileFile = 'Profiles\Default\profile.ps1'
	}
	
	if ($Profile -eq 'WinPE')
	{
		$profileFile = 'Profiles\WinPE\profile.ps1'
	}

	$installPath = Get-RIPowerShellPath
	$profilePath = Join-Path -Path $installPath -ChildPath $profileFile

	foreach ($psHomePath in $psHomePathList)
	{
		$psHomePathExists = Test-Path -Path $psHomePath

		if ($psHomePathExists)
		{
			Copy-Item -Path $profilePath -Destination $psHomePath
		}
	}
}

function Get-RIPowerShellDeployPath
{
	$deployPath = Get-DeployPath
	$path = Join-Path -Path $deployPath -ChildPath '\RI PowerShell'

	return $path
}

function Get-RIPowerShellBetaDeployPath
{
	$deployPath = Get-DeployPath
	$path = Join-Path -Path $deployPath -ChildPath '\RI PowerShell Beta'

	return $path
}

function Update-RIPowerShellDownstreamServers
{
	Param(
		[Parameter(Mandatory=$true,Position=1)][string]$CredentialFile,
		[switch]$Beta)

	$serverList = Import-Csv -Path $CredentialFile

	foreach ($server in $serverList)
	{
		$releasePath = 'RI PowerShell'
		$betaPath = 'RI PowerShell Beta'
		$psDriveName = 'remoteServer'
		$deploySource = ''
		$installPath = ''

		$serverFQDN = $server.serverFQDN
		$username = $server.username
		$password = $server.password
		$credential = Get-CredentialViaPlainText -Username $username -Password $password
		$remoteDeployPath = '\\' + $serverFQDN + '\Deploy'

		if ($Beta)
		{
			$deploySource = Get-RIPowerShellBetaDeployPath
			$installPath = Join-Path -Path $remoteDeployPath -ChildPath $betaPath
		}
		else
		{
			$deploySource = Get-RIPowerShellDeployPath
			$installPath = Join-Path -Path $remoteDeployPath -ChildPath $releasePath
		}

		try
		{
			New-PSDrive -Name $psDriveName -PSProvider FileSystem -Root $remoteDeployPath -Credential $credential -ErrorAction Stop
			robocopy $deploySource $installPath /MIR /W:0 /R:0 /XD ".git" ".vscode" /XF ".gitignore" ".gitattributes"
			$message = "Deployed RI PowerShell to downstream server $serverFQDN."
			New-RIPowerShellUpdateEvent -Message $message -EntryType Information -EventId 700
		}
		catch [System.Exception]
		{
			$message = "Unable to deploy RI PowerShell to downstream server $serverFQDN."
			Write-Host "ERROR: `n$message`n" -ForegroundColor Red
			New-RIPowerShellUpdateEvent -Message $message -EntryType Error -EventId 900
		}

		Remove-PSDrive -Name $psDriveName -ErrorAction SilentlyContinue
	}
}

function Update-RIPowerShellModuleManifests
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Version)

	if (Test-ShellElevation)
	{
		$developmentPath = Get-DevelopmentPath
		$moduleList = Get-ChildItem -Path $developmentPath -Recurse -Filter *.psd1
		
		foreach ($module in $moduleList)
		{
			$path = $module.fullName
			Update-ModuleManifest -Path $path -ModuleVersion $Version
		}
	}
}