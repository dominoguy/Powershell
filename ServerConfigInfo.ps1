#Get Server Config Information
<#
.SYNOPSIS
This script returns server configuration information.

.DESCRIPTION
This script returns the following: User information from AD, computer information from AD, DHCP information and a backup of DHCP, and a backup of the DNS configuration.


.PARAMETER OutPutLocation
The local save location of data
IE. F:\Data\Scripts\Powershell\Logs\ServerConfig
.PARAMETER RemoteSave
The remote save location of data. Must be in an UNC Path
IE. \\RI-FS-001.ri.ads\d$\data\Scripts\Logs\ServerConfig
#>


param(
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath,
        [Parameter(Mandatory=$False,HelpMessage='Remote Save Location, must be in an UNC path')][string]$RemoteSave
    )
<#
.SYNOPSIS
Writes to a log.
.Description
Creates a new log file in the designated location.
.PARAMETER logstring
String of text
#>

$ServerName = get-content env:computername
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}
$LogLocation = $OutPutFilePath + "\" + $ServerName + "\" + 'ServerConfig.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

#Powershell Console
#.\ServerConfigInfo.ps1 'F:\Data\Scripts\Powershell\Logs' '\\RI-FS-001.ri.ads\D$\Data\Scripts\Logs'

$SaveLocation = $OutPutFilePath + "\" + $ServerName
$ADUserFile = $SaveLocation + "\" + 'ADUserInfo.csv'
$ADComputerFile = $SaveLocation + "\" + '\ADComputerInfo.csv'
$DHCPFile = $SaveLocation + "\" + 'DHCPInfo.csv'
$DHCPDBBackup = $SaveLocation + "\" + "\DHCP_DB_Backup"
$SchedTaskFolderPath =  $SaveLocation + "\" + 'SchedTasks'
$DNSBackup = $SaveLocation + "\" + "DNS_ServerConfig.xml"

Write-Log 'Starting ServerConfig'

#Get the domain we are in 
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"

#Local Save
$OutPathFileExists = Test-Path -path $OutPutFilePath
if ( $OutPathFileExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $OutPutFilePath
}

$SchedPathExists = Test-Path -path $SchedTaskFolderPath
if ($SchedPathExists -eq $False)
{
 New-Item -ItemType Directory -Force -Path $SchedTaskFolderPath
}

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

#Get DHCP if available
If (Get-Service -Name DHCPServer -ErrorAction SilentlyContinue)
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

#Get DNS Information if available
If (Get-Service -Name DNS -ErrorAction SilentlyContinue)
{
#Get DNS backup
Write-Log "Getting DNS Backup"
    Get-DNSServer | Export-Clixml -Path $DNSBackup
Write-Log "Completed DNS Backup"
}

#Remote Save
If ($RemoteSave -eq "" -or $RemoteSave -eq $null)
{
    Write-Log "Not Saving remotely"
}
else 
{
    Write-Log "Saving remotely"
    #Test Conection to target server
    $RemoteServer = [regex]::match($RemoteSave,'^\\\\(.*?)\\').Groups[1].Value
    If (Test-connection -Cn $RemoteServer -BufferSize 16 -count 1 -ea 0 -quiet)
    {
        Write-Log "Copying to remote save location"
        $RemoteSavePathExists = Test-Path -path $RemoteServer
        if ($RemoteSavePathExists -eq $False)
        {
            New-Item -ItemType Directory -Force -Path $RemoteSave
        }
        Copy-Item -Path $SaveLocation -Destination $RemoteSave -Recurse -Force
    }
    else 
    {
        Write-Log "Target Server is not available"
    }
}

Write-Log 'Finished ServerConfig'