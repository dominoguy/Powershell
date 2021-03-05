#RI-ActiveDirectory

<#
.SYNOPSIS
Adds Active Directory attributes for Local Administrator Password Solution (LAPS).

.DESCRIPTION
Adds Active Directory attributes for Microsoft's Local Administrator Password Solution (LAPS).

You must be a member of Schema Admins to use this command, and have the LAPS PowerShell module installed.
#>
function Add-LapsSchema
{
	if (Test-ShellElevation)
	{
		$lapsModule = 'AdmPwd.PS' 
		
		try
		{
			Import-Module -Name $lapsModule -ErrorAction SilentlyContinue
		}
		catch
		{
			Write-Error -Message 'The requested operation requires Local Administrator Password Solution PowerShell module.'
		}

		$moduleInstalled = Get-Module -Name $lapsModule -ListAvailable

		if ($moduleInstalled)
		{
			Update-AdmPwdADSchema
		}
	}
}

<#
.SYNOPSIS
Copies the members of one AD group to another.

.DESCRIPTION
Copies the members of one Active Directory group to another.

.PARAMETER Source
Source Active Directory Group.

.PARAMETER Destination
Destination Active Directory Group.

.EXAMPLE
Copy-ADGroupMembers Developers Programmers
#>
function Copy-ADGroupMembers
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Source,
		[Parameter(Mandatory=$true,Position=2)][string]$Destination)
		
	$memberList = Get-ADGroup $Source | Get-ADGroupMember
	Add-ADGroupMember -Identity $Destination -Members $memberList		
}

<#
.SYNOPSIS
Enables Local Administrator Password Solution (LAPS) for the Workstations OU.

.DESCRIPTION
Enables Microsoft's Local Administrator Password Solution (LAPS) for the Workstations OU.

.PARAMETER AllowedPrincipals
URL to the remote repository.

.EXAMPLE
Enable-LapsForWorkstationsOU -AllowedPrincipals 'Workstation Admins'
#>
function Enable-LapsForWorkstationsOU
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string[]]$AllowedPrincipals)
	
	$ou = Get-ADBaseWorkstationsOUPath
	Enable-LapsOU -AllowedPrincipals $AllowedPrincipals -OU $ou
}

<#
.SYNOPSIS
Enables Local Administrator Password Solution (LAPS) for the Servers OU.

.DESCRIPTION
Enables Microsoft's Local Administrator Password Solution (LAPS) for the Servers OU.

.PARAMETER AllowedPrincipals
URL to the remote repository.

.EXAMPLE
Enable-LapsForServersOU -AllowedPrincipals 'Server Admins'
#>
function Enable-LapsForServersOU
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string[]]$AllowedPrincipals)
	
	$ou = Get-ADBaseServersOUPath
	Enable-LapsOU -AllowedPrincipals $AllowedPrincipals -OU $ou
}

function Enable-LapsOU
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string[]]$AllowedPrincipals,
		[Parameter(Mandatory=$true)][string]$OU)
	
	Set-AdmPwdComputerSelfPermission -OrgUnit $OU
	Set-AdmPwdReadPasswordPermission -OrgUnit $OU -AllowedPrincipals $AllowedPrincipals
	Set-AdmPwdResetPasswordPermission -OrgUnit $OU -AllowedPrincipals $AllowedPrincipals
}

function Get-ADWritableDomainController
{
	$domainController = Get-ADDomainController -Writable -Discover -Service ADWS -ForceDiscover

	return $domainController
}

function Get-ADResourceMembership
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][ValidateSet('ACL','PRN')][string]$ResourceType,
		[switch]$Recursive)

	$exportList = @()
	$resourceList = Get-ADGroup -Filter * | Where-Object {$_.Name -like "$ResourceType.*"}

	foreach ($resource in $resourceList)
	{
		$resourceName = $resource.Name
		$resourcePath = Convert-ADResourceToPath -ResourceName $resourceName
		$userList = $resource | Get-ADGroupMember -Recursive:$Recursive
		$userNameList = $userList.Name -join ', '
		$resourceEntry = New-Object -TypeName PSObject
        $resourceEntry | Add-Member -MemberType NoteProperty -Name 'Resource' -Value $resourceName
        $resourceEntry | Add-Member -MemberType NoteProperty -Name 'Path' -Value $resourcePath
        $resourceEntry | Add-Member -MemberType NoteProperty -Name 'Users' -Value $userNameList
		$exportList += $resourceEntry
	}

	return $exportList
}

function Convert-ADResourceToPath
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$ResourceName)
	
	$ResourceName -match "(\w*\.)(.*)(\.\w*\Z)" | Out-Null
	$resource = $matches[2]
	$path = $resource.Replace('.','\')

	return $path
}

function Get-ADBaseOUPath
{
	$adDomain = Get-ADDomain
	$adBaseOUPath = 'OU=' + $adDomain.Name + ',' + $adDomain.DistinguishedName
	$adBaseOUPath = $adBaseOUPath.ToUpper()
	
	return $adBaseOUPath
}


function Get-ADBaseGroupsOUPath
{
	[CmdletBinding()]

	$path = Get-ADBaseChildOUPath -ChildPath 'OU=Groups'
	
	return $path
}

function Get-ADBaseUsersOUPath
{
	[CmdletBinding()]

	$path = Get-ADBaseChildOUPath -ChildPath 'OU=Users'
	
	return $path
}

<#
.SYNOPSIS
Returns the path for the Printers resource OU.

.DESCRIPTION
Returns the path for the Printers resource OU in Active Directory.
#>
function Get-ADBasePrintersOUPath
{
	$path = Get-ADBaseChildOUPath -ChildPath 'OU=Printers,OU=Resources'
	
	return $path
}

function Get-ADBaseServersOUPath
{
	[CmdletBinding()]

	$path = Get-ADBaseChildOUPath -ChildPath 'OU=Servers,OU=Computers'
	
	return $path
}

function Get-ADBaseWorkstationsOUPath
{
	[CmdletBinding()]

	$path = Get-ADBaseChildOUPath -ChildPath 'OU=Workstations,OU=Computers'
	
	return $path
}

function Get-ADBaseChildOUPath
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$ChildPath)
	
	$adBaseOUPath = Get-ADBaseOUPath
	$path = "$ChildPath,$adBaseOUPath"

	return $path
}

function Get-ADDisabledUsers
{
	Install-ADPowerShellRsat
	$searchBase = Get-ADBaseUsersOUPath
	$disabledUsers = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $searchBase

	return $disabledUsers
}

<#
.SYNOPSIS
Returns a list of workstation administrator passwords.

.DESCRIPTION
Returns a list of workstation administrator passwords stored in Active Directory using Microsoft Local Administrator Password Solution (LAPS).
#>
function Get-ADWorkstationAdminPasswords
{
	$workstationsOU = Get-ADBaseWorkstationsOUPath
	$workstationList = Get-AdComputer -SearchBase $workstationsOU -Filter * 
	$passwordList = @()

	foreach ($workstation in $workstationList)
	{
		$workstationName = $workstation.Name
		$passwordEntry = Get-AdmPwdPassword -ComputerName $workstationName
		$passwordList += $passwordEntry
	}

	return $passwordList
}

<#
.SYNOPSIS
Creates a new printer resource group in Active Directory.

.DESCRIPTION
Creates a new printer resource group in Active Directory for each specified printer name.

.PARAMETER Name
Name of the printer.

.EXAMPLE
New-ADPrinterResourceGroup -Name GL-PRN-001,GL-PRN-002
#>
function New-ADPrinterResourceGroup
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string[]]$Name)

		foreach ($printer in $Name)
		{
			$printer = $printer.ToUpper()
			$resourceName = "PRN.$printer.Print"
			$path = Get-ADBasePrintersOUPath
			New-ADGroup `
				-Name $resourceName  `
				-DisplayName $resourceName `
				-GroupScope DomainLocal `
				-GroupCategory Security `
				-Path $path
		}
}

<#
.SYNOPSIS
Creates Active Directory accounts for MAC-based authentication from a CSV file.

.DESCRIPTION
Creates Active Directory accounts for MAC-based authentication from a CSV file and adds them to the MAC Authenticated Computers security group.

.PARAMETER Path
Path to CSV file. The CSV file must contain macAddress, computerName and deviceType fields.

.EXAMPLE
New-ADMacAccountsFromFile -Path .\macinfo.csv
#>
function New-ADMacAccountsFromFile
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Path)

	$deviceList = Import-CSV -Path $Path

	for ($i = 0; $i -lt $deviceList.Count; $i++)
	{
		$device = $deviceList[$i]
		$computerName = $device.computerName
		$macAddress = $device.macAddress
		$deviceType = $device.deviceType
		New-ADMacAccount -ComputerName $computerName -MacAddress $macAddress -DeviceType $deviceType
		
		$activity = 'New-ADMacAccountsFromFile' 
		$status = "Account created for device: $computerName"
		$percentComplete = ($i/$deviceList.Count*100)
		Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
	}
}

<#
.SYNOPSIS
Creates a new Active Directory account for MAC-based authentication.

.DESCRIPTION
Creates a new Active Directory account for MAC-based authentication and adds them to the MAC Authenticated Computers security group.

.PARAMETER ComputerName
Name of the computer.

.PARAMETER MacAddress
MAC Address of the system.

.PARAMETER DeviceType
Type of network device. Valid types are Workstation, Phone or Printer.

.EXAMPLE
New-ADMacAccount -ComputerName FOO-DT-001 -MacAddress 0123456789AB -DeviceType Workstation
#>
function New-ADMacAccount
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$ComputerName,
		[Parameter(Mandatory=$true)][string]$MacAddress,
		[Parameter(Mandatory=$true)][ValidateSet('Workstation','Phone','Printer')][string]$DeviceType)
	
	$accountPrefix = 'MACAuth-'

	$MacAddress = (ConvertTo-ShortMACAddress -MacAddress $MacAddress).ToUpper()
	$accountName = "$accountPrefix$MacAddress"
	$userExists = Get-ADUser -Filter {SamAccountName -eq $accountName}  -ErrorAction SilentlyContinue
	
	if (!$userExists)
	{
		$defaultGroup = 'Domain Users'
		$groupPrefix = 'MAC Authenticated'
		$groupSuffix = 's'

		$server = Get-ADWritableDomainController
		$macGroup = "$groupPrefix $DeviceType$groupSuffix"
		$domainFqdn = Get-ADDomainFqdn
		$securePassword = New-RandomPassword -Length 32
		New-AdUser `
			-AccountPassword $securePassword `
			-CannotChangePassword $true `
			-ChangePasswordAtLogon $false `
			-Description $ComputerName `
			-DisplayName $accountName `
			-Enabled $true `
			-GivenName $accountName `
			-SamAccountName $accountName `
			-AllowReversiblePasswordEncryption $true `
			-Server $server `
			-Name $accountName `
			-PasswordNeverExpires $true `
			-UserPrincipalName "$accountName@$domainFqdn"
		Add-ADGroupMember -Identity $macGroup -Members $accountName -Server $server
		Set-ADUserPrimaryGroup -Identity $accountName -Group $macGroup -Server $server
		Remove-ADGroupMember -Identity $defaultGroup -Members $accountName -Server $server -Confirm:$false
		$macPassword = ConvertTo-SecureString -String $MacAddress -AsPlainText -Force
		Set-ADAccountPassword -Identity $accountName -NewPassword $macPassword -Server $server
	}
}

function Set-ADUserPrimaryGroup
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Identity,
		[Parameter(Mandatory=$true)][string]$Group,
		[Parameter(Mandatory=$true)][string]$Server)

	$groupID = (Get-AdGroup -Identity $Group -Properties PrimaryGroupToken -Server $Server).PrimaryGroupToken
	Set-ADUSer -Identity $Identity -Replace @{primaryGroupID=$groupID} -Server $Server
}

<#
.SYNOPSIS
Generates a new random password of a specified length.

.DESCRIPTION
Generates a new random password of a specified length.

.PARAMETER Length
Length of the password.

.PARAMETER AsPlainText
Return password as plain text.

.EXAMPLE
New-RandomPassword -Length 32 -AsPlainText
#>
function New-RandomPassword
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Length,
		[switch]$AsPlainText)
	
	$alphabet = @()

	for ($i = 33; $i -lt 127; $i++)
	{
		$alphabet += [char][byte]$i
	}

	$password = $null

	for ($i = 0; $i -lt $Length; $i++)
	{
		$character = Get-Random -InputObject $alphabet
		$password += $character
	}

	if ($AsPlainText)
	{
		return $password
	}
	else
	{
		$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
		
		return $securePassword
	}
}

function New-ADMacGroup
{
	param(
		[Parameter(Mandatory=$true)][ValidateSet('Workstation','Phone','Printer')][string]$DeviceType)
	
	$groupPrefix = 'MAC Authenticated'
	$groupSuffix = 's'

	$macGroup = "$groupPrefix $DeviceType$groupSuffix"
	$macGroupExists = Get-ADGroup -Filter {SamAccountName -eq $macGroup}

	if (!$macGroupExists)
	{
		New-ADGroup -Name $macGroup -GroupCategory Security -GroupScope Global
	}
}

<#
.SYNOPSIS
Creates a fine-grained password policy for MAC authentication.

.DESCRIPTION
Creates a fine-grained password policy named MAC Authenticated Devices for MAC authentication.
#>
function New-ADMacFineGrainedPasswordPolicy
{
	$policyName = 'MAC Authenticated Devices'
	$macGroupList = 'MAC Authenticated Workstations','MAC Authenticated Phones',
		'MAC Authenticated Printers'

	$server = Get-ADWritableDomainController
	New-ADFineGrainedPasswordPolicy `
		-ComplexityEnabled $false `
		-DisplayName $policyName `
		-LockoutThreshold 1 `
		-MinPasswordLength 12 `
		-MaxPasswordAge 0 `
		-MinPasswordAge 0 `
		-Name $policyName `
		-PasswordHistoryCount 24 `
		-Precedence 1 `
		-ProtectedFromAccidentalDeletion $true `
		-ReversibleEncryptionEnabled $true `
		-Server $server `
		-OtherAttributes @{"msDS-LockoutDuration"="-9223372036854775808"}

	foreach ($macGroup in $macGroupList)
	{
		$macGroupExists = Get-ADGroup -Filter {SamAccountName -eq $macGroup}

		if (!$macGroupExists)
		{
			New-ADGroup -Name $macGroup -GroupCategory Security -GroupScope Global -Server $server
		}
	}

	Add-ADFineGrainedPasswordPolicySubject -Identity $policyName -Subjects $macGroupList -Server $server
}

function Get-ADDomainFqdn
{
	$adDomain = Get-ADDomain
	$domainFqdn = $adDomain.DNSRoot

	return $domainFqdn
}

function Remove-DisabledUsersFromDistributionGroups
{
	param(
		[Parameter(Mandatory=$true)][string]$SearchBase)
	
	$groupList = Get-ADGroup -Filter 'GroupCategory -eq "Distribution"' -SearchBase $SearchBase
	
	foreach ($group in $groupList)
	{
		$memberList = Get-ADGroupMember -Identity $group -Recursive
		
		foreach ($member in $memberList)
		{
            $disabledList = Get-ADUser -Identity $member.distinguishedName -Properties Enabled | `
				Where-Object {$_.Enabled -eq $false}
				
			foreach ($disabled in $disabledList)
			{
				Remove-ADGroupMember -Identity $group -Member $member -Confirm:$false
			}
        }
    }
}

<#
.SYNOPSIS
Resets a user account's password expiry date.

.DESCRIPTION
Resets an Active Directory user account's password expiry date.

.PARAMETER Identity
Name of old server.

.EXAMPLE
Reset-ADUserPasswordExpiry -Identity fbar
#>
function Reset-ADUserPasswordExpiry
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Identity)

	$user = Get-ADUser -Identity $Identity -Properties pwdLastSet
	$user.pwdLastSet = 0
	Set-ADUser -Instance $user
	$user.pwdLastSet = -1
	Set-ADUser -Instance $user
}

<#
.SYNOPSIS
Tests if a password is valid against an AD account.

.DESCRIPTION
Tests if a password is valid against an Active Directory account.

Note that the test will return false if the account is currently locked out.

.PARAMETER Username
Name of an Active Directory account.

.PARAMETER Password
Password to test. 

.EXAMPLE
Test-ADAccountPassword foo
#>
function Test-ADAccountPassword
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Username,
		[Parameter(Mandatory=$true,Position=2)][securestring]$Password)

	$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
	$unsecuredPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
	$directoryEntry = New-Object DirectoryServices.DirectoryEntry('', $Username, $unsecuredPassword)
	[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

	if ($directoryEntry.PSBase.Name)
	{
		return $true
	}
	else
	{
		return $false
	}
}

<#
.SYNOPSIS
Updates the user profile and home folder paths for all users.

.DESCRIPTION
Updates the user profile and home folder paths for all users in Active Directory.

.PARAMETER OldSerer
Name of old server.

.PARAMETER NewSerer
Name of new server.

.EXAMPLE
Update-ADUserProfilePaths -OldServer GL-FS-001 -NewServer GL-FS-004
#>
function Update-ADUserProfilePaths
{
	param(
		[Parameter(Mandatory=$true)][string]$OldServer,
		[Parameter(Mandatory=$true)][string]$NewServer)
		
	if (Test-ShellElevation)
	{
		$baseOU = Get-ADBaseUsersOUPath
		$userList = Get-ADUser -Filter * -SearchBase $baseOU -Properties *

		foreach ($user in $userList)
		{
			$homeDirectory = $user.homeDirectory
			$profilePath = $user.profilePath
			
			if ($homeDirectory)
			{
				$homeDirectory = $homeDirectory -replace $OldServer,$NewServer
				$user | Set-ADUser -HomeDirectory $homeDirectory
			}
			
			if ($profilePath)
			{
				$profilePath = $profilePath -replace $OldServer,$NewServer
				$user | Set-ADUser -ProfilePath $profilePath
			}
		}
	}
}

function Update-ADUserInformation
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)
	
	$userList = Import-Csv -Path $Path

	for ($i = 0; $i -lt $userList.Count; $i++)
	{
		$user = $userList[$i]
		$userName = $user.firstName.SubString(0,1) + $user.lastName
		$userName = $userName.ToLower()
		$activity = 'Update-ADUserInformation' 
		$status = "Updating: $userName"
		$percentComplete = ($i/$userList.Count*100)
		Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete

		try
		{
			Get-ADUser -Identity $userName -ErrorAction SilentlyContinue
			$location = $user.location
			$description = $user.role
			Set-ADUser `
				-Identity $userName `
				-Description $description `
				-Office $location
		}
		catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
		{
		}
	}
}

<#
.SYNOPSIS
Moves FSMO roles to a specified Domain Controller.

.DESCRIPTION
Moves all five FSMO roles to a specified Domain Controller. Optionally, these roles may be seized.

Note that to move all five roles, the current must be a member of Schema Admins.

.PARAMETER Identity
Identity of the Domain Controller to move all FSMO roles to.

.PARAMETER Server
Name of the Domain Controller running Active Directory Web Services. If unspecified, the server specified in Identity will be used.

.PARAMETER Force
Roles are seized during the move.

.EXAMPLE
Move-FsmoRoles -Identity GL-HDC-002
#>
function Move-FsmoRoles
{
	param(
		[Parameter(Mandatory=$true)][string]$Identity,
		[string]$Server,
		[switch]$Force)

	if (Test-ShellElevation)
	{
		$roles = 'SchemaMaster','RIDMaster','InfrastructureMaster','DomainNamingMaster','PDCEmulator'
		
		if (!$Server)
		{
			$Server = $Identity
		}
		
		Move-ADDirectoryServerOperationMasterRole `
			-Identity $Identity `
			-Server $Server `
			-OperationMasterRole $roles `
			-Force:$Force
	}
}