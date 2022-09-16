#RIMonthly

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}


#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

#$LogLocation = "F:\Data\Scripts\Powershell\RIMonthly\Logs\RIMMonthly-$curdate.log"
$LogLocation = "D:\Backups\RIBackup\RIMonthly\Logs\RIMMonthly-$curdate.log"
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

Write-Log "Start Monthly Backups for $curDate"

$bcApp = "C:\Program Files\Beyond Compare 4\BCompare.exe"
#$bcSnap = "F:\Data\Scripts\Powershell\RIMonthly\BCSnap.txt"
$bcSnap = "D:\Backups\RIBackup\RIMonthly\BCSnap.txt"
#$bcCopy = "F:\Data\Scripts\Powershell\RIMonthly\CompareCopy.txt"
$bcCopy = "D:\Backups\RIBackup\RIMonthly\CompareCopy.txt"

#$bcSize = "F:\Data\Scripts\Powershell\RIMonthly\CompareSize.txt"

#$serversList = "F:\Data\Scripts\Powershell\RIMonthly\ServersList.csv"
$serversList = "D:\Backups\RIBackup\RIMonthly\ServersList.csv"

$Servers = Import-CSV -Path $serversList | select-object -Property Client,ServerName,BaselinesDir,BackupsDir,DataDir,MonthlyDir,Exempt

$curMonth = Get-Date -UFormat "%m"
#$curMonth = "01"
$curYear = Get-Date -UFormat "%Y"
If ($curMonth -eq "01")
{
    $prevMonth = "12"
    $prevYear = $curYear-1
}
else
{
    $prevMonth = $curmonth-1
    $prevYear = $curYear
}
#Adds a leading "0" if month is a single digit
$prevMonth = "{0:d2}" -f $prevmonth

ForEach ($server in $Servers)
{
    $client = $server.Client
    $serverName = $server.ServerName
    $BaselinesDir = $server.BaselinesDir
    $BackupsDir = $server.BackupsDir
    $DataDir = $server.DataDir
    $MonthlyDrive = $server.MonthlyDir
    $Exempt = $server.Exempt

    $BaselinesDir = "$BaselinesDir\$DataDir"
    $BackupsDir = "$BackupsDir\$DataDir"
    $MonthlyDir = "$MonthlyDrive\Baselines_${prevMonth}_$prevYear\$Client\$ServerName\$DataDir"
    Write-Log "************ The server is: $Servername ************"
    Write-Log "The Backup directory is: $ServerName\$DataDir"
    Write-Log "The Baselines directory is: $BaselinesDir"
    Write-log "The monthly backup directory is: $MonthlyDir"

    $BaselinesDirExists = Test-Path -path $BaselinesDir 
    If ($BaselinesDirExists -eq $False)
    {
        New-Item -ItemType "Directory" -Force -Path $BaselinesDir
    }

    $MonthlyDirExists = Test-Path -path $MonthlyDir
    If ($MonthlyDirExists -eq $False)
    {
        New-Item -ItemType "Directory" -Force -Path $MonthlyDir
    }
    
    #Create a new snapshot of the existing data. To be used for next months backup
    Write-Log "Start: New BCSS snapshot of $ServerName\$DataDir"
    $bcssCurDate = "${curMonth}_$curYear"
    $bcssExceptions = ""
     If ($Exempt -eq "T")
     {
        $ExemptList = ".\$servername-$DataDir-ExemptionList.csv"
        $ExemptDirs = Import-CSV -Path $ExemptList | select-object -Property ExemptDir
        $bcssExceptions = "*"

        Foreach ($Dir in $ExemptDirs)
        {
            $Exemption = $Dir.ExemptDir
            $bcssExceptions = "$bcssExceptions;-.\$Exemption\"
        }
     }
    
    $argsBCSS = "@$bcSnap /closescript $BackupsDir $bcssCurDate $BaselinesDir $bcssExceptions"
    Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
    Write-Log "Completed: New BCSS snapshot of $ServerName\$DataDir"

    #Run the monthly backup
    Write-Log "Start: Monthly backup of $ServerName\$DataDir"
    $prevBCSSFile = "$BaselinesDir\${prevMonth}_$prevYear.bcss"
    $prevBCSSLog = "$BaselinesDir\${prevMonth}_$prevYear.log"
    $prevBCSSFileExists = Test-Path -path $prevBCSSFile
   
    If ($prevBCSSFileExists -eq $True)
    {
        $bcssPrevDate = "${prevMonth}_$prevYear"
        $argsBCSS = "@$bcCopy /closescript $BackupsDir $prevBCSSFile $MonthlyDir $bcssPrevDate $bcssExceptions"
        Start-Process -FilePath $bcApp -ArgumentList $argsBCSS -wait
        Copy-Item -Path $prevBCSSFile -Destination $MonthlyDir
        Copy-Item -Path $prevBCSSLog -Destination $MonthlyDir
    }
    else {
        Write-Log "No previous BCSS, monthly backup to proceed next month"
    }
  
    Write-Log "END: Monthly backup of $ServerName\$DataDir"
   
}
Write-Log "End Monthly Backups for $curDate"