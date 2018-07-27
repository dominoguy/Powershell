# BC_DataSizeComparison Ver 1.0

<#
.SYNOPSIS
Runs a Beyond Compare report on the changes between the last BCSS and the current data set for each client server


.DESCRIPTION


.PARAMETER ServerList
Location of the list of client server directories in csv format
IE. F:\Data\Scripts\Powershell\RIMonthly\serverslist.csv

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\BC_Comparison.log
#>

param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage='Location of CSV ServerList')][string]$ServerList,
        [Parameter(Mandatory=$true,Position=2,HelpMessage='Location of Log file')][string]$LogLocation
    )

<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logdatetime
datetime of text
#>
function Write-Log
{
    Param(
        [String]$logdatetime)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logdatetime"
}

function Get-Month () 
{
    $value = "" | Select-Object -Property curMonth,curYear,prevMonth,prevYear
    $date = Get-Date
    $currentMonth = $date.Month
    $currentYear = $date.Year
    $prevMonth = $currentMonth-1

    write-Log "This is the previous month inside the function $prevMonth"

    If ($prevMonth = 0)
    {
        $prevMonth = 12
        $prevYear = $currentYear-1
    }
    else
    {
    $prevYear = $currentYear
    }
    $value.curMonth =$currentMonth
    $value.curYear = $currentYear
    $value.prevMonth = $prevMonth
    $value.prevYear = $prevYear
    Return $value
}


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

Write-Log "BCSS Data Size Comparison Begins"


#$date = Get-Date
$month = Get-Month

write-Log "This is the previous month $($month.prevMonth)"

Write-Log "BCSS Data Size Comparison Ends"