#RI-Services

function Test-ServiceExists
{
	param(
		[Parameter(Mandatory = $true, Position = 1)][string]$Service)
	
	$serviceExists = Get-Service | Where-Object {$_.Name -eq $Service}
	
	return [bool]$serviceExists
}