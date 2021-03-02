#RI-Credential

function Get-CredentialViaPlainText
{
	Param(
		[Parameter(Mandatory=$true,Position=1)][string]$Username,
		[Parameter(Mandatory=$true,Position=1)][string]$Password)
	
	$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
	$credential = New-Object -TypeName System.Management.Automation.PSCredential `
	         -ArgumentList $username,$securePassword
			 
	return $credential
}