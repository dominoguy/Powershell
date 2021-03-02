#RI-System

function Get-Uptime
{
	Param(
		[Parameter(Position=1)][ValidateSet('Short', 'Verbose')][string]$OutputAs = 'Short')
		
	$operatingSystem = Get-CimInstance -ClassName win32_operatingsystem
	$uptime = (Get-Date) - ($operatingSystem.LastBootUpTime)
	
	if ($OutputAs -eq 'Short')
	{
		$uptimeDays = $uptime.Days.ToString("00")
		$uptimeHours = $uptime.Hours.ToString("00")
		$uptimeMinutes = $uptime.Minutes.ToString("00")
		
		$display = "$uptimeDays $uptimeHours $uptimeMinutes"
		$display = $display -replace ' ',':'
		
		return $display
	}
	
	if ($OutputAs -eq 'Verbose')
	{
		return $uptime
	}
}

function Get-LocalComputerName
{
	return "$env:COMPUTERNAME"
}

function Get-WindowsVersion
{
	$windowsVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
	$windowsVersion = $windowsVersion -replace 'Microsoft ',''
	
	return $windowsVersion
}

function Get-WindowsVersionNumber
{
	$verboseVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
	$version = ($verboseVersion -replace '\.\d*$','')

	return $version
}

function Get-WindowsArchitecture
{
	$windowsArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
	
	return $windowsArchitecture
}

function Get-WindowsMajorVersion
{
	$verboseVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
	$majorVersion = [int]($verboseVersion -replace "\..*",'')

	return $majorVersion
}

function Get-WindowsReleaseID
{
	$registryKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
	$registryKeyValue = 'ReleaseId'
	$minimumVersion = 10

	$majorVersion = Get-WindowsMajorVersion

	if ($majorVersion -ge $minimumVersion)
	{
		$releaseID = (Get-ItemProperty -Path $registryKey -Name $registryKeyValue -ErrorAction SilentlyContinue).ReleaseId

		if ($releaseID)
		{
			$releaseID = "$releaseID "
		}

		return $releaseID
	}
	else
	{
		return $null
	}
}

function Get-SystemSummary
{
	$minimumVersionNumber = 6.2
	$summary = @()
	$windowsVersion = Get-WindowsVersion
	$releaseID = Get-WindowsReleaseID
	$windowsArchitecture = Get-WindowsArchitecture
	$uptime = Get-Uptime
	$summary += "OS Version : $windowsVersion $releaseID$windowsArchitecture"
	$summary += "Uptime     : $uptime days"
	$windowsVersionNumber = [float](Get-WindowsVersionNumber)

	if ($windowsVersionNumber -ge $minimumVersionNumber)
	{
		$ipAddresses = Get-FormattedIPv4Address
		$summary += "IP Address : $ipAddresses"
	}

	$color = Get-ShellColor
	$memoryUseRatio = Get-MemoryUseRatio
	$context = Get-UserContext
	$summary += "Memory Use : $memoryUseRatio GB"
	$summary += "Context    : $context`n"
	$formattedSummary = $summary -join "`n"
	Write-Host "`n$formattedSummary" -ForegroundColor $color
}

function Get-SerialNumber
{
	$serialNumber = Get-CimInstance -ClassName Win32_BIOS | ForEach-Object {$_.serialNumber}
	
	return $serialNumber
}