#Get Server Config Information
<#
.SYNOPSIS
This script returns server configuration information.

.DESCRIPTION
This script returns the following: User information from AD, computer information from AD, DHCP information and a backup of DHCP, and a backup of the DNS configuration.

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\ADInfo.log
.PARAMETER OutPut Location
The location of the CSV file with data
IE. F:\Data\Scripts\Powershell\LOGS
.PARAMETER ADUserFileName
The name of the ADUSER information file
IE.'ADUserInfo.csv'
.PARAMETER ADComputerFileName
The name of the ADComputer information file
IE.'ADComputerInfo.csv'
.PARAMETER DHCPFileName
The name of the DHCP information file
IE.'DHCPInfo.csv'
.PARAMETER SchedTaskFolderPath
The location of where the Scheduled Tasks are saved.
IE.F:\Data\Scripts\Powershell\Logs\SchedTasks'

#>


param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADUser Info File')][string]$ADUserFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADComputer Info File')][string]$ADComputerFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of DHCP Info File')][string]$DHCPFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of Scheduled Task Info File')][string]$SchedTaskFolderPath
    )
<#
.SYNOPSIS
Writes to a log.
.Description
Creates a new log file in the designated location.
.PARAMETER logstring
String of text
#>
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

#Powershell Console
#.\ServerConfigInfo.ps1 'F:\Data\Scripts\Powershell\LOGS\ADInfo.log' 'F:\Data\Scripts\Powershell\Logs' 'ADUserInfo.csv' 'ADComputerInfo.csv' 'DHCPInfo.csv' 'F:\Data\Scripts\Powershell\Logs\SchedTasks'
'F:\Data\Scripts\Powershell\LOGS\ADInfo.log' 
'F:\Data\Scripts\Powershell\Logs' 
'ADUserInfo.csv'
'ADComputerInfo.csv'
'DHCPInfo.csv'
'F:\Data\Scripts\Powershell\Logs\SchedTasks'


$ADUserFile = $OutPutFilePath + "\" + $ADUserFileName
#Get the domain we are in 
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"
$DNSZone = $userdomain.DNSRoot

$ADUserFile = $OutPutFilePath + "\" + $ADUserFileName
$ADComputerFile = $OutPutFilePath + "\" + $ADComputerFileName
$DHCPFile = $OutPutFilePath + "\" + $DHCPFileName

$OutPathFileExists = Test-Path -path $OutPutFilePath
if ( $OutPathFileExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $OutPutFilePath
}

$SchedPathExists = Test-Path -path $SchedTaskFolderPath
if ( $SchedPathExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $SchedTaskFolderPath
}
$ServerName = get-content env:computername
$DNSDomain = get-content env:userdnsdomain
$FullServerName = $Servername + '.' + $DNSDomain
$PDCInfo = Get-ADDomainController -Discover -Service "PrimaryDC"
$PDCName = $PDCInfo.name

#check to see if you are on the PDC then get the AD stuff
If ($ServerName -eq $PDCName)
#Get the Active Directory User information and put into a csv file
{
Write-Log "Getting User Information from Active Directory"
Get-ADUser -Filter * -SearchBase $domain -ResultPageSize 0 -Property samaccountname,Surname,GivenName,enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,lastLogonTimestamp | Select-Object SAMAccountname,Surname,GivenName,Enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,@{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} | Export-CSV -NoType $ADUserFile
Write-Log "Completed User Information from Active Directory"
#Get the Active Driectory Computer Information and put it into a csv File
Write-Log "Getting Computer Information from Active Directory"
Get-ADComputer -Filter * -SearchBase $domain -ResultPageSize 0 -Property CN,DistinguishedName,IPv4Address,PasswordLastSet,Operatingsystem,OperatingsystemVersion | Select-Object CN,DistinguishedName,IPv4Address,PasswordLastSet,OperatingSystem,OperatingSystemVersion | Export-CSV -NoType $ADComputerFile
Write-Log "Completed Computer Information from Active Directory"
}

#all other servers check for DHCP DNS Scheduled Tasks
$DHCPService = Get-Service -Name DHCPServer
$DHCPRunning = $DHCPService.Status

If ($DHCPRunning -eq "Running")
{
#Get the DHCP servername
$DHCPScopeInfo = Get-DHCPServerv4Scope -ComputerName $ServerName
$DHCPScopeID = $DHCPScopeInfo.ScopeID
#Get DHCP Information and put it into a csv File
Write-Log "Getting DHCP Information"
Get-DhcpServerv4Lease -ComputerName $ServerName -ScopeId $DHCPScopeID | Export-CSV -NoType $DHCPFile
Write-Log "Completed DHCP Information"
#Backup DHCP Database
Write-Log "Getting backup of DHCP Database"
$DHCPDBBackup = $OutPutFilePath + "\DHCP_DB_Backup"
Backup-DhcpServer -ComputerName $ServerName -Path $DHCPDBBackup
Write-Log "Completed backup of DHCP Database"
}
#Get Scheduled Tasks
Write-Log "Getting Scheduled Task Information"
$Tasks = Get-ScheduledTask -TaskPath \ | Select-Object TaskName 
    foreach($Task in $Tasks){ 
        $TaskName = $Task.TaskName 
        Export-ScheduledTask -TaskName $TaskName | Out-File "$SchedTaskFolderPath\$TaskName.xml" -Force 
    }
Write-Log "Completed Scheduled Task Information"

#Get DNS Information
$DNSService = Get-Service -Name DNS
$DNSRunning = $DNSService.Status

If ($DNSRunning -eq "Running")
{
#Get DNS backup
Write-Log "Getting DNS Backup"
$DNSBackup = $OutPutFilePath + "\DNS_ServerConfig.xml"
    Get-DNSServer | Export-Clixml -Path $DNSBackup
Write-Log "Completed DNS Backup"
}