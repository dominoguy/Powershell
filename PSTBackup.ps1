#PSTBackup Version 2.0
#Brian Long July 12, 2018
<#
.SYNOPSIS
Robocopys PSTs from a local workstation to the server

.DESCRIPTION
Starts in a targeted directory and checks each subsequent folder for psts, if found checks to see if
it is in use,if not then does the robocopy.

.PARAMETER PSTListLocation
Location of the list of psts in CSV format
IE. F:\Data\Scripts\Powershell\pstlist.csv

.PARAMETER LogLocaiton
Location of log file
IE. F:\Data\Scripts\Powershell\LOGS\PSTCopy.log
#>

param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage='Location of CSV PST List')][string]$PSTListLocation,
        [Parameter(Mandatory=$true,Position=2,HelpMessage='Location of Log file')][string]$LogLocation
    )

<#
.SYNOPSIS
Writes to a log.

.Description
Creates a new log file in the designated location.

.PARAMETER logstring
String of text
#>
        function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}
function Backup-PST
{
    Param(
        [String]$Filename,
        [String]$SourceDir,
        [String]$DestDir,
        [String]$FilePath,
        [String]$RobocopyLog,
        [String]$Username)

    $oFile = New-Object System.IO.FileInfo $FilePath
    try
    {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($oStream)
        {
            $oStream.Close()
        }
        $False
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Log " ***** $UserName $FilePath $ErrorMessage *****"
        return $True
    }
    finally
    {
        if (-Not $ErrorMessage)
        {
            Write-Log "$UserName $FilePath is ready for backup"
            Robocopy.exe $SourceDir $DestDir $Filename /e /ndl /np /tee /w:0 /r:0 /log:$RobocopyLog
            Write-Log "$UserName $FileName has been backed up"
        }
    }
}

#$logFile = 'F:\Data\Scripts\Powershell\LOGS\PSTCopy.log'
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

Write-Log "PSTBackup Begins"

$list = Import-Csv $PSTListLocation

foreach ($row in $list)
{
    #Get a list of pst files (recursive into sub dirs) using source as root dir
    $startDir = $row.startDir
    $userName = $row.userName
    $folderExists = Test-Path $startDir

    if ($folderExists -eq $True) 
    {
        $pstList = Get-ChildItem $startDir -Recurse | Where-Object {$_.extension -eq ".pst"}
        foreach ($pst in $pstList)
        {
            $fileName = $pst.Name
            $sourceDir = [String]($pst.Directory)
            $filePath = $pst.FullName
            $userDir = $row.UserDir
            $diffDir = $sourceDir.replace($startDir,'')
            $destDir = $userdir +'\' + $diffDir
            $robocopyLog = $destDir +'\' + $filename + '.log'
            Backup-PST $fileName $sourceDir $destDir $filePath $robocopyLog $userName
        }
    }
    else {Write-Log "$Time  ***** $userName $startDir is not available *****"}
}
Write-Log "PSTBackup Ends"