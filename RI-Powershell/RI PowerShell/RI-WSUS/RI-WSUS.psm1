#RI-WSUS

function Optimize-WsusContent
{
	if (Test-ShellElevation)
	{
		Restart-WsusWebAppPool
		Invoke-WsusServerCleanup -CleanupObsoleteComputers
		Invoke-WsusServerCleanup -CleanupUnneededContentFiles
		Invoke-WsusServerCleanup -DeclineSupersededUpdates
		Invoke-WsusServerCleanup -DeclineExpiredUpdates

		$eventMessage = 'Optimized WSUS content.'
		New-RIPowerShellWsusEvent -Message $eventMessage -EntryType Information -EventId 1601
	}
}

function Optimize-WsusDatabase
{
	if (Test-ShellElevation)
	{
		$sqlcmdExists = Test-SQLCommandLineTool -Version 11

		if ($sqlcmdExists)
		{
			Start-SQLScript -ChildPath 'Modules\RI-WSUS\WsusDBMaintenance.sql'

			$eventMessage = 'Optimized WSUS database.'
			New-RIPowerShellWsusEvent -Message $eventMessage -EntryType Information -EventId 1602
		}
		else
		{
			Write-Host 'The requested operation requires the Microsoft Command Line Utilities for SQL Server.'
		}
	}
}

<#
.SYNOPSIS 
Runs a complete optimization of a WSUS server.

.DESCRIPTION
Runs a complete optimization of a WSUS server, removing history, unneeded and hidden updates, unneeded content files, and indexing the database.
#>
function Optimize-WsusServer
{
	Remove-WsusSyncHistory
	Remove-WsusUnneededUpdates
	Remove-WsusHiddenUpdates
	Optimize-WsusContent
	Optimize-WsusDatabase
}

function Remove-WsusSyncHistory
{
	if (Test-ShellElevation)
	{
		$sqlcmdExists = Test-SQLCommandLineTool -Version 11

		if ($sqlcmdExists)
		{
			$sqlcmdPath = Get-SQLCommandLineToolPath -Version 11

			$deleteQuery = "`"USE SUSDB; DELETE FROM tbEventInstance WHERE EventNamespaceID = '2' AND EVENTID IN ('381', '382', '384', '386', '387', '389');`""
			$argumentList = "-E -S np:\\.\pipe\MICROSOFT##WID\tsql\query -Q " + $deleteQuery

			Start-Process -FilePath $sqlcmdPath -ArgumentList $argumentList -NoNewWindow -Wait
		}
		else
		{
			Write-Host 'The requested operation requires the Microsoft Command Line Utilities for SQL Server.'
		}
	}
}

function Repair-WsusInstallation
{
	if (Test-ShellElevation)
	{
		Stop-WsusServices
		Start-SQLScript -ChildPath 'Modules\RI-WSUS\Repair-WsusInstallation.sql'
		Remove-WsusContentFolder
		Start-WsusServices
		Start-WsusPostInstall

		Write-Host "Use Start-WsusConsole to complete the WSUS setup process."
	}
}

function Repair-WsusUpgradeClassification
{
	if (Test-ShellElevation)
	{
		$hotFixId = 'KB3159706'
		$hotFixInstalled = Get-HotFix -Id $hotFixId -ErrorAction SilentlyContinue

		if ($hotFixInstalled)
		{
			$sqlcmdExists = Test-SQLCommandLineTool -Version 11

			if ($sqlcmdExists)
			{
				Start-WsusPostInstallServicing
				Install-HttpActivation45
				Add-WebEsdMime
				Restart-WsusService
				Disable-WsusUpgradeClassification
				Remove-WsusWindows10Upgrades
				Enable-WsusUpgradeClassification
				Start-WsusSynchronization
			}
			else
			{
				Write-Host 'The requested operation requires the Microsoft Command Line Utilities for SQL Server.'
			}
		}
		else
		{
			Write-Warning -Message "HotFix $hotFixId must be installed before running this command."
		}
	}
}

function Remove-WsusContentFolder
{
	Remove-Item -Path 'D:\WSUS' -Recurse -Force
}

function Start-WsusPostInstall
{
	Set-Location "C:\Program Files\Update Services\Tools"
	.\Wsusutil.exe postinstall CONTENT_DIR="D:\WSUS"
}

function Start-WsusServices
{
	$wsusServices = 'WSUSService','W3SVC'
	Start-Service -Name $wsusServices
}

function Stop-WsusServices
{
	$wsusServices = 'WSUSService','W3SVC'
	Stop-Service -Name $wsusServices
}

function Add-WebEsdMime
{
	Add-WebConfigurationProperty //staticContent `
		-Name collection `
		-Value @{fileExtension='.esd'; mimeType='application/octet-stream'}
}

function Start-WsusPostInstallServicing
{
	$wsusutilPath = 'C:\Program Files\Update Services\Tools\wsusutil.exe'
	$argumentList = 'postinstall /servicing'
	Start-Process -FilePath $wsusutilPath -ArgumentList $argumentList -NoNewWindow -Wait
}

function Restart-WsusService
{
	Restart-Service -Name WsusService
}

function Remove-WsusWindows10Upgrades
{
	[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
	$wsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
	$wsusServer.GetUpdates() | `
		Where-Object {$_.UpdateClassificationTitle -eq 'Upgrades' -and $_.ProductTitles -contains 'Windows 10'} | `
		ForEach-Object {$_.Decline(); Write-Host $_.Title declined}
	$wsusServer.GetUpdates() | `
		Where-Object {$_.UpdateClassificationTitle -eq 'Upgrades' -and $_.ProductTitles -contains 'Windows 10'} | `
		ForEach-Object {$wsusServer.DeleteUpdate($_.Id.UpdateId.ToString()); Write-Host $_.Title removed}

	Remove-WsusSqlTbFileTable
}

function Remove-WsusSqlTbFileTable
{
	Start-SQLScript -ChildPath 'Modules\RI-WSUS\Repair-WsusUpgradeClassification.sql'
}

function Get-WsusUpdateList
{
	[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
	$wsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
	$updates = @()
	$try = 0
	$tryMax = 3
	$successfulTry = $false

	do
	{
		try
		{
			$try++
			Write-Host "Getting Windows Updates (Try $try of $tryMax)"
			$updates = $wsusServer.GetUpdates()
			$successfulTry = $true
		}
		catch
		{
			if ($try -ge $tryMax)
			{
				Write-Host "Operation timed out while enumerating updates. Try running the command again."
			}
		}
	}
	while(($try -lt $tryMax) -and (!$successfulTry))

	return $updates
}

function Get-WsusHiddenUpdates
{
	$updateList = Get-WsusUpdateList
	$filteredUpdateList = $updateList | Where-Object {$_.IsDeclined -eq $true}

	return $filteredUpdateList
}

function Get-WsusUnneededUpdates
{
	$searchTermList = Get-WsusUnneededUpdateSearchTerms
	$updateList = Get-WsusUpdateList
	$filteredUpdateList = @()

	foreach ($searchTerm in $searchTermList)
	{
		$matchingUpdateList = $updateList | Where-Object {$_.Title -like "*$searchTerm*"}
		$filteredUpdateList += $matchingUpdateList
	}

	return $filteredUpdateList
}

<#
.SYNOPSIS 
Returns a list of unneeded update search terms.

.DESCRIPTION
Returns a list of unneeded update search terms.
#>
function Get-WsusUnneededUpdateSearchTerms
{
	$configFile = 'Modules\RI-WSUS\wsusunneededupdates.cfg'
	$resourcePath = Get-RIPowerShellResourcesPath -ChildPath $configFile
	$searchTermList = Get-Content -Path $resourcePath
	
	return $searchTermList
}

<#
.SYNOPSIS 
Declines unneeded Windows updates.

.DESCRIPTION
Declines unneeded Windows updates. For a list of search terms used to determine if an updates is unneeded, use Get-WsusUnneededUpdateSearchTerms.
#>
function Remove-WsusUnneededUpdates
{
	$updateList = Get-WsusUnneededUpdates
	$updateListCount = $updateList.Count

	for ($i = 0; $i -lt $updateListCount; $i++)
	{
		$update = $updateList[$i]
		$update.Decline()
		$updateTitle = $update.Title
		Write-Host "$updateTitle declined."	
	}

	$eventMessage = "$updateListCount WSUS declined updates removed."
	New-RIPowerShellWsusEvent -Message $eventMessage -EntryType Information -EventId 1603
}

function Remove-WsusHiddenUpdates
{
	if (Test-ShellElevation)
	{
		Restart-WsusWebAppPool
		$removalsBeforeRecycleMax = 25
		$removalsBeforeRecycle = $removalsBeforeRecycleMax

		[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
		$wsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
		$hiddenUpdateList = Get-WsusHiddenUpdates
		$hiddenUpdateCount = $hiddenUpdateList.Count

		$timer = New-StopWatch
		$removalRate = 0

		if ($hiddenUpdateCount -gt 0)
		{
			Write-Host "$hiddenUpdateCount hidden updates found."

			for ($i = 0; $i -lt $hiddenUpdateCount; $i++)
			{
				$removalsBeforeRecycle--

				if ($removalsBeforeRecycle -lt 0)
				{
					Restart-WsusWebAppPool
					$removalsBeforeRecycle = $removalsBeforeRecycleMax
				}

				$hiddenUpdate = $hiddenUpdateList[$i]
				$wsusServer.DeleteUpdate($hiddenUpdate.Id.UpdateId.ToString())
				$hiddenUpdateName = $hiddenUpdate.Title
				Write-Host "Removed: $hiddenUpdateName"

				$timeElapsed = $timer.Elapsed.TotalHours
				$removalRate = [int]($i/$timeElapsed)

				$activity = 'Remove-WsusHiddenUpdates'
				$activityNumber = $i + 1
				$status = "$activityNumber of $hiddenUpdateCount hidden updates removed at rate of $removalRate/hr"
				$percentComplete = ($i/$hiddenUpdateCount*100)
				Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
			}

			Write-Host "Removed $hiddenUpdateCount updates at a rate of $removalRate/hr."
		}
		else
		{
			Write-Host "No hidden updates found."
		}
	}
}

function Restart-WsusWebAppPool
{
	if (Test-ShellElevation)
	{
		Import-Module -Name WebAdministration
		$site = 'WSUS Administration'
		$pool = (Get-Item "IIS:\Sites\$site"| Select-Object applicationPool).applicationPool
		Restart-WebAppPool -Name $pool

		$eventMessage = 'Restarted WSUS App Pool.'
		New-RIPowerShellWsusEvent -Message $eventMessage -EntryType Information -EventId 1600
	}
}

function Start-WsusSynchronization
{
	$wsusServer = Get-WsusServer
	$subscription = $wsusServer.GetSubscription()
	$subscription.StartSynchronization()
}

function Disable-WsusUpgradeClassification
{
	Get-WsusClassification | `
		Where-Object -FilterScript {$_.Classification.Title -Eq 'Upgrades'} | `
		Set-WsusClassification -Disable
}

function Enable-WsusUpgradeClassification
{
	Get-WsusClassification | `
		Where-Object -FilterScript {$_.Classification.Title -Eq 'Upgrades'} | `
		Set-WsusClassification
}

function Start-WsusConsole
{
	$consolePath = "$env:programfiles\Update Services\AdministrationSnapin\wsus.msc"
	Start-Process -FilePath $consolePath
}