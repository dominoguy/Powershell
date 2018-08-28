# BC_DataSizeComparison Ver 1.0

<#
.SYNOPSIS
Runs a Beyond Compare report on the changes between the last BCSS and the current data set for each client server


.DESCRIPTION


.PARAMETER ServerList
Location of the list of client server directories in csv format
IE. F:\Data\Scripts\Powershell\RIMonthly\serverslist.csv
G:\Backups\RIBackup\RIMonthly\serverslist.csv

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\BC_Comparison.log
G:\Backups\RIBackup\RIMonthly\LOGS\BC_Comparison.log
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

#Create the comparison reports
$runPath = $PSScriptRoot
$bcApp="C:\Program Files\Beyond Compare 4\BCompare.exe"
$bcScptSnap = "$runPath\BCSnap.txt"
$bcCompareSize = "@$runPath\Comparesize.txt"


$list = Import-Csv $ServerList

foreach ($row in $list)
{
    $ClientDIr = $row.ClientDIr
    $Path = $ClientDIr.split("\")
    $drive = $Path[0]

    $Folder1 = $Path[1]
    $Folder2 = $Path[2]
    $dirFolder = $Path[3]
    $dirClient = $Path[4]
    $dirServer = $Path[5]
    $dirBaseline = 'Baselines'

    #$dirFolder = $Path[1]
    #$dirClient = $Path[2]
    #$dirServer = $Path[3]

    $bcssFileDir = "$drive\$folder1\$folder2\$dirBaseline\$dirClient\$dirServer"
    #$bcssFileDir = "$drive\$dirBaseline\$dirClient\$dirServer"

    $bcssFileName = "${currentMonth}_$currentYear"
    $bcssFile = "$bcssFileDir\${currentMonth}_$currentYear.bcss"
    $bcssReport = "$bcssFileDir\${currentMonth}_$currentYear"
  
    $bcssFile = "$drive\$folder1\$folder2\$dirBaseline\$dirClient\$dirServer\${currentMonth}_$currentYear.bcss"
    #$bcssFile = "$drive\$dirBaseline\$dirClient\$dirServer\${currentMonth}_$currentYear.bcss"

    write-Log "***Running the comparison for $dirserver ***"

    Start-Process $bcApp -argumentlist "$bcCompareSize $ClientDir $bcssFile $bcssFileDIr $bcssFilename" -NoNewWindow -Wait

    [xml]$XmlDocument = Get-content -Path "${bcssReport}_Report.xml"
   
#Check for free space on a drive
    [int]$driveLimit = '100000000'
    [int]$driveLimitMB = [Math]::Round('100000000'/1mb,2)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='F:'"
    Select-Object Size,FreeSapce

    $disksize = $disk.size
    $diskFree = $disk.Freespace
    $disksizeMB = [Math]::Round($disk.size/1mb,2)
    $diskFreeMB = [Math]::Round($disk.Freespace/1mb,2)

    #write-Log "The drive limit is $driveLimitMB MB"
    write-Log "Total disk size is $disksizeMB MB"
    Write-Log "Total free disk space is $diskFreeMB MB"

    $LTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.lt.name
    $LTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.lt.size
   
    $LTfolderdatasize = $LTfolderdatasize -replace '[,]',''

    $RTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.rt.name
    $RTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.rt.size

    $RTfolderdatasize = $RTfolderdatasize -replace '[,]',''

    $RawBackupSize = $LTfolderdatasize-$RTfolderdatasize
    $BackupSize = [Math]::Round($RawBackupSize/1mb,2)

    Write-Log "The backup size for $dirserver is $BackupSize MB"
    $SpaceRemain = $diskFree - $RawBackupSize
    $SpaceRemainMB = [Math]::Round($SpaceRemain/1mb,2)

    If ($SpaceRemain -gt $driveLimit)
    {
        Write-Log "There is room for the backup with $SpaceRemainMB Mb remaining"
    }
    else
    {
        Write-Log "Backup is too big. you need $SpaceRemain MB more"
    }
}







Write-Log "BCSS Data Size Comparison Ends"