#Number of Files and Size of Directory
<#
.SYNOPSIS
This script will calculate the number of files and the size of directories

.DESCRIPTION
The script will access a list of directories to work on from a .csv file. 
It will then calculate the number of files per directory and keep a subtotal for a final total of directories in the list.
Next it will calculate the size of the directories and convert to GB, it will total sub directories and give a final total
DirectoryCount.ps1 -LogLocation 'F:\Data\Scripts\Powershell\LOGS\DirectoryCount.log' -DirectoryList 'F:\Data\Scripts\Powershell\DirectoryList.csv'

.PARAMETER LogLocation
Location of script log file and its name
IE. 'F:\Data\Scripts\Powershell\LOGS\DirectoryCount.log'
.PARAMETER DirectoryList
This is the CSV file list of directories to be enumerated
IE. 'F:\Data\Scripts\Powershell\DirectoryList.csv'
#>

param(
        [Parameter(Mandatory=$true,HelpMessage='Path of the location of Log file')][string]$LogLocation,
        [Parameter(Mandatory=$true,HelpMessage='Path of the list of Directories file')][string]$DirectoryList
    )

#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#$logFile = 'F:\Data\Scripts\Powershell\LOGS\DirectoryCount.log'
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

#Directory Emuneration
Write-Log "Directory Count Begins"
Write-Log "********************"

#$DirListLocation = 'F:\Data\Scripts\Powershell\DirectoryList.csv'
$DirListLocation = $DirectoryList

$list = Import-Csv $DirListLocation

[long]$totalSize = 0

foreach ($row in $list)
{
    #Get a list of directories to count
    $DirPath = $row.DirPath
    $folderExists = Test-Path $DirPath
    if ($folderExists -eq $True) 
    {
        Write-Log "Starting $dirPath"
       [long]$dirSize = 0
       Get-ChildItem -Path $DirPath -File -Recurse -Force -ErrorAction SilentlyContinue | %{$dirSize += $_.Length}
       $SizeinGB = [Math]::Round($dirSize/1GB,2)
       Write-log  "         $dirPath is $SizeinGB GB"
       [long]$fileCount = 0
       Get-ChildItem -Path $DirPath -Recurse -File | Measure-Object | %{$fileCount += $_.Count}
       Write-log  "         $dirPath has $fileCount files"
       Write-Log "Finished $dirPath"
       Write-Log "********************"
    }
    else {Write-Log "$dirPath is not available *****"}
    $totalsize = $totalsize + $dirSize
    $TotalsizeinGB = [Math]::Round($totalsize/1GB,2)
    $totalFile = $totalfile + $fileCount
}
Write-Log "The total size is $totalsizeinGB GB"
Write-Log "The total number of files is $totalFile"
Write-Log "********************"
Write-Log "Directory Count Ends"
