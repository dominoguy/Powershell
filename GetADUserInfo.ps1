#Get Active Directory User Information
<#
.SYNOPSIS
This script returns Active Directory Users information and last logon time and exports to a CSV file.

.DESCRIPTION
This script removes the date from the file name and copies the file to a designated directory for backup.
The script will keep 30 days of the vendors backups and deleting anything older.
There should NOT be any other files in this directory than the backup files.
Backup scripts should excempt the vendors backup directory from the client backup.

Sample file name:
    Back_Office_Database_2018-09-04--03-00-12.7z

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
.PARAMETER SchedTaskFileName
The name of the Scheduled Tasks information file
IE.'SchedTaskInfo.csv'

#>


param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADUser Info File')][string]$ADUserFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADComputer Info File')][string]$ADComputerFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of DHCP Info File')][string]$DHCPFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of Scheduled Task Info File')][string]$SchedTaskFileName
    )
<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logstring
String of text
#>
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
#.\ServerConfigInfo.ps1 'F:\Data\Scripts\Powershell\LOGS\ADInfo.log' 'F:\Data\Scripts\Powershell\Logs' 'ADUserInfo.csv' 'ADComputerInfo.csv' 'DHCPInfo.csv' 'SchedTaskInfo.csv'
'F:\Data\Scripts\Powershell\LOGS\ADInfo.log' 
'F:\Data\Scripts\Powershell\Logs' 
'ADUserInfo.csv'
'ADComputerInfo.csv'
'DHCPInfo.csv'
'SchedTaskInfo.csv'

$ADUserFile = $OutPutFilePath + "\" + $ADUserFileName
#Get the domain we are in 
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"
#Get the DHCP servername
$DHCPServerInfo = Get-DhcpServerInDC
$DHCPServer = $DHCPServerInfo.DNSName
$DHCPScopeInfo = Get-DHCPServerv4Scope -ComputerName $DHCPServer
$DHCPScopeID = $DHCPScopeInfo.ScopeID

$ADUserFile = $OutPutFilePath + "\" + $ADUserFileName
$ADComputerFile = $OutPutFilePath + "\" + $ADComputerFileName
$DHCPFile = $OutPutFilePath + "\" + $DHCPFileName
$SchedTaskFile = $OutPutFilePath + "\" + $SchedTaskFileName

#Get the Active Directory User information and put into a csv file
Write-Log "Getting User Information from Active Directory"
Get-ADUser -Filter * -SearchBase $domain -ResultPageSize 0 -Property samaccountname,Surname,GivenName,enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,lastLogonTimestamp | Select SAMAccountname,Surname,GivenName,Enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,@{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} | Export-CSV -NoType $ADUserFile
Write-Log "Completed User Information from Active Directory"
#Get the Active Driectory Computer Information and put it into a csv File
Write-Log "Getting Computer Information from Active Directory"
Get-ADComputer -Filter * -SearchBase $domain -ResultPageSize 0 -Property CN,DistinguishedName,IPv4Address,PasswordLastSet,Operatingsystem,OperatingsystemVersion | Select CN,DistinguishedName,IPv4Address,PasswordLastSet,OperatingSystem,OperatingSystemVersion | Export-CSV -NoType $ADComputerFile
Write-Log "Completed Computer Information from Active Directory"
#Get DHCP Information and put it into a csv File
Write-Log "Getting DHCP Information"
Get-DhcpServerv4Lease -ComputerName $DHCPServer -ScopeId $DHCPScopeID | Export-CSV -NoType $DHCPFile
Write-Log "Completed DHCP Information"
#Get Scheduled Tasks
Write-Log "Getting Scheduled Task Information"
Get-ScheduledTask -Taskpath * | Export-ScheduledTask
Write-Log "Completed Scheduled Task Information"
#GET backups of AD, DNS and DHCP