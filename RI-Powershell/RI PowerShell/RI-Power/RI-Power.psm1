#RI-Power

function Get-BatteryChargeRemaining
{
	$chargeRemaining = (Get-CimInstance -ClassName win32_battery).EstimatedChargeRemaining

	return $chargeRemaining
}

function Get-BatteryRuntime
{
	$runtimeMinutes = (Get-CimInstance -ClassName win32_battery).EstimatedRunTime

	return $runtimeMinutes
}

<#
.SYNOPSIS
Restarts a computer after a specified delay.

.DESCRIPTION
Restarts a computer after a specified delay. If no delay is specified, a default of 60 seconds is used.

.PARAMETER DelaySeconds
Number of seconds to delay the restart. If this parameter is not specified, a default of 60 seconds is used.

.EXAMPLE
Restart-ComputerWithDelay -DelaySeconds 10
#>
function Restart-ComputerWithDelay
{
	param(
		[Parameter(Position = 1)][int]$DelaySeconds = 60)
				
	Start-CountdownMessage -Verb 'Restarting' -DelaySeconds $DelaySeconds
	Restart-Computer -Force
}

<#
.SYNOPSIS
Puts the computer to sleep.

.DESCRIPTION
Puts the computer to sleep. Zzzzzzzzz.

.PARAMETER DelaySeconds
Number of seconds to delay the suspend. If this parameter is not specified, the computer will be suspended immediately.

.EXAMPLE
Suspend-Computer 600
#>
function Suspend-Computer
{
	param(
		[Parameter(Position = 1)][int]$DelaySeconds = 0)
	
	Start-CountdownMessage -Verb 'Suspending' -DelaySeconds $DelaySeconds
	Add-Type -As System.Windows.Forms
	$suspend = [System.Windows.Forms.PowerState]::Suspend
	$force = $false
	$disableWake = $false
	[System.Windows.Forms.Application]::SetSuspendState($suspend, $force, $disableWake) | Out-Null
}

function Start-CountdownMessage
{
	param(
		[Parameter(Mandatory=$true)][int]$DelaySeconds,
		[Parameter(Mandatory=$true)][string]$Verb)
		
	for ($i = $DelaySeconds; $i -gt 0; $i--)
	{
		Write-Host "$Verb in $i seconds. Press Ctrl+C to cancel.    `r" `
			-ForegroundColor Yellow `
			-NoNewline
		Start-Sleep -Seconds 1
	}	
}