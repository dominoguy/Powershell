#RI-Storage

function ConvertTo-RoundedDownGB ($size)
{
	$size = [math]::truncate($size/1GB)
	
	return $size
}

function Get-FileTypeSize
{
	Param(
		[Parameter(Mandatory=$true,Position=1)][string]$Extension,
		[Parameter(Mandatory=$true,Position=2)][string]$Path)
		
	$files = Get-ChildItem -Include *.$Extension -Path $Path -Recurse -ErrorAction SilentlyContinue
	$size = ($files | Measure-Object -Sum Length).Sum
	
	return $size
}

function Get-FixedVolumes
{
	$fixedVolumes = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'}
	
	return $fixedVolumes
}

function Get-FixedVolumeSummary
{
	$unhealthyVolumes = Get-FixedVolumes | `
		Where-Object {$_.HealthStatus -ne 'Healthy'}
	
	if ($unhealthyVolumes)
	{
		$count = $unhealthyVolumes.count
		
		Write-CriticalSummary "$count 'fixed storage file systems(s) reported an unhealthy status.'"
	}
	if (!$unhealthyVolumes)
	{
		Write-OptimalSummary 'Fixed storage file systems healthy.'
	}
}

function Get-SystemVolume
{
	if (Test-ShellElevation)
	{
		$systemDrive = $env:SYSTEMDRIVE
		$systemDrive = $systemDrive -replace ':',''
		
		$systemVolume = Get-Volume $systemDrive
		
		return $systemVolume
	}
}

function Format-Disk
{
	param(
		[Parameter(Mandatory=$true)][int]$Disk,
		[ValidateSet('GPT','MBR')][string]$PartitionStyle='GPT',
		[Parameter(Mandatory=$false)][string]$DriveLetter,
		[Parameter(Mandatory=$true)][string]$Label,
		[switch]$Force)
		
	if (Test-ShellElevation)
	{
		$diskToFormat = Get-Disk $Disk
		$existingPartitionStyle = $diskToFormat.partitionStyle
		
		if ($existingPartitionStyle -ne 'RAW')
		{
			if (!$Force)
			{
				Write-Warning -Message 'Drive is already initialized and may contain data. Re-run this command with the -Force switch to format this drive.'
			}
			else
			{
				if ($DriveLetter)
				{
					$diskToFormat | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -PassThru | `
						Initialize-Disk -PartitionStyle $PartitionStyle -PassThru | `
						New-Partition -DriveLetter $DriveLetter -UseMaximumSize | `
						Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false
				}
				else
				{
					$diskToFormat | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -PassThru | `
						Initialize-Disk -PartitionStyle $PartitionStyle -PassThru | `
						New-Partition -UseMaximumSize | `
						Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false
				}
			}
		}
		else
		{
			if ($DriveLetter)
			{
				$diskToFormat | `
					Initialize-Disk -PartitionStyle $PartitionStyle -PassThru | `
					New-Partition -DriveLetter $DriveLetter -UseMaximumSize | `
					Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false
			}
			else
			{
				$diskToFormat | `
					Initialize-Disk -PartitionStyle $PartitionStyle -PassThru | `
					New-Partition -UseMaximumSize | `
					Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false
			}
		}
	}
}