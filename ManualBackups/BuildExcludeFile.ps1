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
#$dataParse = $IncrementalLog -replace '[ ]{2,}',','
$option = [System.StringSplitOptions]::RemoveEmptyEntries


Foreach ($row in $IncrementalLog)
{
    IF ($row | Select-string -Pattern "recv")
    {
    $dataParse = $row -Replace ".*recv" -replace "recv.*"
    #$dataParse = $Filter.split('recv',5)[-1]
    $result = $dataParse.Trim()
    
    Add-Content -Path "F:\Data\Scripts\Powershell\ManualBackups\newdelimitedlogfile.txt" -value $result
    }
}


#add the directories which have been completed
#save changes name file in standardized format.