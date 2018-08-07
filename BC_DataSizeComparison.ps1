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

$date = Get-Date
$currentMonth = $date.Month
$currentYear = $date.Year
$prevMonth = (Get-Date).AddMonths(-1)
$prevMonth = $prevMonth.Month
#$prevMonth = 12
If ($prevMonth -eq 12)
{
    $prevYear = (Get-Date).AddYears(-1)
    $prevYear = $prevYear.Year
}
else {
    $prevYear = $currentYear
}

If ($currentMonth -le 10)
{
    $currentMonth = "0$currentMonth"
}

If ($prevMonth -le 10)
{
    $prevMonth = "0$prevMonth"
}


write-Log "This is the current month $currentMonth"
write-Log "This is the previous month $prevMonth"
write-Log "This is the current year $currentYear"
write-Log "This is the previous year $prevYear"

set $bcApp="C:\Program Files\Beyond Compare 4\BCompare.exe"
Write-Log "BCSS Data Size Comparison Ends"