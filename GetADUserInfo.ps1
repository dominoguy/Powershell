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
IE. F:\Data\Scripts\Powershell\LOGS\BackupRename.log
.PARAMETER OutPut Location
The location of the CSV file with data
IE. F:\Data\Scripts\Powershell\LOGS
.PARAMETER ADUserLogName
The name of the ADUSERLog of the renamed database
IE. ADUserInfo.log
.PARAMETER DBFileNameSearch
The part of the name of the database which will be used to find the correct file.
IE. "Act! Ace_Manufacturing*.txt"
.PARAMETER NewDBName
The new name of the database
IE. 'ACT_Backup.txt'

#>


param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADUser Info File')][string]$ADUserFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of ADComputer Info File')][string]$ADComputerFileName,
        [Parameter(Mandatory=$true,HelpMessage='Name of DHCP Info File')][string]$DHCPFileName
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

'F:\Data\Scripts\Powershell\LOGS\ADInfo.log' 
'F:\Data\Scripts\Powershell\Logs' 
'ADUserInfo.csv'
'ADComputerInfo.csv'
'DHCPInfo.csv'

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

#Get the Active Directory User information and put into a csv file
Write-Log "Getting User Information from Active Directory"
Get-ADUser -Filter * -SearchBase $domain -ResultPageSize 0 -Property samaccountname,Surname,GivenName,enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,lastLogonTimestamp | Select SAMAccountname,Surname,GivenName,Enabled,HomeDirectory,HomeDrive,ProfilePath,EmailAddress,@{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} | Export-CSV -NoType $ADUserFile

#Get the Active Driectory Computer Information and put it into a csv File
Write-Log "Getting Computer Information from Active Directory"
Get-ADComputer -Filter * -SearchBase $domain -ResultPageSize 0 -Property CN,DistinguishedName,PasswordLastSet,Operatingsystem,OperatingsystemVersion | Select CN,DistinguishedName,PasswordLastSet,OperatingSystem,OperatingSystemVersion | Export-CSV -NoType $ADComputerFile

#Get DHCP Information and put it into a csv File
Write-Log $DHCPScopeID
Get-DhcpServerv4Lease -ComputerName $DHCPServer -ScopeId $DHCPScopeID | Export-CSV -NoType $DHCPFile