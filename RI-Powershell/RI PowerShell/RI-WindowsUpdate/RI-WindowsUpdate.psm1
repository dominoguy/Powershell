#RI-WindowsUpdate

function New-WindowsUpdatesSession
{
	$session = New-Object -ComObject Microsoft.Update.Session

	return $session
}

function Start-WindowsUpdatesDownload ($Session, $UpdateList)
{
	Write-Host 'Downloading... ' -NoNewline
	
	$count = $UpdateList.Updates.Count
	$updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
	
	for ($i = 0; $i -lt $count; $i++)
	{
		$update = $UpdateList.Updates.Item($i)
		$updatesToDownload.Add($update) | Out-Null
	}
	
	$downloader = $Session.CreateUpdateDownloader()
	$downloader.Updates = $updatesToDownload
	$downloader.Download() | Out-Null
}

function Get-WindowsUpdatesUpdateList ($Session)
{
	$searcher = $Session.CreateUpdateSearcher()
	$updateList = $searcher.Search("IsInstalled=0 and Type='Software'")
	
	return $updateList
}

function Start-WindowsUpdatesInstall ($Session, $UpdateList)
{
	Write-Host 'Installing... ' -NoNewline
	
	$updatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
	
	for ($i = 0; $i -lt $count; $i++)
	{
		$update = $UpdateList.Updates.Item($i)
		if ($update.IsDownloaded)
		{
			$updatesToInstall.Add($update) | Out-Null
		}
	}
		
	$installer = $Session.CreateUpdateInstaller()
	$installer.Updates = $updatesToInstall
	$installResult = $installer.Install()
	
	Write-Host "Done.`n`n" -NoNewline
	
	return $installResult
}

<#
.SYNOPSIS
Resets the Windows Update cache.

.DESCRIPTION
Purges the contents of the Windows Update cache and deletes files associated with Windows upgrades.

.EXAMPLE
Reset-WindowsUpdateCache
#>
function Reset-WindowsUpdateCache
{
	if (Test-ShellElevation)
	{
		$updateService = 'wuauserv'

		Stop-Service -Name $updateService
		Remove-Item "$env:windir\softwaredistribution" -Recurse -Force
		Get-ChildItem -Path "$env:SystemDrive\*~BT" -Directory -Force | Remove-Item -Recurse -Force
		Start-Service -Name $updateService
	}
}

function Get-WindowsUpdatesPending
{
	$session = New-WindowsUpdatesSession
	$updatesPending = Get-WindowsUpdatesUpdateList $session

	return $updatesPending
}

function Get-WindowsUpdateRemoteTask
{
	param(
		[Parameter(Mandatory = $true, Position = 1)][string[]]$ComputerName)

	$taskName = 'Install Windows Updates Remotely'
	$scriptBlock = { Get-ScheduledTask -TaskName $args[0] }
	Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $taskname | `
		Format-Table PSComputerName,TaskName,State
}

<#
.SYNOPSIS
Installs Windows updates.

.DESCRIPTION
Installs all pending Windows updates, optionally restarting the computer after completion. If 30 or more updates are pending, the -Force switch must be used to continue.

.PARAMETER Restart
Restart the computer after updates are installed if required.

.PARAMETER Force
Force the install of Windows updates, even if 30 or more updates are pending.

.EXAMPLE
Install-WindowsUpdates -Restart
#>
function Install-WindowsUpdates
{
	param(
		[switch]$Restart,
		[switch]$Force)
	
	if (Test-ShellElevation)
	{
		Write-Host "`nSearching for available updates... "
		
		$countThreshold = 30
		$session = New-WindowsUpdatesSession
		$updateList = Get-WindowsUpdatesUpdateList $session
		$count = $updateList.Updates.Count
		
		if ($count -gt 0)
		{
			if (($count -le $countThreshold) -or $Force)
			{
				Write-Host "$count updates found. " -NoNewline
					
				Start-WindowsUpdatesDownload $session $updateList
				$installResult = Start-WindowsUpdatesInstall $session $updateList
							
				if ($installResult.RebootRequired)
				{
					Write-Warning -Message "A restart is required to complete Windows Updates."
					
					if ($Restart)
					{
						$delaySeconds = 60
						
						Restart-ComputerWithDelay $delaySeconds
					}
				}
			}
			else
			{
				Write-Warning -Message "$count updates found. To process this many updates, re-run the command with the Force switch."
			}
		}
		else
		{
			Write-Host "No updates are available to install.`n`n" -NoNewline
		}
	}
}

<#
.SYNOPSIS
Installs Windows updates on a remote system.

.DESCRIPTION
Installs all pending Windows updates on one or more remote systems via a scheduled task. The system is restarted if required.

.PARAMETER ComputerName
Name of one more more computers to install updates on.

.EXAMPLE
Install-WindowsUpdatesRemotely GL-FS-001,GL-FS-002,GL-FS-003
#>
function Install-WindowsUpdatesRemotely
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string[]]$ComputerName)

	$scriptFile = 'Modules\RI-WindowsUpdate\New-WindowsUpdateScheduledTask.ps1'
	$scriptPath = Get-RIPowershellResourcesPath -ChildPath $scriptFile
	
	foreach ($computer in $ComputerName)
	{
		try
		{
			Invoke-Command -ComputerName $computer -FilePath $scriptPath -ErrorAction Stop
			$message = "Sent command to remotely install Windows Updates on $computer."
			New-RIPowerShellWindowsUpdateEvent -Message $message -EntryType Information -EventId 1301
		}	
		catch
		{
			$message = "Could not send command to remotely install Windows Updates on $computer."
			Write-Error -Message $message
			New-RIPowerShellWindowsUpdateEvent -Message $message -EntryType Error -EventId 1501
		}
	}
}

<#
.SYNOPSIS
Purges the Windows Update policy settings.

.DESCRIPTION
Purges the local machine's Windows Update policy settings.
#>
function Remove-WindowsUpdatePolicy
{
	if (Test-ShellElevation)
	{
		$eventMessage = 'Windows Update policy settings removed.'
		$service = 'wuauserv'
		$windowsUpdateKey = 'hklm:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

		Remove-Item -Path $windowsUpdateKey -Recurse -ErrorAction SilentlyContinue
		Restart-Service -Name $service
		New-RIPowerShellWindowsUpdateEvent `
			-Message $eventMessage `
			-EntryType Information `
			-EventId 1300
	}
}