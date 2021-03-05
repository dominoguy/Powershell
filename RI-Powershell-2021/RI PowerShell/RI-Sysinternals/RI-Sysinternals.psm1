#RI-Sysinternals

function Copy-SysinternalsTools
{
	Param(
	    [Parameter(Position=1)][string]$Path = '.\')

	$siteRoot = 'https://live.sysinternals.com/'
	$toolList = 'autoruns.exe','procexp.exe','procmon.exe'
	
	$pathExists = Test-Path -Path $Path
	
	if (!$pathExists)
	{
		mkdir -Path $Path | Out-Null
	}
	
	foreach ($tool in $toolList)
	{
		$source = $siteRoot + $tool
		Start-BitsTransfer -Source $source -Destination $Path
	}
}