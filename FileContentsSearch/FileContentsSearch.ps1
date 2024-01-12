#FileContentsSearch
#Brian Long 09Jan2024
#Version 1.0
#This script will search a list of directories and their subdirectories looking for keywords in the files.
#Then it will copy the files to another location

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = "$PSScriptRoot\Logs\FileContentsSearch-$curdate.log"
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

Write-Log "Start File Content Search"

#Get the list of Users to search
$Users = Import-csv -Path "$PSScriptRoot\Users.csv"
#Get the list of directories to search
$DirectoryList = Import-csv -Path "$PSScriptRoot\DirectoriesToSearch.csv"
#Get the Keywords to search
$KeywordCSV = Import-csv -Path "$PSScriptRoot\Keywords.csv"
$ResultsDirectory = "D:\Data\Secure\SLT\SLT - 2023\FOIP Request\Renatus Searches\Request 2"

$RootPath = "D:\Data"

$KeywordList = $KeywordCSV.keyword

Write-log "This is the keywordlist: $KeywordList"

ForEach ($User in $Users)
{   
    $User = $User.Users
    Write-Log "Searching files for: $User"
    $TargetDir = "$ResultsDirectory\$User"
    Write-Log "Target Directory: $TargetDir"
    $TestDirPath = Test-Path -Path $TargetDir
    If($TestDirPath -NE $true)
    {
        mkdir $TargetDir
    }
    ForEach($Row in $DirectoryList)
    {
        $Dir = $Row.Directory 
        $SourceDir = $RootPath + "\" + $Dir + "\" + $User
        Write-Log "The source we are searching is: $SourceDir"
        #Note if you think $Results is too large, send to a file and then loop the file to copy out.
        $Results = Get-ChildItem $SourceDir* -Recurse -ErrorAction SilentlyContinue -Force | Select-String -Pattern $KeywordList -AllMatches | Select-Object -Unique Path
        ForEach($Item in $Results)
        {
            $SourceFile = $Item.Path
            $SourceFile | Copy-Item -Destination $TargetDir
            Write-Log "Files found under: $SourceFile"
        }
    }
}














Write-Log "End File Content Search"