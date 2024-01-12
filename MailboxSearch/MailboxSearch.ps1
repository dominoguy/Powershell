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
#Get the list of TO email
$ToList = Import-csv -Path "$PSScriptRoot\To.csv"
#Get the list of keywords to search the mailbox
$KeywordCSV = Import-csv -Path "$PSScriptRoot\Keywords.csv"
#Format the list into a string for the query

#Build the To Search Query
$ToString = ""
ForEach($To in $ToList)
{
    $ToEntry = $To.to
    If($ToString -NE "")
    {
        $ToString = $ToString + " OR "
    }
    
    $ToString = $ToString + 'To:"' + $ToEntry + '"'
}
Write-Log "The To list is: $ToString"

#If($ToString -NE "")
#{
#    $ToString = $ToString + " And "
#}

#Build the Keyword String list
$KeyString = ""
ForEach($Key in $KeywordCSV)
{
    $KeyEntry = $Key.keyword
    If($KeyString -NE "")
    {
        $KeyString = $KeyString + " OR "
    }
    
    $KeyString = $KeyString + '"' + $KeyEntry + '"'
}
Write-Log "The KeyString List is: $KeyString"

$StringList = $ToString + $KeyString

#-SearchQuery needs to be quotes if there are mutltiple search criteria
$StringList = "'" + $StringList + "'"

Write-Log "The -SearchQuery string is:  $StringList"
#Search-Mailbox  -Identity "Jennifer Burns" -SearchQuery 'to:tmitchell or to:"slt@shepherdscare.org" And "LGBTQ" OR "Pride Month"' -TargetMailbox "Discovery Search Mailbox" -TargetFolder "Jennifer Burns" -LogLevel Full

ForEach($Row in $MailboxList)
{
    $Mailbox = $Row.Mailbox
    Write-Log "Searching the mailbox of:  $Mailbox"
    #$Mailbox = """$Mailbox"""
    #Write-Host ""Search-Mailbox  -Identity $MailBox -SearchQuery $StringList -TargetMailbox "Discovery Search Mailbox" -TargetFolder $Mailbox -LogLevel Full""
    #Search-Mailbox  -Identity $MailBox -SearchQuery $StringList -TargetMailbox "Discovery Search Mailbox" -TargetFolder $Mailbox -LogLevel Full
    Search-Mailbox  -Identity $MailBox -SearchQuery "$ToString And $Keystring" -TargetMailbox "Discovery Search Mailbox" -TargetFolder $Mailbox -LogLevel Full
}
Write-Log "End Mailbox Search"