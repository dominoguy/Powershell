#RI-DellChassis

function Test-IsDellServer
{
	param (
		[switch]$HideMessage)
	
	$computerSystem = Get-CimInstance CIM_ComputerSystem
	
	if (($computerSystem.Model -like "PowerEdge*") -or ($computerSystem.Model -like "PowerVault*"))
	{
		return $true
	}
	else
	{
		if (!$HideMessage)
		{
			Write-Host "`nThe requested operation requires a Dell server.`n"
		}
		
		return $false
	}
}

function Get-DellLCDText
{
	$frontPanel = omreport chassis frontpanel
	$lcdText = $frontPanel -match "LCD Line 1\s*:\s*.*"
	$lcdText = $lcdText -replace "LCD Line 1\s*:\s*",""
	
	return $lcdText
}

function Set-DellLCDText
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Message)
		
	$currentText = Get-DellLCDText
	
	if ($currentText -ne $Message)
	{
		omconfig chassis frontpanel lcdindex=1 config=custom text=$Message
	}
}

function Get-HvmIPv4Address
{
	$hvmAdapter = Get-NetIPAddress -InterfaceAlias "*HVM*" -AddressFamily IPv4
	$ipv4Address = $hvmAdapter.IPAddress
	
	return $ipv4Address
}

function Update-DellLCDText
{
	if (Test-ShellElevation)
	{
		if (Test-IsDellServer)
		{
			$computerName = $env:COMPUTERNAME
			$computerIP = Get-HvmIPv4Address
			$dracIP = Get-DRACIPv4Address
			$message = "$computerName $computerIP DRAC $dracIP"
			Set-DellLCDText -Message $message
		}
	}
}