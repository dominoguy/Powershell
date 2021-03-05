#RI-Memory

function Get-Memory
{
	$operatingSystem = Get-Ciminstance Win32_OperatingSystem
	$memory = $operatingSystem | Select-Object -Property *memory*
	
	return $memory
}

function Get-MemoryAvailable
{
	$memory = Get-Memory
	$memoryAvailable = $memory.FreePhysicalMemory
	
	return $memoryAvailable
}

function Get-MemoryInUse
{
	$physicalMemory = Get-PhysicalMemory
	$memoryAvailable = Get-MemoryAvailable
	$memoryInUse = $physicalMemory - $memoryAvailable
	
	return $memoryInUse
}

function Get-MemorySummary
{
	$memoryCritical = 2GB
	$memoryWarning = 4GB
	
	$memoryAvailable = (Get-MemoryAvailable) * 1024
	
	if ($memoryAvailable -lt $memoryCritical)
	{
		Write-CriticalSummary "Less than 2 GB of memory is available on this host."
	}
	else
	{
		if ($memoryAvailable -lt $memoryWarning)
		{
			Write-WarningSummary "Less than 4 GB of memory is available on this host."
		}
	}
}

function Get-MemoryUseRatio
{
	$memoryInUse = (Get-MemoryInUse) * 1024
	$physicalMemory = (Get-PhysicalMemory) * 1024
	$memoryInUseRounded = ($memoryInUse/1GB).ToString("0.0")
	$physicalMemoryRounded = ($physicalMemory/1GB).ToString("0.0")
	$ratio = "$memoryInUseRounded/$physicalMemoryRounded"
	
	return $ratio
}

function Get-PhysicalMemory
{
	$memory = Get-Memory
	$physicalMemory = $memory.TotalVisibleMemorySize
	
	return $physicalMemory
}