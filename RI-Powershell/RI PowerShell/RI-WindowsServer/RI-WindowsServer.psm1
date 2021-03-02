#RI-WindowsServer

function Set-ServerUIMode
{
	param(
		[Parameter(Mandatory=$true,Position=1)][ValidateSet('Core','Full','Minimal')][string]$Mode,
		[switch]$Restart)
	
	if (Test-ShellElevation)
	{
		$shellRole =  'Server-Gui-Shell'
		$minimalRole = 'Server-Gui-Mgmt-Infra'
		
		if ($Mode -eq 'Core')
		{
			Uninstall-WindowsFeature -Name $shellRole | Out-Null
			Uninstall-WindowsFeature -Name $minimalRole | Out-Null
		}
		
		if ($Mode -eq 'Full')
		{
			Install-WindowsFeature -Name $shellRole | Out-Null
			Install-WindowsFeature -Name $minimalRole | Out-Null
		}

		if ($Mode -eq 'Minimal')
		{
			Install-WindowsFeature -Name $minimalRole | Out-Null
			Uninstall-WindowsFeature -Name $shellRole | Out-Null
		}
		
		if ($Restart)
		{
			Restart-ComputerWithDelay
		}
	}
}