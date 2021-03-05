#RI-NetworkAdapter

function ConvertTo-ShortMacAddress
{
	Param(
	    [Parameter(Mandatory=$true,Position=1)][string]$MacAddress)
		
	$shortMAC = $MacAddress -replace ':',''
	$shortMAC = $shortMAC -replace '-',''
	$shortMAC = $shortMAC -replace ' ',''
	
	return $shortMAC
}

function Set-NetConnectionProfileToPrivate
{
	$profileList = Get-NetConnectionProfile

	foreach ($profile in $profileList)
	{
		$profile.NetworkCategory = 'Private'
		Set-NetConnectionProfile -InputObject $profile
	}
}

<#
.SYNOPSIS 
Wakes a system at the specified MAC Address.

.DESCRIPTION
Sends a Wake-On-LAN (WOL) packet to a specified MAC address, waking the connected device.

.PARAMETER MacAddress
The MAC address of the device to wake.

.EXAMPLE
Send-WakeOnLAN -MacAddress AA:BB:CC:DD:EE:FF
#>
function Send-WakeOnLAN
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory = $True,Position = 1)][string]$MacAddress)
	
	$broadcastIPv4Address = '255.255.255.255'
	$port = 9
	
	$broadcast = [Net.IPAddress]::Parse($broadcastIPv4Address)
	$MacAddress = ConvertTo-ShortMacAddress -MacAddress $MacAddress
	$target = 0,2,4,6,8,10 | % {[convert]::ToByte($MacAddress.substring($_,2),16)}
	$packet = (,[byte]255 * 6) + ($target * 16)
	$udpClient = new-Object System.Net.Sockets.UdpClient
	$udpClient.Connect($broadcast,$port)
	$udpClient.Send($packet,102) | Out-Null
}

function Import-WakeOnLanMapping
{
	$mappings = Import-Mapping -Module 'RI-NetworkAdapter' -File 'computertomac-map.csv' 

	return $mappings
}

<#
.SYNOPSIS 
Wakes a computer.

.DESCRIPTION
Sends a Wake-On-LAN (WOL) packet to a specified computer, using a mapped list.

.PARAMETER ComputerName
Name of the computer to wake.

.EXAMPLE
Send-WakeOnLANToComputer GL-DT-021
#>
function Send-WakeOnLANToComputer
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory = $True,Position = 1)][string]$ComputerName)
	
	$mappingList = Import-WakeOnLanMapping
	$mapping = $mappingList | Where-Object {$_.computerName -eq $ComputerName}

	if ($mapping)
	{
		$macAddress = $mapping[0].macAddress
		Send-WakeOnLAN -MacAddress $macAddress
	}
	else
	{
		Write-Host "No MAC Address for $ComputerName was found."	
	}
}