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
	$resourcesPath = Get-RIPowershellResourcesPath
	$exceptionPath = Join-Path -Path $resourcesPath -ChildPath $exceptionFile
	$exceptionList = Get-Content -Path $exceptionPath

	$mailboxList = Get-Mailbox -Identity $Identity
	$mailboxList = $mailboxList | Where-Object {$exceptionList -notcontains $_.SamAccountName}

	return $mailboxList
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

	Write-Host "`nWARNING: Use Get-PSSession and Remove-PSSession cmdlets to disconnect from this imported session." `
		-ForegroundColor Yellow
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

	Set-ExchangeScopeToForest

	$displayNameList = Get-MailboxDisplayName -Identity *
	$displayNameRule = 'Antispam - Display Name'
	$domainNameList = (Get-AcceptedDomain).DomainName.domain
	$domainNameRule = 'Antispam - Domain Name'
	$localPartList = Get-MailboxLocalParts -Identity *
	$localPartRule = 'Antispam - Local Part'

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

function Remove-ExchangeMessagesFrom
{
	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$From,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "From:$From AND Received:$Date"

	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}

function Remove-ExchangeMessagesWithAttachment
{
	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$FileName,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "Attachment:$FileName AND Received:$Date"

	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}

function Remove-ExchangeMessagesWithSubject
{
	param(
	    [Parameter(Mandatory=$true)][string]$Identity,
	    [Parameter(Mandatory=$true)][string]$Subject,
	    [Parameter(Mandatory=$true)][string]$Date)

	$query = "Subject:$Subject AND Received:$Date"

	Remove-ExchangeMessagesByQuery -Identity $Identity -Query $query
}