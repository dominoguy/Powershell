#RI-Exchange

<#
.SYNOPSIS
Enables anonymous relay on an Exchange server.

.DESCRIPTION
Enabled anonymous SMTP relay on an Exchange server receive connector.

.PARAMETER ReceiveConnector
Identity of the Exchange server receive connector to modify.
#>
function Enable-ExchangeAnonymousRelay
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$ReceiveConnector)

	$connector = Get-ReceiveConnector -Identity $ReceiveConnector
	$connector | Add-ADPermission -User 'NT AUTHORITY\ANONYMOUS LOGON' -ExtendedRights 'Ms-Exch-SMTP-Accept-Any-Recipient'
}

function Get-DisabledMailboxes
{
	$disabledUserList = Get-ADDisabledUsers
	$disabledMailboxList = @()

	foreach ($disabledUser in $disabledUserList)
	{
		$identity = $disabledUser.samaccountname
		$mailbox = Get-MailboxStatistics -Identity $identity -ErrorAction SilentlyContinue
		
		if ($mailbox)
		{
			$disabledMailboxList += $mailbox
		}
	}

	return $disabledMailboxList
}

<#
.SYNOPSIS
Exports disabled users' Exchange mailboxes to PST files.

.DESCRIPTION
Exports disabled users' Exchange mailboxes to PST files. The destination must be referenced by UNC and accessible by the Exchange server's machine account.

.PARAMETER Path
Location to export the PST files. The path must be a UNC accessible by Exchange server's machine account.

If a PST already exists for a given user, the -Force switch will be needed to overwrite.

.PARAMETER MaxRequests
Maximum number of export requests to make to Exchange.

.EXAMPLE
Export-DisabledMailboxes -Path \\RI-FS-001\Archive\Mail -MaxRequests 10
#>
function Export-DisabledMailboxes
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][int]$MaxRequests,
		[switch]$Force)
	
	$completedRequests = 0
	$disabledMailboxList = Get-DisabledMailboxes

	for ($i = 0; $i -lt $disabledMailboxList.Count; $i++)
	{
		if ($completedRequests -lt $MaxRequests)
		{
			$disabledMailbox = $disabledMailboxList[$i]
			$displayName = $disabledMailbox.DisplayName
			$exportStarted = Export-Mailbox -DisplayName $displayName -Path $Path -Force:$False

			if ($exportStarted)
			{
				$completedRequests++
			}
		}
	}
}

<#
.SYNOPSIS
Exports an Exchange mailbox to a PST file.

.DESCRIPTION
Exports an Exchange mailbox to a PST file. The destination must be referenced by UNC and accessible by the Exchange server's machine account.

.PARAMETER DisplayName
Name of the tag to create.

.PARAMETER Path
Location to export the PST file. The path must be a UNC accessible by Exchange server's machine account.

If a PST already exists for the user, the -Force switch will be needed to overwrite.

.EXAMPLE
Export-Mailbox -DisplayName "Foo Bar" -Path \\RI-FS-001\Archive\Mail
#>
function Export-Mailbox
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$DisplayName,
		[Parameter(Mandatory=$true)][string]$Path,
		[switch]$Force)

	$fileName = "Archive - $DisplayName.pst"
	$filePath = Join-Path -Path $Path -ChildPath $fileName
	$pathExists = (Test-Path -Path $filePath)

	if (!$pathExists -or $Force)
	{
		$requestName = "Archive-$DisplayName"
		New-MailboxExportRequest `
			-Mailbox $DisplayName `
			-FilePath $filePath `
			-Name $requestName `
			-ExcludeDumpster `
			-AcceptLargeDataLoss `
			-BadItemLimit Unlimited `
			-LargeItemLimit Unlimited `
			-WarningAction SilentlyContinue

		return $true
	}
	else
	{
		Write-Warning -Message "A PST for $DisplayName already exists. Use -Force to overwrite."

		return $false
	}
}

<#
.SYNOPSIS
Returns a list of active Exchange mailboxes.

.DESCRIPTION
Returns a list of Exchange mailboxes that have been used within a specified number of days.

.PARAMETER Days
Number of days to check for active mailboxes.

.EXAMPLE
Get-ActiveMailbox -Days 90
#>
function Get-ActiveMailbox
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][int]$Days)
	
	$mailboxList = Get-Mailbox -ResultSize Unlimited –RecipientTypeDetails UserMailbox,SharedMailbox
	$activeMailboxList =  $mailboxList | `
		Where-Object {(Get-MailboxStatistics $_.Identity).LastLogonTime -gt (Get-Date).AddDays(-$Days)}

	return $activeMailboxList
}

<#
.SYNOPSIS
Returns the mailbox GUID of an Exchange user.

.DESCRIPTION
Returns the mailbox GUID of a given Exchange user.

.PARAMETER Identity
Identity of the mailbox.
#>
function Get-ExchangeMailboxGUID
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$Identity)

	Set-ExchangeScopeToForest
	$mailbox = Get-Mailbox -Identity $Identity
	$exchangeGUID = $mailbox.exchangeGUID

	return $exchangeGUID
}

<#
.SYNOPSIS
Displays health of an Exchange search index.

.DESCRIPTION
Returns properties describing the current health of an Exchange server's search index.
#>
function Get-ExchangeSearchHealth
{
	Get-MailboxDatabaseCopyStatus | Format-List -Property "Cont*"
}

<#
.SYNOPSIS
Returns the local parts for all email addresses attached to a mailbox.

.DESCRIPTION
Returns all unique local parts for all email addresses attached to a mailbox.

.PARAMETER Identity
Identity of the mailbox.
#>
function Get-MailboxLocalParts
{
	param(
		[Parameter(Mandatory=$true, Position=1)][string]$Identity)

	$mailbox = Get-UserMailbox -Identity $Identity
	$emailAddressList = $mailbox.emailAddresses.smtpAddress
	$localPartList = New-Object System.Collections.Generic.List[String]

	foreach ($emailAddress in $emailAddressList)
	{
		$emailAddress -match "(.*)(\@.*)" | Out-Null
		$localPart = $matches[1]

		if (!$localPartList.Contains($localPart))
		{
			$localPartList.Add($localPart)
		}
	}

	return $localPartList.ToArray()
}

<#
.SYNOPSIS
Returns the display name associated with a mailbox.

.DESCRIPTION
Returns the display name associated with an Exchange mailbox.

.PARAMETER Identity
Identity of the mailbox.
#>
function Get-MailboxDisplayName
{
	param(
		[Parameter(Mandatory=$true, Position=1)][string]$Identity)

	$mailbox = Get-UserMailbox -Identity $Identity
	$displayNameList = $mailbox.displayName

	return $displayNameList
}

function Get-UserMailbox
{
	param(
		[Parameter(Mandatory=$true, Position=1)][string]$Identity)

	Set-ExchangeScopeToForest
	$exceptionFile = 'Modules\RI-Exchange\Get-UserMailbox-exceptions.txt'
	$exceptionPath = Get-RIPowershellResourcesPath -ChildPath $exceptionFile
	$exceptionList = Get-Content -Path $exceptionPath
	$mailboxList = Get-Mailbox -Identity $Identity
	$mailboxList = $mailboxList | Where-Object {$exceptionList -notcontains $_.SamAccountName}

	return $mailboxList
}

<#
.SYNOPSIS
Hides mailboxes for all disabled user accounts.

.DESCRIPTION
Hides Exchange mailboxes for all disabled user accounts in Active Directory.
#>
function Hide-DisabledMailboxes
{
	$mailboxList = Get-DisabledMailboxes

	foreach ($mailbox in $mailboxList)
	{
		$mailbox | Set-Mailbox -HiddenFromAddressListsEnabled $true
	}
}

<#
.SYNOPSIS
Imports an Exchange Online PowerShell session.

.DESCRIPTION
Imports an Exchange Online PowerShell session using specified credentials.

.PARAMETER Credential
Credentials to use for the session.
#>
function Import-ExchangeOnlinePSSession
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][PSCredential]$Credential)

	$configurationName = 'Microsoft.Exchange'
	$connectionURI = 'https://outlook.office365.com/powershell-liveid/'

	$session = New-PSSession `
		-ConfigurationName $configurationName `
		-ConnectionUri $connectionURI `
		-Credential $Credential `
		-Authentication Basic `
		-AllowRedirection
	Import-PSSession $session
	Write-Warning -Message 'Use Get-PSSession and Remove-PSSession cmdlets to disconnect from this imported session.'
}

<#
.SYNOPSIS
Updates the antispam transport rules in Exchange.

.DESCRIPTION
Updates the local part and display name antispam transports rules in Exchange Server.
#>
function Update-AntispamTransportRules
{
	param(
		[string[]]$Exclude)

	$displayNameRule = 'Antispam - Display Name'
	$domainNameRule = 'Antispam - Domain Name'
	$localPartRule = 'Antispam - Local Part'
	
	Set-ExchangeScopeToForest
	$displayNameList = Get-MailboxDisplayName -Identity *
	$domainNameList = (Get-AcceptedDomain).DomainName.domain
	$localPartList = Get-MailboxLocalParts -Identity *
	New-AntispamTransportRule -Name $displayNameRule -WordList $displayNameList
	New-AntispamTransportRule -Name $domainNameRule -WordList $domainNameList
	New-AntispamTransportRule -Name $localPartRule -WordList $localPartList
}

function New-AntispamTransportRule
{
	param(
		[Parameter(Mandatory=$true)][string]$Name,
		[Parameter(Mandatory=$true)][string[]]$WordList)

	$subjectPrefix = 'Potential Spam (Delete): '
	$ruleExists = Get-TransportRule -Identity $Name -ErrorAction SilentlyContinue

	if ($ruleExists)
	{
		Remove-TransportRule -Identity $Name -Confirm:$false
	}

	New-TransportRule `
		-Name $Name `
		-Enabled $true `
		-FromScope NotInOrganization `
		-Mode Enforce `
		-PrependSubject $subjectPrefix `
		-SenderAddressLocation HeaderOrEnvelope `
		-FromAddressContainsWords $WordList
}

<#
.SYNOPSIS
Sets the Exchange PowerShell session scope to forest.

.DESCRIPTION
Sets the Exchange PowerShell session scope to include all domains in a forest.
#>
function Set-ExchangeScopeToForest
{
	Set-AdServerSettings -ViewEntireForest $true
}

function Grant-ExchangePublicFolderExternalAccess
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$Identity)

	Get-PublicFolder -Identity $Identity |Add-PublicFolderClientPermission -User Anonymous -AccessRights CreateItems
}

function Remove-ExchangeMessagesByQuery
{
	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$Query)

	#Exchange 2013
	$removalList = Get-Mailbox -Identity $Identity | `
		Search-Mailbox -SearchQuery $Query -DeleteContent -Force
	$removalList | Where-Object {$_.resultItemsCount -gt 0} | Select-Object identity,resultItemsCount
}

<#
.SYNOPSIS
Removes emails from an email address.

.DESCRIPTION
Removes emails from a specified email address.

.PARAMETER Identity
Identity of mailboxes to search.

.PARAMETER From
Email address of the sender.

.PARAMETER Date
Date to check for messages. The date must be of the format MM/DD/YYYY as per Windows Query Language. To specify a range, place .. between the dates as below:

31/10/2018..25/12/2018

.EXAMPLE
Remove-ExchangeMessagesFrom -Identity * -From foo@bar.com -Date 30/08/2020
#>
function Remove-ExchangeMessagesFrom
{
    [CmdletBinding()]

	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$From,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "From:$From AND Received:$Date"
	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}

<#
.SYNOPSIS
Removes emails with a given attachment.

.DESCRIPTION
Removes emails with a given attachment.

.PARAMETER Identity
Identity of mailboxes to search.

.PARAMETER FileName
Name of the attachment.

.PARAMETER Date
Date to check for messages. The date must be of the format MM/DD/YYYY as per Windows Query Language. To specify a range, place .. between the dates as below:

31/10/2018..25/12/2018

.EXAMPLE
Remove-ExchangeMessagesWithAttachment -Identity * -FileName foo.bar -Date 30/08/2020
#>
function Remove-ExchangeMessagesWithAttachment
{
    [CmdletBinding()]

	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$FileName,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "Attachment:$FileName AND Received:$Date"
	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}

<#
.SYNOPSIS
Removes emails with a given subject.

.DESCRIPTION
Removes emails with a given subject.

.PARAMETER Identity
Identity of mailboxes to search.

.PARAMETER Subject
Subject of the email.

.PARAMETER Date
Date to check for messages. The date must be of the format MM/DD/YYYY as per Windows Query Language. To specify a range, place .. between the dates as below:

31/10/2018..25/12/2018

.EXAMPLE
Remove-ExchangeMessagesWithSubject -Identity * -Subject "Foo Bar" -Date 30/08/2020
#>
function Remove-ExchangeMessagesWithSubject
{
    [CmdletBinding()]

	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$Subject,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "Subject:$Subject AND Received:$Date"
	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}