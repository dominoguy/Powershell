#Domain-IP-Check
#This script checks a file with looks for a domain name and the ip address on the same line and compares it to what is expected
#File (DomainIPCheck.csv) is in the format of comma delimited: domain,ip, IE. google.ca,142.251.33.99
#Launching script format is Domain-IP-Check.ps1 -DomainsToCheck renatus-edm.mine.nu,ri2.mine.nu
#mulitple domains can be specified, separated by a comma, entries need to be the DomainIPCheck.csv file.

param(
        [Parameter(Mandatory=$True,HelpMessage='Name of Domain')][string[]]$DomainsToCheck,
        [Parameter(Mandatory=$False,HelpMessage='File Location')][string]$File
    )
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = "F:\Data\Scripts\Github\Powershell\Domain-IP-Check\Logs\Domain-IP-Check-$curdate.log"
$logFile = $LogLocation
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Start Checking Domain has the expected IP address"

ForEach($DomainInList in $DomainsToCheck)
{
    Write-Log "Checking $DomainInList"
    #Get the current IP address of Domain to check
   Try
   { 
        $DNSName = Resolve-DnsName $DomainInList -Type A -ErrorAction Stop

        $CurIP = $DNSName.IPAddress
        $File = "F:\Data\Scripts\Github\Powershell\Domain-IP-Check\DomainIPCheck.csv"
        #Get the file to check
        $Contents = Import-csv -Path $File
        $DomainFound =$False
     ForEach($line in $Contents)
        {
            $Domain = $line.Domain
            $ExpectedIP = $line.IP
            If ($Domain -eq $DomainInList)
            {
                Write-Log ("Checking the IP Address for $Domain")
                If($ExpectedIP -eq $CurIP)
                {
                    Write-Log "Current IP matches Expected IP - $ExpectedIP for $DomainInList"
                }
                else
                {
                    Write-Log ("IP does not match for $DomainInList, current IP = $CurIP, expected IP is $ExpectedIP")
                }
                $DomainFound = $True
            }
        }
        IF ($DomainFound -eq $False)
        {
            Write-Log "There is no entry for $DomainInList in the domains file"
        }
    }
    catch 
    {
        Write-Log "No NSLookUp results for $DomainInList"
    }

}
Write-Log "End Checking Domain-IP address"