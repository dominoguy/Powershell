#RI-DellOMSA

function Restart-DellOMSAServices
{
	if (Test-ShellElevation)
	{
		if(Test-IsDellServer)
		{
			$dependantServices = 'Server Administrator'
			$independantServices = 'dcevt64','omsad','dcstor64'
	
			Stop-Service $dependantServices
			Stop-Service $independantServices
			Start-Service $independantServices
			Start-Service $dependantServices
		}
	}
}

function Test-OMSAInstall
{
	param(
		[switch]$HideMessage)
	
	$installPath = 'C:\Program Files\Dell\SysMgt'
	
	$installed = Test-Path -Path $installPath
	
	if($installed)
	{
		return $installed
	}
	else
	{
		if(!$HideMessage)
		{
			Write-Host "`The requested operation requires Dell OMSA.`n"
		}
	
		return $installed
	}
}
		