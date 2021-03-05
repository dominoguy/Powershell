#RI-Print

function Clear-PrtprocsFolders
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][int]$Threshold)

	if (Test-ShellElevation)
	{
		$delaySeconds = 2
		$prtprocsPath = 'C:\Windows\system32\spool\prtprocs\x64'

		$directories = Get-ChildItem $prtprocsPath -Directory
		$directoryMeasure = $directories | Measure-Object
		$directoryCount = $directoryMeasure.count

		if ($directoryCount -ge $Threshold)
		{
			Stop-Service spooler
			Start-Sleep -Seconds $delaySeconds
			Remove-Item $directories -Recurse -Force
			Start-Service spooler
		}
	}
}

function Disable-PrinterPortSNMP
{
	if (Test-ShellElevation)
	{
		$portList = Get-CimInstance -ClassName Win32_TCPIPPrinterPort -Filter 'SNMPEnabled = True'

		foreach ($port in $portList)
		{
		    $port.SNMPEnabled = $false
		    $port.Put() | Out-Null
		}
	}
}

function Get-PrintSpoolerMemoryHealth
{
	$maximumMemory = 2GB
	
	$process = Get-Process -ProcessName spoolsv
	$commitMemory = $process.pagedMemorySize64
	$workingMemory = $process.workingSet64
	
	if ($commitMemory -gt $maximumMemory)
	{
		return $false
	}
	if ($workingMemory -gt $maximumMemory)
	{
		return $false
	}
	
	return $true
}

<#
.SYNOPSIS
Removes print jobs older than a specified number of days.

.DESCRIPTION
Removes print jobs older than a specified number of days.

.PARAMETER AgeDays
Number of days.

.EXAMPLE
Remove-OldPrintJobs -AgeDays 5
#>
function Remove-OldPrintJobs
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$AgeDays)
		
	if (Test-ShellElevation)
	{
		$limit = (Get-Date).AddDays(-$AgeDays)
		Get-Printer | Get-PrintJob | Where-Object {$_.SubmittedTime -lt $limit} | Remove-PrintJob
	}
}

function Restart-PrintSpooler
{
	if (Test-ShellElevation)
	{
		$delaySeconds = 1;
		$jobFiles = 'C:\Windows\system32\spool\printers\*.*'
		$processName = 'PrintIsolationHost'
		$service = 'spooler'
		$attempts = 0
		$maxAttempts = 30;
		
		Stop-Service -Name $service
		Get-Process -ProcessName $processName -ErrorAction SilentlyContinue | Stop-Process -Force
		
		do
		{
			$attempts++
			Remove-Item $jobFiles -Force -ErrorAction SilentlyContinue
			Start-Sleep -Seconds $delaySeconds
		}
		while ((Get-ChildItem -Path $jobFiles) -and ($attempts -lt $maxAttempts))
		
		Start-Service -Name spooler
	}
}

function Set-PrintProcessorsToWinprint
{
	if (Test-ShellElevation)
	{
		$printProcessor = 'winprint'
		
		$printersToModify = Get-Printer | Where-Object {$_.printProcessor -ne $printProcessor}
		$printersToModify | Set-Printer -PrintProcessor $printProcessor
	}
}

function Set-PrintQueuesToServerSideRendering
{
	 Get-Printer | Set-Printer -RenderingMode SSR
}

function Test-PrintSpoolerHealth
{
	Param(
	    [switch]$Restart)
	
	if (Test-ShellElevation)
	{
		$memoryHealthy = Get-PrintSpoolerMemoryHealth
			
		if (!$memoryHealthy)
		{
			if ($Restart)
			{
				Restart-PrintSpooler
			}
			
			return $false
		}
		else
		{
			return $true
		}
	}
}