#CompareUserLists
#Version 1.0
#This script will:
#1) Compare two user lists and resolve into one list no duplicates

#Run from the same directory as the lists

param(
        [Parameter(Mandatory=$true,HelpMessage='Name of List 1')][string]$List1,
        [Parameter(Mandatory=$true,HelpMessage='Name of List 2')][string]$List2,
        [Parameter(Mandatory=$true,HelpMessage='Name of Output File')][string]$NameofResultsFIle
)


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$logFile = "F:\Data\Scripts\Powershell\CompareUsersLists\CompareUserLists.log"
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

#$list1 = "SCF Managers Distribution-Members.csv"
#$list2 = "SCF Quality_BPC-Members.csv"
#$NameofResultsFIle = "ComparisonResults.csv"

#List1
$Users1 = import-csv -path "$PSScriptRoot\$List1"
#List2
$Users2 = import-csv -path "$PSScriptRoot\$List2"

#CSV file list of users in AD file but not in Active Employee file
$CompareResults = "$PSScriptRoot\$NameofResultsFIle"


$CompareResultsExists = Test-Path -path $CompareResults
$Headers = '"Members"'
if ( $CompareResultsExists -eq $True)
{
    Remove-Item $CompareResults
    New-Item -ItemType File -Force -Path $CompareResults
    Add-Content -Path $CompareResults -Value $Headers
}
else
{
    New-Item -ItemType File -Force -Path $CompareResults
    Add-Content -Path $CompareResults -Value $Headers
}

$CombinedUsersUnique = $Users1.Members + $Users2.Members | Select-Object -Unique | Sort-Object

ForEach ($User in $CombinedUsersUnique)
{
    $Results = [PSCustomObject]@{
        Members = "$User"
    } 
    $Results | Export-Csv -Path $CompareResults -Append -NoTypeInformation
}
