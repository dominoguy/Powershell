#RI-DellPERC

function Get-DellPERCComponentIDs ($info)
{
	$info = $info -match "^ID\s*:\s*\d*$"
	$info = $info -replace "ID\s*:\s*",""
	
	return $info
}

function Get-DellPERCControllers
{
	$controllerInfo = omreport storage controller
	$controllers = Get-DellPERCComponentIDs $controllerInfo
	
	return $controllers
}
	
function Get-DellPERCVolumes ($controller)
{
	$volumesInfo = omreport storage vdisk controller=$controller
	$volumes = Get-DellPERCComponentIDs $volumesInfo
	
	return $volumes
}

function Get-DellPERCPhysicalDriveSummary
{
	if(Test-OMSAInstall -HideMessage)
	{
		$controllerList = Get-DellPERCControllers
		
		foreach ($controller in $controllerList)
		{
			$driveReport = omreport storage pdisk controller=$controller
			$criticalErrors = $driveReport -match ': Critical'
			$nonCriticalErrors = $driveReport -match ': Non-Critical'

			if ($criticalErrors)
			{
				$count = $criticalErrors.Count
				Write-CriticalSummary "$count drive(s) on PERC controller $controller are in a critical state."
			}

			if ($nonCriticalErrors)
			{
				$count = $nonCriticalErrors.Count
				Write-CriticalSummary "$count drive(s) on PERC controller $controller are in a non-critical state."
			}

			if (!$criticalErrors -and !$nonCriticalErrors)
			{
				Write-OptimalSummary "Drives on PERC controller $controller are healthy. "
			}
		}
	}
}

function Set-DellPERCCheckRate ($controller, $checkRate)
{
	if (Test-ShellElevation)
	{
		omconfig storage controller action=setchangecontrollerproperties controller=$controller checkconsistencyrate=$checkRate | Out-Null
	}
}

function Test-IfDellPERCVolumeResynching ($controller, $volume)
{
	$resynching = 'State\s*:\s*Resynching'
	
	$volumeInfo = omreport storage vdisk controller=$controller vdisk=$volume
	
	if ($volumeInfo -match $resynching)
	{
		return $true
	}
	
	return $false
}

function Start-DellPERCVolumeConsistencyCheck
{
	Param(
		[Parameter(Mandatory=$true)][string]$Rate)
	
	if (Test-ShellElevation)
	{
		if(Test-IsDellServer)
		{
			$controllerList = Get-DellPERCControllers

			foreach ($controller in $controllerList)
			{
				Set-DellPERCCheckRate $controller $Rate
				$volumeList = Get-DellPERCVolumes $controller
				
				foreach ($volume in $volumeList)
				{
					$pollRateSeconds = 10
					
					omconfig storage vdisk action=checkconsistency controller=$controller vdisk=$volume
					Write-Host "Checking controller $controller volume $volume"
					
					do
					{
						Start-Sleep -Seconds $pollRateSeconds
					}
					while (Test-IfDellPERCVolumeResynching $controller $volume)
				}
			}
		}
	}
}