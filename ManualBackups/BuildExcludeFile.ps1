<#BuildExcludeFile
Version 1.0 21-Oct-2021 Brian Long
This script creates an exclusion list for a server based on the last directoroy RSync finished on.
It uses the Redirected log and looks at the last 20 entries to determine the last directory.
It then builds an exclusion list from a default exclusion list adding each entry until it reaches the last directory RSync acted on (which it does not add to the list).
RSync will then use this list for the manual backup.
4 parms need to be setup are the log locations and exclude files
#>

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

Write-Log "Creating Exclude File for "

#Create blank exclude file for server. If file already exists delete it.
$ExcludeListManualPath = "F:\Data\Scripts\Powershell\ManualBackups\Exclude-Manual-RMC-FS-001.txt"
$ExcludeListManualPathExists = Test-Path -path $ExcludeListManualPath 
If ($ExcludeListManualPathExists -eq $True)
{
    Remove-Item $ExcludeListManualPath 
    New-Item -ItemType File -Force -Path $ExcludeListManualPath 
}
else
{
    New-Item -ItemType File -Force -Path $ExcludeListManualPath 
}

#Get Default exclude folder list
$ExcludeFIleDefaultsPath = "F:\Data\Scripts\Powershell\ManualBackups\ExcludeFilter-Defaults.Txt"
$ExcludeFileDefaults = Get-Content -Path $ExcludeFIleDefaultsPath

#Get Redirect log contents
$reDirectLogPath = "F:\Data\Scripts\Powershell\ManualBackups\RMC-Backup-RMC-FS-001-Incremental.Log.redirect"
$reDirectLog = Get-Content -Path $reDirectLogPath | Select -last 20

#Locate the last directory rsync operated on
Foreach ($row in $reDirectLog)
{
    IF ($row | Select-string -Pattern "/")
    {
     $dataParse = $row.split("/")
     $redirectDir = $dataParse[0]
     $redirectDir = "- " + $redirectDir + "/"
    
        ForEach ($dir in $ExcludeFIleDefaults)
        {
            if ($dir -eq $redirectDir)
            {
                $lastDir = $dir
                write-host "This is the lastdir " $lastDir
            }
        }
    }
}

#Build the exclusion list
ForEach ($dir1 in $ExcludeFIleDefaults)
{
    if ($dir1 -ne $lastDir)
    {
        Add-Content -Path $ExcludeListManualPath  -Value $dir1
    }
    Else {Break}
}
Write-Log "Exclude File Created for "