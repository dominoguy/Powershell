#RI-Virtualization

function Disable-VMQs
{
	$disabledWeight = 0
	
	Get-NetAdapterVmq | Disable-NetAdapterVmq
	$vmqEnabledAdapters = Get-VM | Get-VMNetworkAdapter | Where-Object {$_.VMQWeight -ne $disabledWeight}
	$vmqEnabledAdapters | Set-VMNetworkAdapter -VmqWeight $disabledWeight
}

function Disable-VMNestedVirtualization
{
	param (
		[string]$VMName)

	$vm = Get-VM -VMName $VMName
	$vm | Set-VMProcessor -ExposeVirtualizationExtensions $false
	$vm | Get-VMNetworkAdapter | Set-VMNetworkAdapter -MacAddressSpoofing Off
}

function Enable-VMNestedVirtualization
{
	param (
		[string]$VMName)
	
	$vm = Get-VM -VMName $VMName
	$vm | Set-VMProcessor -ExposeVirtualizationExtensions $true
	$vm | Get-VMNetworkAdapter | Set-VMNetworkAdapter -MacAddressSpoofing On
}

function Get-VMHardDiskDriveFragmentation
{
	param (
		[string[]]$VMName = '*')
	
	$vmHardDiskDrives = Get-VM -VMName $VMName | `
		Get-VMHardDiskDrive | Where-Object {$_.DiskNumber -eq $null} | `
		Get-VHD |  `
		Select-Object -Property Path,FragmentationPercentage | `
		Sort-Object -Property FragmentationPercentage -Descending

	return $vmHardDiskDrives
}

function Get-VMReplicaSummary
{
	$replication = Get-VMReplication	
	
	if ($replication)
	{
		$unhealthyReplicas = $replication | Where-Object {$_.Health -ne 'Normal'}
	
		if ($unhealthyReplicas)
		{
			$count = $unhealthyReplicas.count
			Write-CriticalSummary "$count virtual machine(s) report unhealthy replica status."
		}
		if (!$unhealthyReplicas)
		{
			Write-OptimalSummary 'Replication state healthy.'
		}
	}
}

function Get-VMMemorySummary
{
	$padding = '          '
	
	$vmList = Get-VM |Where-Object {$_.DynamicMemoryEnabled -eq $true}
	$low = $vmList | Where-Object {$_.MemoryStatus -eq 'Low'}
	$critical = $vmList | Where-Object {$_.MemoryStatus -eq 'Warning'}
	
	if ($low)
	{
		$count = $low.count
		Write-WarningSummary "$count virtual machine(s) report low memory."
		
		foreach ($vm in $low)
		{
			$name = $vm.Name
			Write-Host $padding$name
		}
	}
	
	if ($critical)
	{
		$count = $critical.count
		Write-CriticalSummary "$count virtual machine(s) are out of memory."
		
		foreach ($vm in $critical)
		{
			$name = $vm.Name
			Write-Host $padding$name 
		}
	}
	
	if (!$low -and !$critical)
	{
		Write-OptimalSummary 'Virtual machine memory state healthy.'
	}
}

function Get-VMCheckpointSummary
{
	$checkpoints = Get-VM | Get-VMSnapshot
	$standardCheckpoints = $checkpoints | `
		Where-Object {($_.SnapshotType -ne 'Recovery') -and ($_.Name -notlike "Rolling Checkpoint - *")}
	$rollingCheckpoints = $checkpoints | `
		Where-Object {$_.Name -like "Rolling Checkpoint*"}
		
	if ($standardCheckpoints)
	{
		$count = $standardCheckpoints.count
		Write-WarningSummary "$count standard checkpoint(s) are active on this host."
	}
	else
	{
		Write-OptimalSummary 'There are no standard checkpoints on this host.'
	}
	
	if ($rollingCheckpoints)
	{
		$count = $rollingCheckpoints.count
		Write-WarningSummary "$count Rolling Checkpoint(s) are active on this host."
	}
	else
	{
		Write-OptimalSummary 'There are no Rolling Checkpoints on this host.'
	}
}

function Get-PlacementFolder
{
	$placementDirectory = ':\virtual'
	$placementFolders =  @()
	
	$volumeList = Get-Volume | Sort-Object DriveLetter
			
	foreach ($volume in $volumeList)
	{
		$driveLetter = $volume.driveLetter
		$placementPath = $driveLetter + $placementDirectory
		
		if (Test-Path $placementPath)
		{
			$placementFolders += $placementPath
		}
	}
	
	return $placementFolders
}

function Get-PlacementVolume
{
	$placementDirectory = '\virtual'
	$placementVolumes =  @()
	
	$volumeList = Get-Volume | Sort-Object DriveLetter
			
	foreach ($volume in $volumeList)
	{
		$volumeLetter = $volume.driveLetter
		$placementPath = $volumeLetter + ':' + $placementDirectory
		
		if (Test-Path $placementPath)
		{
			$placementVolumes += $volume
		}
	}
	
	return $placementVolumes
}

function Get-PlacementVolumeSummary
{
	if (Test-ShellElevation)
	{
		$sizeWarning = 200GB
		$sizeCritical = 100GB
		
		$volumeList = Get-PlacementVolume
		
		foreach ($volume in $volumeList)
		{
			$volumeLetter = $volume.driveLetter
			$sizeRemaining = $volume.sizeRemaining
			$sizeRounded = ConvertTo-RoundedDownGB $sizeRemaining
			
			if ($sizeRemaining -lt $sizeCritical)
			{
				Write-CriticalSummary "Placement volume $volumeLetter has $sizeRounded GB of drive space remaining."
			}
			else
			{
				if ($sizeRemaining -lt $sizeWarning)
				{
					Write-WarningSummary "Placement volume $volumeLetter has $sizeRounded GB of drive space remaining."
				}
			}
		}
	}
}

function Get-SystemVolumeSummary
{
	$sizeWarning = 80GB
	$sizeCritical = 40GB
	
	$volume = Get-SystemVolume
	$driveLetter = $volume.driveLetter
	$size = $volume.sizeRemaining
	$sizeRounded = ConvertTo-RoundedDownGB $size
				
	switch ($size)
	{
		{$_ -lt $sizeCritical}
		{
			Write-CriticalSummary "System volume $driveLetter $sizeRounded GB of drive space remaining."
			break
		}
		
		{$_ -lt $sizeWarning}
		{
			Write-WarningSummary "System volume $driveLetter has $sizeRounded GB of drive space remaining."
			break
		}
	}
}

function Get-DifferencingDisksSummary
{
	$threshold = 1GB
	$pathList = Get-PlacementFolder
	
	foreach ($path in $pathList)
	{
		$size = Get-DifferencingDisksUsage -Path $path
		$sizeRounded = ConvertTo-RoundedDownGB $size
	
		if ($size -gt $threshold)
		{
			Write-InformationalSummary "Placement folder $path has $sizeRounded GB of differencing disks in use."
		}
	}
}

function Get-DifferencingDisksUsage
{
	param (
		[Parameter(Mandatory=$true)][string]$Path)

	$extension = 'avhd*'
	$size = Get-FileTypeSize -Extension $extension -Path $Path

	return $size
}

function Get-VMReplicationPendingSummary
{
	$sizeWarning = 1GB
	$sizeCritical = 10GB
	
	$pathList = Get-PlacementFolder
	
	foreach ($path in $pathList)
	{
		$size = Get-VMReplicationPendingUsage -Path $path
		$sizeRounded = ConvertTo-RoundedDownGB $size
	
		switch ($size)
		{
			{$_ -gt $sizeCritical}
			{
				Write-CriticalSummary "Placement folder $path has $sizeRounded GB of pending replication changes."
				break
			}
			
			{$_ -gt $sizeWarning}
			{
				Write-WarningSummary "Placement folder $path has $sizeRounded GB of pending replication changes."
				break
			}
		}
	}
}

function Get-VMReplicationPendingUsage
{
	param (
		[Parameter(Mandatory=$true)][string]$Path)

	$extension = 'hrl'
	$size = Get-FileTypeSize -Extension $extension -Path $Path
	
	return $size
}

function Get-VMSavedMemorySummary
{
	$threshold = 1GB
	$pathList = Get-PlacementFolder
	
	foreach ($path in $pathList)
	{
		$size = Get-VMSavedMemoryUsage -Path $path
		$sizeRounded = ConvertTo-RoundedDownGB $size
	
		if ($size -gt $threshold)
		{
			Write-InformationalSummary "Placement folder $path has $sizeRounded GB of saved memory in use."
		}
	}
}

function Get-VMSavedMemoryUsage
{
	param (
		[Parameter(Mandatory=$true)][string]$Path)

	$extension = 'bin'
	$size = Get-FileTypeSize -Extension $extension -Path $Path
	
	return $size
}

function Get-VMHostSummary
{
	param (
		[switch]$RemoteSessionDisabled)
		
	$remoteSession = Test-RemoteSession
	
	if ($remoteSession -and $RemoteSessionDisabled)
	{
		Write-Host "`nUse the Get-VMHostSummary cmdlet to view a health summary of this host.`n"
	}
	else
	{
		$computerName = Get-LocalComputerName
		Get-MemorySummary
		Get-DellPERCPhysicalDriveSummary
		Get-FixedVolumeSummary
		Get-SystemVolumeSummary
		Get-PlacementVolumeSummary
		Get-VMMemorySummary
		Get-VMReplicaSummary
		Get-VMReplicationPendingSummary
		Get-VMCheckpointSummary
		Get-DifferencingDisksSummary
		Get-VMSavedMemorySummary
		Write-Host "`n"
	}
}

function Get-VMStorageUsage
{
	param (
		[Parameter(Mandatory=$true,Position=1)][string[]]$VMName)
		
	$length = 0
	
	$vmList = Get-VM -VMName $VMName
	
	if ($vmList)
	{
		foreach ($vm in $vmList)
		{
			$attachedVHDList = $vm | Get-VM |Get-VMHardDiskDrive | Get-VHD
			
			foreach ($attachedVHD in $attachedVHDList)
			{
				$length += $attachedVHD.FileSize
				$parentpath = $attachedVHD.ParentPath
				
				while ($parentpath)
				{
					$parentVHD = Get-VHD -Path $parentpath
					$length += $parentVHD.FileSize
					$parentpath = $parentVHD.ParentPath
				}
			}
		}
		
		$lengthFormatted = Format-Length $length
		Write-Output $lengthFormatted 
	}
}

function Optimize-VMStorage
{
	param (
		[Parameter(Mandatory=$true,Position=1)][string[]]$VMName,
		[switch]$Defrag,
		[switch]$Force)
		
	if (Test-ShellElevation)
	{
		$vmList = Get-VM -VMName $VMName	
		$storageUsage = Get-VMStorageUsage -VMName $VMName
		Write-Host "Storage used before optimization: $storageUsage"
		
		for ($i = 0; $i -lt $vmList.Count; $i++)
		{
			$vm = $vmList[$i]
			$name = $vm.Name
			$activity = 'Optimize-VMStorage' 
			$status = "Optimizing storage for virtual machine $name"
			$percentComplete = ($i/$vmList.Count*100)
			Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
			$checkpointExists = Get-VMSnapshot -VM $vm
			
			if ($checkpointExists)
			{
				Write-Host "`n$name has checkpoints and will be skipped.`n" -ForegroundColor Yellow
			}
			else
			{
				$vmStatus = $vm.Status
				
				if ($vmStatus -eq 'Merging disks')
				{
					Write-Host "$name is merging disks and will be skipped." -ForegroundColor Yellow
				}
				else
				{
					$vmIsOffBeforeOptimize = Test-VMIsOff -VM $vm
					
					if ($vmIsOffBeforeOptimize)
					{
						Optimize-VMVolumes -VM $vm

						if ($Defrag)
						{
							Optimize-VMDrives -VM $vm -Defrag
						}
						else
						{
							Optimize-VMDrives -VM $vm
							Optimize-VMDrives -VM $vm #second pass
						}
					}
					else
					{
						if ($Force)
						{
							Write-Host "Stopping virtual machine $name." -ForegroundColor Yellow
							Stop-VM $vm
							Optimize-VMVolumes -VM $vm

							if ($Defrag)
							{
								Optimize-VMDrives -VM $vm -Defrag
							}
							else
							{
								Optimize-VMDrives -VM $vm
								Optimize-VMDrives -VM $vm #second pass
							}
							
							Write-Host "Starting virtual machine $name." -ForegroundColor Yellow
							Start-VM $vm
						}
						else
						{
							Write-Host "$name is running. Use the Force switch or shutdown the VM first." -ForegroundColor Yellow
						}
					}
				}	
			}	
		}
		
		$storageUsage = Get-VMStorageUsage -VMName $VMName
		Write-Host "Storage used after optimization: $storageUsage"
	}
}

function Optimize-VMVolumes
{
	param (
		[Parameter(Mandatory=$true)][Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
		
	$drives = Get-VMHardDiskDrive -VM $VM | Where-Object {$_.Path -notlike "Disk *"}
	$drives | Mount-VHD -Passthru | Get-Disk | Get-Partition | Get-Volume | `
		Optimize-Volume -SlabConsolidate -ReTrim -ErrorAction SilentlyContinue
	$drives | Dismount-VHD
}

function Optimize-VMDrives
{
	param (
		[Parameter(Mandatory=$true)][Microsoft.HyperV.PowerShell.VirtualMachine]$VM,
		[switch]$Defrag)
	
	$driveList = Get-VMHardDiskDrive -VM $VM | Where-Object {$_.Path -notlike "Disk *"}
	$driveList | Resize-VHD -ToMinimumSize -ErrorAction SilentlyContinue

	if ($Defrag)
	{
		foreach ($drive in $driveList)
		{
			$fragrmentationThreshold = 35
			$fragmentation = ($drive | Get-VHD).FragmentationPercentage

			if ($fragmentation -ge $fragrmentationThreshold)
			{
				$delimiter = '-'
				$oldSuffix = 'OLD-'
				$newSuffix = 'NEW-'

				$vmName = $VM.VMName
				$controllerType = $drive.controllerType
				$controllerNumber = $drive.controllerNumber
				$controllerLocation = $drive.controllerLocation
				$drivePath = $drive.path
				$driveFolder = Split-Path -Path $drivePath -Parent
				$driveFileName = Split-Path -Path $drivePath -Leaf
				$newDriveGUID = New-GUIDString
				$newDriveFileName = $newSuffix + $newDriveGUID + $delimiter + $driveFileName
				$newDrivePath = Join-Path -Path $driveFolder -ChildPath $newDriveFileName
				$isSwapDrive = $driveFileName -match '.*SWAP.vhdx'

				if ($isSwapDrive)
				{
					Convert-VHD -Path $drivePath -DestinationPath $newDrivePath -VHDType Fixed
				}
				else
				{
					Convert-VHD -Path $drivePath -DestinationPath $newDrivePath -VHDType Dynamic
				}

				Remove-VMHardDiskDrive `
					-VMName $vmName `
					-ControllerType $controllerType `
					-ControllerNumber $controllerNumber `
					-ControllerLocation $controllerLocation
				$oldDriveGUID = New-GUIDString
				$oldDriveFileName = $oldSuffix + $oldDriveGUID + $delimiter + $driveFileName
				Rename-Item -Path $drivePath -NewName $oldDriveFileName
				Rename-Item -Path $newDrivePath -NewName $driveFileName
				Add-VMHardDiskDrive `
					-VMName $vmName `
					-Path $drivePath `
					-ControllerType $controllerType `
					-ControllerNumber $controllerNumber `
					-ControllerLocation $controllerLocation
			}
		}
	}
	else
	{
		$driveList | Mount-VHD -NoDriveLetter -ReadOnly
		$driveList | Optimize-VHD -Mode Full
		$driveList | Dismount-VHD
	}
}

function Test-VMIsOff
{
	param (
		[Parameter(Mandatory=$true)][Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
		
	$state = $VM.State
	
	if ($state -eq 'Off')
	{
		return $true
	}
	else
	{
		return $false
	}
}

function Reset-VMHardDiskDrive
{
	param (
		[Parameter(Mandatory=$true)][string]$VMName,
		[Parameter(Mandatory=$true)][ValidateSet('SCSI','IDE')][string]$ControllerType,
		[Parameter(Mandatory=$true)][string]$ControllerNumber,
		[Parameter(Mandatory=$true)][string]$ControllerLocation)

	$addDelaySeconds = 8
	
	$vm = Get-VM -VMName $VMName
	$vmHardDiskDrive =  $vm | Get-VMHardDiskDrive `
		-ControllerType $ControllerType `
		-ControllerNumber $ControllerNumber `
		-ControllerLocation $ControllerLocation
	$path = $vmHardDiskDrive.Path
	$disk = $vmHardDiskDrive.DiskNumber
	$vmHardDiskDrive | Remove-VMHardDiskDrive
	Start-Sleep -Seconds $addDelaySeconds

	if ($disk)
	{
		$vm | Add-VMHardDiskDrive `
		-ControllerType $ControllerType `
		-ControllerNumber $ControllerNumber `
		-ControllerLocation $ControllerLocation `
		-DiskNumber $disk
	}
	else
	{
		$vm | Add-VMHardDiskDrive `
			-ControllerType $ControllerType `
			-ControllerNumber $ControllerNumber `
			-ControllerLocation $ControllerLocation `
			-Path $path
	}
}
	
function Restart-SCVMMAgent
{
	$service = Get-Service -Name 'SCVMMAgent'
	
	if ($service.Status -ne 'Running')
	{
		Restart-Service $service -Force
	}
}

function Remove-NonRollingVMCheckpoints
{
	param (
		[Parameter(Mandatory=$true)][string[]]$VMName)
		
	$checkpointPrefix = 'Rolling Checkpoint - '
	
	$vmList = Get-VM -VMName $VMName
	
	foreach ($vm in $vmList)
	{
		$checkpoints = $vm | Get-VMSnapshot | Where-Object {$_.Name -notlike "$checkpointPrefix*"}
		$checkpoints | Remove-VMSnapshot
	}
}

function New-RollingVMCheckpoint
{
	param (
		[Parameter(Mandatory=$true)][string[]]$VMName,
		[Parameter(Mandatory=$true)][int]$MaxCheckpoints)
		
	$checkpointPrefix = 'Rolling Checkpoint - '
	$vmList = Get-VM -VMName $VMName
	
	foreach ($vm in $vmList)
	{
		$checkpointGUID = New-GUIDString
		$checkpointName = $checkpointPrefix + $checkpointGUID
		$vm | Checkpoint-VM -SnapshotName $checkpointName
		$message = "Created new rolling checkpoint $checkpointGUID for virtual machine $VMName."
		New-RIPowerShellVirtualizationEvent -Message $message -EntryType Information -EventId 2200
		$checkpointList = $vm | Get-VMSnapshot | Where-Object {$_.Name -like "$checkpointPrefix*"}
		$checkpointCount = $checkpointList.Count

		while ($checkpointCount -gt $MaxCheckpoints)
		{
			$checkpointList[0] | Remove-VMSnapshot -ErrorAction SilentlyContinue
			$checkpointList = $vm | Get-VMSnapshot | Where-Object {$_.Name -like "$checkpointPrefix*"}
			$checkpointCount = $checkpointList.Count
			$retryDelaySeconds = 1
			Start-Sleep -Seconds $retryDelaySeconds
		}
	}
}

<#
.SYNOPSIS
Creates a new configuration file suitable for use with New-RollingVMCheckpointFromFile

.DESCRIPTION
Creates a new configuration CSV file suitable for use with New-RollingVMCheckpointFromFile.

.PARAMETER Path
Path to save the file.

.PARAMETER Edit
Launches Notepad with the newly created file.

.PARAMETER Force
Overwrites file if it already exists.

.EXAMPLE
New-RollingVMCheckpointFile -Path .\rollingcheckpoints.csv
#>
function New-RollingVMCheckpointFile
{
	[CmdletBinding()]

	param (
		[Parameter(Position=1)][string]$Path = 'C:\ProgramData\RI PowerShell\Settings\RI-Virtualization\rollingcheckpoints.csv',
		[switch]$Edit,
		[switch]$Force)

	$fileExists = Test-Path -Path $Path

	if (!$fileExists -or $Force)
	{
		$headers = 'vmName,maxCheckpoints,diskLocation'
		
		$folderPath = Split-Path -Path $Path -Parent
		New-Item -Path $folderPath -ItemType Directory -ErrorAction SilentlyContinue
		Set-Content -Path $Path -Value $headers

		if ($Edit)
		{
			notepad.exe $Path
		}
	}
	else
	{
		Write-Warning -Message 'File already exists. Use -Force to overwrite.'
	}
}

<#
.SYNOPSIS
Creates rolling checkpoints based on a CSV file.

.DESCRIPTION
Creates rolling checkpoints based on a CSV file.

The CSV file must contain the following columns:

- vmName, the name of the virtual machine
- maxCheckpoints, the maximum number of checkpoints to retain
- diskLocation, an optional SCSI disk location to be disconnected before the checkpoint operation

.PARAMETER Path
Path to the CSV file.

.EXAMPLE
New-RollingVMCheckpointFromFile -Path .\rollingcheckpoints.csv
#>
function New-RollingVMCheckpointFromFile
{
	param (
		[Parameter(Mandatory=$true)][string]$Path)
	
	$pathExists = Test-Path -Path $Path

	if ($pathExists)
	{
		$checkPointSettingsList = Import-Csv -Path $Path
		
		foreach ($checkPointSetting in $checkPointSettingsList)
		{
			$vmName = $checkPointSetting.vmName
			$vm = Get-VM -VMName $vmName
			$maxCheckpoints = $checkPointSetting.maxCheckpoints
			$diskLocation = $checkPointSetting.diskLocation
			$diskPath = ''

			if ($diskLocation)
			{
				$delaySeconds = 8

				$vmHardDiskDrive = $vm | Get-VMHardDiskDrive `
				-ControllerType SCSI `
				-ControllerNumber 0 `
				-ControllerLocation $diskLocation
				$diskPath = $vmHardDiskDrive.Path
				$vmHardDiskDrive | Remove-VMHardDiskDrive
				$message = "Disconnected drive on SCSI 0 $diskLocation from virtual machine $vmName."
				New-RIPowerShellVirtualizationEvent -Message $message -EntryType Information -EventId 2201
				Start-Sleep -Seconds $delaySeconds
			}

			New-RollingVMCheckpoint -VMName $vmName -MaxCheckpoints $maxCheckpoints

			if ($diskLocation)
			{
				$vm | Add-VMHardDiskDrive `
					-ControllerType SCSI `
					-ControllerNumber 0 `
					-ControllerLocation $diskLocation `
					-Path $diskPath
				$message = "Reconnected drive on SCSI 0 $diskLocation to virtual machine $vmName."
				New-RIPowerShellVirtualizationEvent -Message $message -EntryType Information -EventId 2202
			}
		}
	}
}

function Reset-VMNetworkAdapterConnection
{
	param (
		[Parameter(Mandatory=$true)][string[]]$VMName)

	$vmList = Get-VM -VMName $vm

	foreach ($vm in $vmList)
	{
		$vmNetworkAdapterList = $vm | Get-VMNetworkAdapter

		foreach ($vmNetworkAdapter in $vmNetworkAdapterList)
		{
			$delaySeconds = 1
			
			$vmSwitchName = $vmNetworkAdapter.switchname
			$vmNetworkAdapter | Disconnect-VMNetworkAdapter
			Start-Sleep -Seconds $delaySeconds
			$vmNetworkAdapter | Connect-VMNetworkAdapter -SwitchName $vmSwitchName
		}
	}
}

function Test-VMHost
{
	$serviceName = 'vmms'
	$serviceExists = Test-ServiceExists -Service $serviceName
	
	return $serviceExists
}

<#
.SYNOPSIS
Creates and formats a new virtual drive.

.DESCRIPTION
Creates and formats a new virtual drive.

.PARAMETER Path
Path for the new virtual drive. The extension must end in either .vhd or .vhdx.

.PARAMETER SizeBytes
Size in bytes for the new virtual drive.

.PARAMETER Label
Label for the volume on the new virtual drive.

.PARAMETER AssignDriveLetter
Assigns a drive letter to the virtual drive.

.PARAMETER Mount
Leaves the virtual hard drive mounted after being created.

.EXAMPLE
New-RollingVMCheckpointFromFile -Path .\rollingcheckpoints.csv
#>
function New-FormattedVHD
{
    [CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][UInt64]$SizeBytes,
		[Parameter(Mandatory=$true)][string]$Label,
		[switch]$AssignDriveLetter,
		[switch]$Mount)

	New-VHD -Path $Path -SizeBytes $SizeBytes | Out-Null
	$mountedVHDX = Mount-VHD -Path $Path -NoDriveLetter -Passthru
	$disk = $mountedVHDX.DiskNumber

	if ($AssignDriveLetter)
	{
		$driveLetter = Get-AvailableDriveLetter -First
		Format-Disk -Disk $disk -Label $Label -DriveLetter $driveLetter| Out-Null
	}
	else
	{
		Format-Disk -Disk $disk -Label $Label | Out-Null
	}
	
	$mountedVHDXPath = $mountedVHDX.path
	
	if (!$Mount)
	{
		Dismount-VHD -Path $mountedVHDXPath
	}
}