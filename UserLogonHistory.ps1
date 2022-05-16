#UserLogonHistory
#Run on the logon server
#Set the user you want to check in $checkuser and $checkuserlog variables
#Set the number of days in the logs to check in the $startDate variable


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}



# a username, whose logon history you want to view
$checkuserlog = 'blong'
$checkuser ='*blong*'

$LogLocation = "D:\Data\Scripts\Logs\$checkuserlog-LogOnHistory.log"
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Scanning $checkuser Log On History"

# getting information about the user logon history for the last 2 days (you can change this value)
$startDate = (get-date).AddDays(-2)
$DCs = Get-ADDomainController -Filter *
foreach ($DC in $DCs)
{
$logonevents = Get-Eventlog -LogName Security -InstanceID 4624 -after $startDate -ComputerName $dc.HostName
    foreach ($event in $logonevents){
        
        $DCName = $dc.name
        $username = $event.ReplacementStrings[5]
        $LoginType = $event.ReplacementStrings[8]
        $EventTime = $event.TimeGenerated
        $workstation = $event.ReplacementStrings[11]
        $IPAddress = $event.ReplacementStrings[18]

        if (($username -notlike '*$') -and ($username -like $checkuser)) 
        {
            # Remote (Logon Type 10)
            if ($LoginType -eq 10)
            {
            write-Log "Type 10: Remote Logon Date: $EventTime Status: Success User: $username Workstation: $workstation IP Address: $IPAddress DC Name: $dcName"
            }
            # Network(Logon Type 3)
            if ($LoginType -eq 3)
            {
            write-Log "Type 3: Network Logon Date: $EventTime Status: Success User: $username Workstation: $workstation IP Address: $IPAddress DC Name: $dcName"
            }
        }
    }
}