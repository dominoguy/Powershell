#RI-NetworkingIPv4

function Get-IPv4AddressFromString ($text)
{
	$ipv4Pattern = '\d*\.\d*.\d*\.\d*'
	
	$ipv4Address = $text -match $ipv4Pattern
	$ipv4Address = $matches[0]

    return $ipv4Address
}

function Get-ExternalIPv4Address
{
    $uri = 'https://api.ipify.org?format=json'
	
	$reply =  Invoke-RestMethod -Uri $uri
	$ipv4Address = $reply.ip

    return $ipv4Address
}

function Get-IPv4AddressOwner
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$IPv4Address)

	$pattern = "(?s)ISP.*City"
	
	$url = "https://www.abuseipdb.com/check/$IPv4Address"
	$text = Get-WebPageText -URL $url
	$text -match $pattern | Out-Null
	$info = $matches[0]
	$info = $info -replace "<.*>",''
	$info = $info -replace "\n\n\n\n\n",''
	$info = $info -replace "\n\n\n",''
	$info = $info -replace "ISP",''
	$info = $info -replace "City",''
	
	return $info
}

function Get-FormattedIPv4Address
{
	$interfaceList = Get-NetIPAddress | `
		Where-Object {($_.addressfamily -eq 'IPv4') -and ($_.InterfaceAlias -notlike "*loopback*")}

	$ipAddresses = $null

	foreach($interface in $interfaceList)
	{
		$ipAddresses += $interface.IPAddress
		$ipAddresses += ' '
	}

	$ipAddresses = $ipAddresses -replace " $",''
	$ipAddresses = $ipAddresses -replace ' ',', '

	return $ipAddresses
}

function Test-IPv4AddressPattern
{
	Param(
		[Parameter(Mandatory=$true)][string]$Address)
	
	$ipv4Pattern = '\d*\.\d*.\d*\.\d*$'
	$ipv4Address = $Address -match $ipv4Pattern

	if ($Matches)
	{
		return $true
	}
	else
	{
		return $false
	}
}

function Watch-Connection
{
	[CmdletBinding()]

	param (
		[Parameter(Mandatory=$true,Position=1)][string]$ComputerName,
		[string]$Owner)
		
	$barLimit = 50
	$barScalar = 20
	$criticalThreshold = 300
	$lineCount = 0
	$lineThreshold = 10
	$pollRateMilliseconds = 1000
	$warningThreshold = 150

	$ComputerName = Convert-NetbiosNameToFQDN -ComputerName $ComputerName -Owner $Owner
	
	do
	{
		$lineCount++
		
		if ($lineCount -eq $lineThreshold)
		{
			$lineColor = 'DarkGray'
			$lineCount = 0
		}
		else
		{
			$lineColor = 'White'
		}

		$time = Get-FormattedTime
		Write-Host "`n$time " -ForegroundColor $lineColor -NoNewline
		$connection = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue
		
		if ($connection)
		{
			$destination = $connection.ProtocolAddress
			[int]$roundtrip = $connection.ResponseTime
			$roundtripText = [string]$roundtrip
			$paddingLength = 4 - ($roundtripText.Length)

			if ($paddingLength -lt 0)
			{
				$paddingLength = 0
			}
			
			$padding = $(' ' * $paddingLength)
			
			if ($destination -ne '127.0.53.53')
			{
				$bar = Format-BarGraph -Number $roundtrip -Scalar $barScalar -Limit $barLimit
				$isIPv4Pattern = Test-IPv4AddressPattern -Address $ComputerName
				
				if ($isIPv4Pattern)
				{
					Write-Host "Reply from $destination`: " -ForegroundColor $lineColor -NoNewline
				}
				else
				{
					Write-Host "Reply from $destination `($ComputerName`)`: " -ForegroundColor $lineColor -NoNewline
				}
				
				switch ($roundtrip)
				{
					{$_ -ge $criticalThreshold}
						{
							Write-Host "$padding$roundtrip ms $bar" -ForegroundColor Red -NoNewline
							break
						}
					{$_ -ge $warningThreshold}
						{
							Write-Host "$padding$roundtrip ms $bar" -ForegroundColor Yellow -NoNewline
							break
						}
					default
						{
							Write-Host "$padding$roundtrip ms $bar" -ForegroundColor Green -NoNewline
						}
				}
			}
			else
			{
				Write-Host "$ComputerName resolved to 127.0.53.53. Flush the DNS cache." -ForegroundColor Red -NoNewline
			}
		}
		else
		{
			Write-Host "Request to $ComputerName timed out." -ForegroundColor Red -NoNewline
		}
		
		Start-Sleep -Milliseconds $pollRateMilliseconds
	}
	while ($pollRateMilliseconds)
}