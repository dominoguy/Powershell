#MailboxSearch
#Brian Long
#Verison 1.0
#This script searchs mailbox(es) in Exchange based on To and From Fields and Keywords
#Required: 
#The Discovery Search Mailbox needs to be setup.
#SearchVariables.csv, Columns = To, From, Keyword
#Mailboxes.csv, Columns = Mailbox
#CSVs need to be in the same folder as MailboxSearch.ps1
#Log folder, located in the same folder as MailboxSearch.ps1

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
#Get the list of SearchQuery Variables to search the mailbox
$SearchVarCSV = Import-csv -Path "$PSScriptRoot\SearchVariables.csv"

#Build the variables for the query
ForEach($Key in $SearchVarCSV)
{
    $ToEntry = $Key.To
    If(-Not [String]::IsNullOrWhiteSpace($ToEntry))
    {
        IF($null -NE $ToString)
        {
            $ToString = $ToString + " OR " + '"' + $ToEntry + '"'
        }
        else {
            $ToString = "TO:" + '"' + $ToEntry + '"'
        }
    }

    $FromEntry = $Key.From
    If(-Not [String]::IsNullOrWhiteSpace($FromEntry))
    {
        IF($null -NE $FromString)
        {
            $FromString = $FromString + " OR " + '"' + $FromEntry + '"'
        }
        else {
            $FromString = "From:" + '"' + $FromEntry + '"'
        }
    }
    
    $KeyEntry = $Key.Keyword
    If(-Not [String]::IsNullOrWhiteSpace($KeyEntry))
    {
        IF($null -NE $KeyString)
        {
            $KeyString = $KeyString + " OR " + '"' + $KeyEntry + '"'
        }
        else {
            $KeyString = '"' + $KeyEntry + '"'
        }
    }
}

#Build -SearchQuery string
If (-Not [String]::IsNullOrWhiteSpace($FromString))
{
    If(-Not [String]::IsNullOrWhiteSpace($ToString))
    {
    $FromString = " AND " + $FromString
    }
}

If (-Not [String]::IsNullOrWhiteSpace($KeyString))
{
    If(-Not [String]::IsNullOrWhiteSpace($ToString) -or -Not [String]::IsNullOrWhiteSpace($FromString))
    {
    $KeyString = " AND " + $KeyString
    }
}

$SearchQuery = $ToString + $FromString + $KeyString
Write-Log "The -SearchQuery string is:  $SearchQuery"

#if Mailboxboxes.csv is blank then default is search all mailboxes

$TargetMailBox = "Discovery Search Mailbox"
ForEach($Row in $MailboxList)
{
    $Mailbox = $Row.Mailbox
    Write-Log "Searching the mailbox of:  $Mailbox"
    Write-Host "Searching the mailbox of:  $Mailbox"
    #Search-Mailbox  -Identity $Mailbox -SearchQuery 'From:"ManiKadiyala@altec-inc.com" OR "eleson@SHEPHERDSCARE.org" AND "doclink" OR "prereqs" OR "Foodservices"' -TargetMailbox "$TargetMailBox" -TargetFolder $Mailbox -LogLevel Full
    Search-Mailbox  -Identity $Mailbox -SearchQuery "$SearchQuery" -TargetMailbox "$TargetMailBox" -TargetFolder $Mailbox -LogLevel Full
}
Write-Host "End Mailbox Search"
Write-Log "End Mailbox Search"