#RI-Backup

<#
.SYNOPSIS
Performs a backup of a virtual machine.

.DESCRIPTION
Performs a backup of a Hyper-V virtual machine to a given path using the Windows Server Backup engine.

.PARAMETER VMName
Name of the virtual machine.

.PARAMETER Path
Path to backup to. Please review notes for expected behaviors.

.EXAMPLE
Backup-VM GL-FS-002 F:\

.NOTES
If the backup path is to attached storage, the backup will be performed incrementally.
If the backup path is to an SMB share, any existing backup will be erased and replaced.
#>
function Backup-VM
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$VMName,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)
		
	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$argument1 = "wbadmin start backup -backuptarget:" + $Path
		$argument2 = " -hyperv:`"Host Component`"," + $VMName
		$argument3 = " -quiet"
		$command = $argument1 + $argument2 + $argument3 
		cmd /c $command
	}
}

<#
.SYNOPSIS
Performs a backup of a virtual machine to a VHDX file.

.DESCRIPTION
Performs a Hyper-V level backup of a virtual machine to a previously created VHDX file.

.PARAMETER VMName
Name of the virtual machine.

.PARAMETER Path
Path to the folder the VHDX is in.

.EXAMPLE
Backup-VMIncrementally GL-APP-001 d:\backups\VHDX

.NOTES
The VHDX must be formatted before the first incremental backup can be made.
#>
function Backup-VMIncrementally
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$VMName,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)

	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$vmExists = $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue

		if ($vmExists)
		{
			$vhdxFile = New-VMIncrementalBackupVHDName -VM $vm
			$vhdxPath = Join-Path -ChildPath $vhdxFile -Path $Path
			$vhdxExists = Test-Path -Path $vhdxPath

			if ($vhdxExists)
			{
				$mountedVHDX = Mount-VHD -Path $vhdxPath -NoDriveLetter -Passthru
				$mountedVHDXPath = $mountedVHDX.path
				$volume = Get-Disk $mountedVHDX.DiskNumber | Get-Partition | Get-Volume
				$volumeExists = $volumePath = $volume.Path
				
				if ($volumeExists)
				{
					Backup-VM -VMName $VMName -Path $volumePath
				}
				else
				{
					Write-Host "`nVirtual hard drive is not formatted. Format the disk before proceeding.`n"
				}	

				Dismount-VHD -Path $mountedVHDXPath
			}
			else
			{
				Write-Host "`nCannot find target virtual hard drive for this backup."
				Write-Host 'Verify the path is correct or create a new virtual hard drive.'
				Write-Host "Expected path: $vhdxPath`n"
			}
		}
		else
		{
			Write-Host "`nCannot locate virtual machine $VMName on this host.`n"
		}
	}
}

<#
.SYNOPSIS
Installs the Windows Server Backup feature.

.DESCRIPTION
Installs the Windows Server Backup feature. If it is already installed, the command completes quietly.

.EXAMPLE
Install-WindowsServerBackup
#>
function Install-WindowsServerBackup
{
	$feature = 'Windows-Server-Backup'

	Install-WindowsFeature -Name $feature | Out-Null
}

function Export-BackupLog
{
	param(
		[Parameter(Position=1)][string]$ComputerName,
		[Parameter(Position=2)][string]$Path='./')

	if (!$ComputerName)
	{
		$ComputerName = Get-ComputerName
		$logFile = Join-Path -Path $Path -ChildPath "backup-$ComputerName.log"
		wbadmin get versions > $logFile
		$message = "Exported backup log to $logFile."
		New-RIPowerShellBackupEvent -Message $message -EntryType Information -EventId 2502
	}
	else
	{
		$message = "The -ComputerName parameter in Export-BackupLog is deprecated."

		Show-DeprecatedBehaviourWarning -Message $message
		$logFile = Join-Path -Path $Path -ChildPath "backup-$ComputerName.log"
		Invoke-Command -ComputerName $ComputerName {wbadmin get versions} > $logFile
	}
}

function Get-BackupVersions
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Path)
		
	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$command = "wbadmin get versions -backuptarget:" + $Path
		cmd /c $command
	}
}

<#
.SYNOPSIS
Returns backup versions contained in a VHDX.

.DESCRIPTION
Returns backup versions contained in a Hyper-V virtual machine backup set stored in a VHDX.

.PARAMETER Path
Path to the incremental backup VHDX.

.EXAMPLE
Get-VMIncrementalBackupVersions -Path GL-FS-003-BACKUP-8e01d151-45c1-4816-b0e6-acbde1671d86.vhdx
#>
function Get-VMIncrementalBackupVersions
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Path)
	

	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$mountedVHDX = Mount-VHD -Path $Path -NoDriveLetter -Passthru
		$mountedVHDXPath = $mountedVHDX.path
		$volume = Get-Disk $mountedVHDX.DiskNumber | Get-Partition | Get-Volume
		$volumeExists = $volumePath = $volume.Path
		
		if ($volumeExists)
		{
			Get-BackupVersions -Path $volumePath
		}
		else
		{
			Write-Host "`nVirtual hard drive $Path does not have any volumes.`n"
		}	

		Dismount-VHD -Path $mountedVHDXPath
	}
}

<#
.SYNOPSIS
Creates a new VHDX for virtual machine incremental backups.

.DESCRIPTION
Creates a new VHDX for Hyper-V virtual machine incremental backups. The file created includes the name and VMID of the virtual machine.

.PARAMETER VMName
Name of virtual machine.

.PARAMETER Path
Folder to place new VHDX file.

.PARAMETER SizeBytes
Maximum size of VHDX.

.EXAMPLE
New-VMIncrementalBackupVHD GL-HDC-001 H:\backups 200GB

.NOTES
This command does not work if the VHDX is located on a WinPE-hosted share.
#>
function New-VMIncrementalBackupVHD
{
    [CmdletBinding()]

	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$VMName,
		[Parameter(Mandatory=$true,Position=2)][string]$Path,
		[Parameter(Mandatory=$true,Position=3)][UInt64]$SizeBytes)

	$vmExists = $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue

	if ($vmExists)
	{
		$vhdxFile = New-VMIncrementalBackupVHDName -VM $vm
		$vhdxPath = Join-Path -ChildPath $vhdxFile -Path $Path
		$vhdxExists = Test-Path -Path $vhdxPath

		if (!$vhdxExists)
		{
			$label = 'BACKUP'
			New-FormattedVHD -Path $vhdxPath -SizeBytes $SizeBytes -Label $label
		}
		else
		{
			Write-Host "`nVirtual drive $vhdxFile already exists in $Path.`n"
		}
	}
	else
	{
		Write-Host "`nCannot locate virtual machine $VMName on this host.`n"
	}
}

function New-VMIncrementalBackupVHDName
{
	param(
	    [Parameter(Mandatory=$true)][Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
	
	$extension = '.vhdx'
	$delimiter = '-BACKUP-'

	$vmName = $VM.Name
	$vmID = $VM.VMId
	$vhdxFile = $vmName + $delimiter + $vmID + $extension

	return $vhdxFile
}

<#
.SYNOPSIS
Restores from backup of a virtual machine.

.DESCRIPTION
Restores a Hyper-V virtual machine from an incremental backup in a VHDX.

.PARAMETER VMName
Name of the virtual machine to restore.

.PARAMETER Path
Path to a VHDX containing the incremental backup.

.PARAMETER Version
A Windows Server Backup version name to restore from.

.PARAMETER RestorePath
Alternate path to restore the virtual machine to, required if not restoring to the original host.

.EXAMPLE
Restore-VMIncrementalBackup -VMName GL-FS-001 -Path H:\backup\GL-FS-001-BACKUP-8b56dc7e-dccf-498b-96c6-e564ed2e8186.vhdx -Version '10/15/2017-07:01'
#>
function Restore-VMIncrementalBackup
{
	param(
		[Parameter(Mandatory=$true)][string]$VMName,
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][string]$Version,
		[Parameter(Mandatory=$false)][string]$RestorePath)

	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$mountedVHDX = Mount-VHD -Path $Path -NoDriveLetter -Passthru
		$volume = Get-Disk $mountedVHDX.DiskNumber | Get-Partition | Get-Volume
		$volumeExists = $volumePath = $volume.Path

		if ($volumeExists)
		{
			if ($RestorePath)
			{
				mkdir -Path $RestorePath -ErrorAction SilentlyContinue
				Restore-VMBackup -VMName $VMName -Path $volumePath -Version $Version -RestorePath $RestorePath
			}
			else
			{
				Restore-VMBackup -VMName $VMName -Path $volumePath -Version $Version
			}
		}
		else
		{
			Write-Host "`nVirtual hard drive $Path does not have any volumes.`n"
		}

		Dismount-VHD -Path $Path
	}
}

function Restore-VMBackup
{
	param(
		[Parameter(Mandatory=$true)][string]$VMName,
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][string]$Version,
		[Parameter(Mandatory=$false)][string]$RestorePath)
		
	if (Test-ShellElevation)
	{
		Install-WindowsServerBackup
		$argument1 = "wbadmin start recovery -backuptarget:$Path"
		$argument2 = ' -itemtype:hyperV'
		$argument3 = " -items:$VMName"
		$argument4 = " -version:$Version"
		$argument5 = ' -quiet'
		$command = $argument1 + $argument2 + $argument3 + $argument4 + $argument5

		if ($RestorePath)
		{
			$argument6 = " -alternateLocation -recoverytarget:$RestorePath"
			$command += $argument6
		}

		cmd /c $command
	}
}

<#
.SYNOPSIS
Schedules an incremental VM backup.

.DESCRIPTION
Creates a daily scheduled task to backup a virtual machine incrementally. If a scheduled task for the virtual machine already exists, it will be overwritten.

.PARAMETER VMName
Name of the virtual machine to backup.

.PARAMETER Path
Path to the folder containing an incremental virtual machine backup VHDX file.

.PARAMETER Hour
Hour to start backup. Must be a value between 0 and 23.

.PARAMETER Minute
Minute to start backup. Must be a value between 0 and 59.

.EXAMPLE
New-VMIncrementalBackupTask -VMName GL-FS-003 -Path F:\backup -Hour 2 -Minute 0
#>
function New-VMIncrementalBackupTask
{
	param(
		[Parameter(Mandatory=$true)][string]$VMName,
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][int]$Hour,
		[Parameter(Mandatory=$true)][int]$Minute)

	if (($Hour -ge 0)-and ($Hour -le 23) -and ($Minute -ge 0) -and ($Minute -le 59))
	{
		if (Test-ShellElevation)
		{
			$taskName = "Backup Virtual Machine - $VMName"
			$description = 'Performs a virtual machine incremental backup.'
			$action = New-ScheduledTaskAction `
				-Execute 'powershell.exe' `
				-Argument "-Command Backup-VMIncrementally -VMName $VMName -Path $Path"
			$user = 'nt authority\system'
			$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

			if ($existingTask)
			{
				$existingTask | Unregister-ScheduledTask -Confirm:$false 
			}

			$time = Get-Date -Hour $Hour -Minute $Minute -Second 0
			$trigger = New-ScheduledTaskTrigger -Daily -At $time
			Register-ScheduledTask `
				-Action $action `
				-Trigger $trigger `
				-TaskName $taskName `
				-Description $description `
				-User $user `
				-RunLevel Highest | `
				Out-Null
		}
	}
	else
	{
		Write-Warning -Message 'Invalid time specified.'
	}
}

<#
.SYNOPSIS
Temporarily sets backup disks offline.

.DESCRIPTION
Temporarily sets backup disks offline.

.PARAMETER DelaySeconds
Time to leave the disks offline. If no time is specified, 600 seconds is used.

.EXAMPLE
Set-BackupDiskOfflineTemporarily -DelaySeconds 120
#>
function Set-BackupDiskOfflineTemporarily
 {
	param(
		[int]$DelaySeconds=600)
	
	$diskList = Get-WindowsServerBackupDisks

	foreach ($disk in $diskList)
	{
		$diskNumber = $disk.Number
		$disk | Set-Disk -IsOffline $true
		$message = "Backup disk $diskNumber has been set offline."
		New-RIPowerShellBackupEvent -Message $message -EntryType Information -EventId 2500
	}

	Start-Sleep -Seconds $DelaySeconds

	foreach ($disk in $diskList)
	{
		$diskNumber = $disk.Number
		$disk | Set-Disk -IsOffline $false
		$message = "Backup disk $diskNumber has been set online."
		New-RIPowerShellBackupEvent -Message $message -EntryType Information -EventId 2501
	}
}

function Get-WindowsServerBackupDisks
{
	$backupLabel = '.*\d{4}_\d{2}_\d{2}\s\d{2}\:\d{2}.*'

	$volumeList = Get-Volume | Where-Object {$_.FileSystemLabel -match $backupLabel}
	$diskList = @()

	foreach ($volume in $volumeList)
	{
		$disk = $volume | Get-Partition | Get-Disk
		$diskList += $disk
	}

	return $diskList
}