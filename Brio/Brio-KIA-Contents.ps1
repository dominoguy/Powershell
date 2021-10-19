#Brio-KIA-Contents
#Version 1.0 
#03Sept2021-Brian Long

<#
.SYNOPSIS
Copies data from KIA files into CSV, to find build information

.DESCRIPTION
This script goes through each file in KIA file directory and reads the file. It will then parse the first line in the file to get the build information
and place the information into a csv file. Column one is file name, column two is data

.PARAMETER LogLocation
Location of script log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\BackupRename.log
.PARAMETER FileLocation
The location of the KIA files
IE. 'F:\Data\Scripts\Powershell\BRIO\Files'
#>
<#
param(
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of Log FIle')][string]$LogLocation,
        [Parameter(Mandatory=$False,Position=2,HelpMessage='Location of list of servers')][string]$FileLocation
    )
#>
#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = "F:\Data\Scripts\Powershell\Logs\Brio-KIA.log"
$FileLocation = "F:\Data\Scripts\Powershell\BRIO\Files"
$ResultsCSV = "F:\Data\Scripts\Powershell\BRIO\KIA-Files.csv"

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


Write-Log "GetKIA Begins"


$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"FileData","FilePath"'
if ( $ResultsExists -eq $True)
{
    Remove-Item $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}
else
{
    #New-Item -ItemType File -Force -Path $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}


$Files = Get-ChildItem -Path $FileLocation -Recurse -Force
foreach ($File in $Files)
{
    Write-Log $File.Fullname
    Write-Log $File.Name
    $FullPath = $File.FullName

    $FileData = (Get-Content -Path $FullPath -TotalCount 3)
    Write-Log $fileData

    Get-Content -Path $ResultsCSV
    $Results = [PSCustomObject]@{
        FileData = "$FileData"
        FilePath = "$FullPath"
    }
    
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation

}

Write-Log "GetKIA Ends"

