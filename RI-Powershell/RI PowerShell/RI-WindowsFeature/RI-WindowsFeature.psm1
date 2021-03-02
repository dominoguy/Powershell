#RI-WindowsFeature

<#
.SYNOPSIS
Installs RSAT on a workstation.

.DESCRIPTION
Installs RSAT on a Windows 10 workstation with a release ID of at least 1809.

Starting with Windows 10 1809, Microsoft made RSAT a Feature On Demand; there is no longer a need to download it.
#>
function Install-RsatOnWorkstation
{
    if (Test-ShellElevation)
    {
        $minReleaseID = 1809
        $releaseID = Get-WindowsReleaseID

        if ($releaseID -ge $minReleaseID)
        {
            $rsatList = Get-WindowsCapability -Name "rsat*" -Online
            
            for ($i = 0; $i -lt $rsatList.Count; $i++)
            {
                $name = $rsatList[$i].DisplayName

                $activity = 'Install-RSATOnWorkstation' 
                $status = "Installing $name"
                $percentComplete = ($i/$rsatList.Count*100)
                Write-Progress `
                    -Activity $activity `
                    -Status $status `
                    -PercentComplete $percentComplete

                $rsatList[$i] | Add-WindowsCapability -Online | Out-Null
            }
        }
        else
        {
            Write-Host "The requested operation requires a Windows release ID greater than $minReleaseID."
        }
    }
}

<#
.SYNOPSIS
Installs AD PowerShell RSAT.

.DESCRIPTION
Installs the Active Directory PowerShell RSAT.
#>
function Install-ADPowerShellRsat
{
	$feature = 'RSAT-AD-PowerShell'
	
	Install-WindowsFeature $feature | Out-Null
}

<#
.SYNOPSIS
Installs the Remote Server Administration Tools (RSAT).

.DESCRIPTION
Installs the Remote Server Administration Tools (RSAT) for the following features:

Active Directory Domain Services
DHCP Server
DNS Server
Group Policy
Print Services
Windows Server Update Services
#>
function Install-RSAT
{
	if (Test-ShellElevation)
	{
		$featureList = 'GPMC','RSAT-AD-PowerShell','RSAT-ADDS-Tools', `
			'RSAT-DHCP','RSAT-DNS-Server','RSAT-Print-Services', `
			'UpdateServices-RSAT'
			
		Install-WindowsFeature $featureList | Out-Null
	}
}

function Install-HttpActivation45
{
	Install-WindowsFeature -Name 'NET-WCF-HTTP-Activation45' -ErrorAction SilentlyContinue
}

function Install-NetFramework35
{
	if (Test-ShellElevation)
	{
		$features = 'NET-Framework-Features'
		$sourcePath = ':\sources\sxs'
		
		$volumeList = Get-Volume | Where-Object {$_.driveLetter -ne $null}	
		$validPathList = @()

		foreach ($volume in $volumeList)
		{
			$driveLetter = $volume.driveLetter
			$testPath = $driveLetter + $sourcePath
			$validPath = Test-Path -Path $testPath

			if ($validPath)
			{
				$validPathList += $testPath
			}
		}

		if ($validPathList)
		{
			Install-WindowsFeature -Name $features -Source $validPathList[0]
		}
		else
		{
			Write-Warning -Message 'Unable to locate the Windows source media. Mount the required media and re-run the command. If the media was mounted after the start of this RI PowerShell session, launch a new one and try again.'
		}
	}
}

<#
.SYNOPSIS
Installs the Telnet client.

.DESCRIPTION
Installs the Telnet client using DISM.
#>
function Install-TelnetClient
{
	if (Test-ShellElevation)
	{
		dism /online /Enable-Feature /FeatureName:TelnetClient /NoRestart
	}
}

<#
.SYNOPSIS
Uninstalls the Remote Server Administration Tools (RSAT).

.DESCRIPTION
Uninstalls the Remote Server Administration Tools (RSAT) for the following features:

Active Directory Domain Services
DHCP Server
DNS Server
Group Policy
Print Services
Windows Server Update Services

.PARAMETER Restart
Restarts Windows if required.

.EXAMPLE
Uninstall-RSAT -Restart
#>
function Uninstall-RSAT
{
	param(
		[switch]$Restart)
		
	if (Test-ShellElevation)
	{
		$features = 'GPMC','RSAT-AD-PowerShell','RSAT-ADDS-Tools', `
			'RSAT-DHCP','RSAT-DNS-Server','RSAT-Print-Services', `
			'UpdateServices-RSAT'
			
		$uninstallResults = Uninstall-WindowsFeature $features
		$restartRequired = $uninstallResults.RestartNeeded
		
		if ($restartRequired -and $Restart)
		{
			Restart-ComputerWithDelay
		}
	}
}