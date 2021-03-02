#RI-FileDeduplication

function Get-DedupDefaultOptimizationJobs
{
	$jobs = Get-DedupSchedule | `
		Where-Object {($_.Name -like "BackgroundOptimization*") -or ($_.Name -like "ThroughputOptimization*")}
	
	return $jobs
}

function Set-DedupDefaultOptimizationJobs
{
	param(
		[Parameter(Mandatory=$true,Position=1)][bool]$Enabled)
	
	if(Test-ShellElevation)
	{
		$jobs = Get-DedupDefaultOptimizationJobs
		$jobs | Set-DedupSchedule -Enabled $Enabled
	}
}