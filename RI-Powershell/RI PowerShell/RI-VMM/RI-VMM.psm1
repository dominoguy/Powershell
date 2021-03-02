#RI-VMM

function Register-VMMManagedHosts
{
	param(
		[Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$Credential,
		[Parameter(Mandatory=$true)][string]$VMMServer)
	
	Get-VMMManagedComputer -VMMServer $VMMServer | `
		Where-Object {$_.Role -like "*Host*"} | `
		Register-SCVMMManagedComputer -Credential $Credential |
		Select-Object Name,MostRecentTask
}

function Repair-SCVMTemplateBootDrive
{
	param(
		[Parameter(Mandatory=$true)][string]$Name)

	$firstBoodDevice = 'SCSI,0,0'
	Get-SCVMTemplate -Name $Name | Set-SCVMTemplate -FirstBootDevice $firstBoodDevice
}