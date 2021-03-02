#RI-Environment

function Get-DeployPath
{
	return $env:DEPLOYPATH
}

function Get-DevelopmentPath
{
	return $env:DEVELOPMENTPATH
}

function Get-ProgrammingPath
{
	return $env:PROGRAMMINGPATH
}

function Get-ComputerName
{
	return $env:computerName
}

function Get-ManagementDomain
{
	$managementDomain = 'ri.ads'

	return $managementDomain
}

function Test-DevelopmentEnvironment
{
	param (
		[switch]$HideMessage)
	
	if ((Get-DevelopmentPath) -and (Get-ProgrammingPath))
	{
		return $true
	}
	else
	{
		if (!$HideMessage)
		{
			Write-Warning -Message 'This operation cannot be performed outside a development environment.'
		}
		
		return $false
	}
}