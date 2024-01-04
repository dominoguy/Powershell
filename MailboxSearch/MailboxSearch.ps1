#MailboxSearch
#This script searchs mailbox(es) in Exchange based on Keywords


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = "$PSScriptRoot\Logs\MailboxSearch-$curdate.log"
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

Write-Log "Start Mailbox Search"
#Get the mailboxes to search
$MailBoxList = Import-csv -Path "$PSScriptRoot\Mailboxes.csv"
#Get the list of keywords to search the mailbox
$KeywordList = Import-csv -Path "$PSScriptRoot\Keywords.csv"
#Format the list into a string for the query
$StringList = "'"
ForEach($Keyword in $KeywordList)
{
    If($StringList -ne "")
    {
        $StringList = $StringList + " OR "
    }
    $StringList = $StringList + '"' + $Keyword.Keyword + '"'
}
$StringList = $StringList + "'"

Write-Log $StringList

#Search-Mailbox  -Identity "Jennifer Burns" -SearchQuery $StringList -TargetMailbox "Discovery Search Mailbox" -TargetFolder "Jennifer Burns" -LogLevel Full
ForEach($Mailbox in $MailboxList)
{
    $Mailbox = $Mailbox.Mailbox
    Write-Log $Mailbox
    Search-Mailbox  -Identity $MailBox -SearchQuery $StringList -TargetMailbox "Discovery Search Mailbox" -TargetFolder $Mailbox -LogLevel Full
}
Write-Log "End Mailbox Search"