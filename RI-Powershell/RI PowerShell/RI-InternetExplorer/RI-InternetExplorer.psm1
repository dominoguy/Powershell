#RI-InternetExplorer

function Reset-InternetExplorerToDefaults
{
	RunDll32.exe InetCpl.cpl,ResetIEtoDefaults
}

function Disable-InternetExplorerESC
{
	$adminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
	
	Set-ItemProperty -Path $adminKey -Name “IsInstalled” -Value 0
	Stop-Process -Name Explorer
}

function Enable-InternetExplorerESC
{
	$adminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
	
	Set-ItemProperty -Path $adminKey -Name “IsInstalled” -Value 1
	Stop-Process -Name Explorer
}