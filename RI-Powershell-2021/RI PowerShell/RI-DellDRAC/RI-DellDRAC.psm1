#RI-DellDRAC

function Get-DracIPv4Address
{
	if(Test-OMSAInstall)
	{
		$dracConfig = omreport chassis remoteaccess config=nic
		$ipv4Address = $dracConfig -match "IP Address\s*:\s*\d*"
		$ipv4Address = $ipv4Address -replace "IP Address\s*:\s*",""
		
		return $ipv4Address
	}
}

function Set-DracIPv4Address
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$IPv4Address,
		[Parameter(Mandatory=$true,Position=2)][string]$SubnetMask,
		[Parameter(Mandatory=$true,Position=3)][string]$Gateway)
			
	$remoteSession = Test-RemoteSession
	
	if ($remoteSession)
	{
		Write-Host "`nThe requested operation cannot be run in a remote PowerShell session.`n"
	}
	else
	{
		if (Test-ShellElevation)
		{
			if(Test-OMSAInstall)
			{
				omconfig chassis remoteaccess `
					config=nic `
					ipsource=static `
					ipaddress=$IPv4Address `
					subnet=$SubnetMask `
					gateway=$Gateway
			}
		}
	}
}

function Set-DracIPv4AddressToDhcp
{
	if (Test-ShellElevation)
	{
		if(Test-OMSAInstall)
		{
			omconfig chassis remoteaccess `
				config=nic `
				ipsource=dhcp
		}
	}
}

function Set-DRACRootPassword
{
	Param(
		[Parameter(Mandatory=$true,Position=1)][string]$Password)
	
	if (Test-ShellElevation)
	{
		if(Test-OMSAInstall)
		{
			$rootID = '2' #Dell default for root
			
			omconfig chassis remoteaccess `
				config=user `
				id=$rootID `
				newpw=$Password `
				confirmnewpw=$Password
		}
	}
}