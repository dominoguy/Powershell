#RI-SMB

function Copy-SMBShare
{
	param(
		[Parameter(Mandatory=$true)][string]$CredentialFile)

	$psDriveName = 'remoteServer'
	
	$serverList = Import-Csv -Path $CredentialFile

	foreach ($server in $serverList)
	{
		$username = $server.username
		$password = $server.password
		$credential = Get-CredentialViaPlainText -Username $username -Password $password
		$remotePath = $server.remotePath
		$destinationPath = $server.destinationPath

		try
		{
			New-PSDrive -Name $psDriveName -PSProvider FileSystem -Root $remotePath -Credential $credential -ErrorAction Stop
			robocopy $remotePath $destinationPath /MIR /W:0 /R:0 /XJ
		}
		catch [System.Exception]
		{
			Write-Host "ERROR: Can't connect to remote server $serverFQDN. Ensure credentials are correct." -ForegroundColor Red
		}
		
		Remove-PSDrive -Name $psDriveName -ErrorAction SilentlyContinue
	}
}