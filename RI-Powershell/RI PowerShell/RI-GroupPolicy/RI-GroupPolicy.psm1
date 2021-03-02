#RI-GroupPolicy

function Export-GPCentralStore
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Path)

	$centralStorePath = Get-GPCentralStorePath
	$centralStoreExists = Test-Path -Path $centralStorePath

	if ($centralStoreExists)
	{
		Copy-Item -Path $centralStorePath -Destination $Path -Recurse
	}
	else
	{
		Write-Warning -Message 'There is no Group Policy Central Store in this domain.'
	}
}

function Export-GPO
{
	[CmdletBinding()]
	
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$Path,
		[switch]$Mirror)
	
	if (Test-ShellElevation)
	{
		$gpoList = Get-GPO -All
		
		for ($i = 0; $i -lt $gpoList.Count; $i++)
		{
			$name = $gpoList[$i].DisplayName
			$exportPath = Join-Path -ChildPath $name -Path $Path
			
			Remove-Item -Path $exportPath -Recurse -Force -ErrorAction SilentlyContinue
			$directory = New-Item $exportPath -Type Directory -Force
			Backup-GPO -Name $name -Path $directory.FullName | Out-Null
			
			$activity = 'Export-GPO' 
			$status = "Exporting Group Policy Object: $name"
			$percentComplete = ($i/$gpoList.Count*100)
			Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
		}
		
		if ($Mirror)
		{
			$directoryList = Get-ChildItem -Path $Path -Directory
			
			foreach ($directory in $directoryList)
			{
				$name = $directory.name
				
				try
				{
					Get-GPO -Name $name -ErrorAction Stop | Out-Null
				}
				catch
				{
					Remove-Item -Path $Path\$name -Recurse -Confirm:$false -Force
				}
			}
		}
	}
}

function Get-GPCentralStorePath
{
	$adDomain = Get-ADDomain
	$domainFQDN = $adDomain.DNSRoot
	$sysvolPath = "\\$domainFQDN\SYSVOL\$domainFQDN\Policies\PolicyDefinitions"

	return $sysvolPath
}

function Import-GPOLibrary
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Path,
		[switch]$Force)
		
	$directoryList = Get-ChildItem -Path $Path -Directory

	foreach ($directory in $directoryList)
	{
		$gpoName = $directory.Name
		$forbiddenPolicyList = 'Default Domain Controllers Policy','Default Domain Policy'
		$gpoForbidden = $gpoName -in $forbiddenPolicyList

		if (!$gpoForbidden)
		{
			$gpoExists = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue| Out-Null
			
			if (!$gpoExists -or $Force)
			{
				New-GPO -Name $gpoName -ErrorAction SilentlyContinue
				$gpoPath = $directory.FullName
				Import-GPO -Path $gpoPath -BackupGpoName $gpoName -TargetName $gpoName | Out-Null
			}
			else 
			{
				Write-Host "A GPO named $gpoName already exists. To overwrite, use the -Force switch."
			}
		}
		else
		{
			Write-Host "Import of forbidden policy $gpoName denied."
		}
	}
}