#BuildExcludeFile



#Functions
function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


$LogLocation = "F:\Data\Scripts\Powershell\ManualBackups\Logs\ExcludeFile.log"

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

<#
1) create a default exclusion list for each server with a complete list of first level dirs after data - hand build
2) script reads redirect log and goes through each line and stores as variable dir name - text that precedes "/"
3) compare dirname to exclusion list dirs and see if it is a match
4) if so then store in a variable
5) do this until end of redirect log
6) then create an exclusion list based on default, add each line until you reach the value in the variable, dont add it or anything after
7) save the exclusion list

#>

Write-Log "Creating Exclude File"
#Create blank exclude file for server
#If file already exists delete it.
$ExcludeFilePath = "F:\Data\Scripts\Powershell\ManualBackups\Exclude-Manual-ODC-FS-001.txt"
$ExcludeFileExists= Test-Path -path $ExcludeFilePath
If ($ExcludeFileExists -eq $True)
{
    Remove-Item $ExcludeFilePath
    New-Item -ItemType File -Force -Path $ExcludeFilePath
}
else
{
    New-Item -ItemType File -Force -Path $ExcludeFilePath
}
#Get Default exclude folder list
$ExcludeFIleDefaultsPath = "F:\Data\Scripts\Powershell\ManualBackups\ExcludeFilter-Defaults.Txt"
#Add the defaults to the list
Get-Content -Path $ExcludeFIleDefaultsPath | Add-Content -Path $ExcludeFilePath
#read past incremental backup log file, log which directories backups have completed and find which directory it stopped on
#Incremental logs are delimited by fixed width columns
$IncrementalLog = Get-Content -Path "F:\Data\Scripts\Powershell\ManualBackups\RMC-Backup-RMC-FS-001-Incremental.Log"

$option = [System.StringSplitOptions]::RemoveEmptyEntries


Foreach ($row in $IncrementalLog)
{
    IF ($row | Select-string -Pattern "recv")
    {
    $dataParse = $row -Replace ".*recv" -replace "recv.*"
    $result = $dataParse.Trim()
    Add-Content -Path "F:\Data\Scripts\Powershell\ManualBackups\newdelimitedlogfile.txt" -value $result
    }
}


#add the directories which have been completed
#save changes name file in standardized format.