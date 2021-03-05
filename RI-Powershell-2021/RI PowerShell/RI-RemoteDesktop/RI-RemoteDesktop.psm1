# RI-RemoteDesktop

function Start-RemoteDesktopConnection
{
	param(
	    [Parameter(Mandatory=$true)][string]$ComputerFQDN,
		[ValidateSet('Fullscreen','1080p','900p','')][string]$Resolution,
		[switch]$Admin)
	
	$arguments = ''
	
	switch ($Resolution)
		{
			'1080p'
			{
				$arguments = '/w:1920 /h:1080'
				break
			}
			'900p'
			{
				$arguments = '/w:1400 /h:900'
				break
			}
			'Fullscreen'
			{
				$arguments = '/f'
				break
			}
		}
	
	if ($Admin)
	{
		mstsc.exe /v:$ComputerFQDN /admin $arguments.Split(' ')
	}
	else
	{
		mstsc.exe /v:$ComputerFQDN $arguments.Split(' ')
	}
}

<#
.SYNOPSIS
Connects to one more computers via Remote Desktop Protocol.

.DESCRIPTION
Enter-RDSession starts a connection to one or more computers via Remote Desktop Protocol. Using Translation Mapping, it can automatically derive the FDQN of a system from just its hostname. You may also specify a resolution to use in the connection.

.PARAMETER ComputerName
One or more computers to connect to.

.PARAMETER Resolution
Sets the resolution of the RDP session.

.PARAMETER Admin
Connect using an admin session.

.PARAMETER Owner
Uses Translation Mapping to automatically determine the FQDN of the remote computer.

.EXAMPLE
Enter-RDSession GL-HVS-001 900p

.NOTES
This command supports Translation Mapping.
#>
function Enter-RDSession
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string[]]$ComputerName,
		[Parameter(Position=2)][ValidateSet('Fullscreen','1080p','900p')][string]$Resolution,
		[switch]$Admin,
		[string]$Owner)
			
	foreach ($computer in $ComputerName)
	{
		$translatedComputerName =  Convert-NetbiosNameToFQDN -ComputerName $computer -Owner $Owner
		Start-RemoteDesktopConnection `
			-ComputerFQDN $translatedComputerName `
			-Admin:$Admin `
			-Resolution $Resolution
	}
}

<#
.SYNOPSIS
Resets the Remote Desktop Connection cache.

.DESCRIPTION
Purges the contents of the Remote Desktop Connection cache.

.EXAMPLE
Reset-RemoteDesktopCache
#>
function Reset-RemoteDesktopCache
{
	$childPath = 'Microsoft\Terminal Server Client\Cache\*.*'
	
	$cachePath = Join-Path -Path $env:LOCALAPPDATA -ChildPath $childPath
	Remove-Item -Path $cachePath -Force
}