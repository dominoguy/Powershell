#This script queries the ITR database and lists the employees who have clocked in.
#The script will email the first results at the begining of the day.
#The script then subsequenial checks every hour to see if any changes have been made and if so emails the results.

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

Function SendEmail {
    [CmdletBinding()]
    Param(
        [String]$Subject,
        [String]$Body,
        [String]$Attachments
    )

    $SMTPServer = "latte.digitaltea.com"
    #$SMTPServer = "ri-exch-002.ri.ads"
    $SMTPUser = "acetechservices@acemfg.com"
    $SMTPPWD = "kMdk239!blkmw9"


    #$passwordLocation = "$PSScriptRoot\Password.txt"
    #$password = Get-Content $passwordLocation | ConvertTo-SecureString
    $password = $SMTPPWD
    $Port = "366"
    #$Port = "25"
    $From = "acetechservices@acemfg.com"
    $To = "brianlong@renatus.ca"
    
    $email = New-Object System.Net.Mail.MailMessage
    $email.From = $From
    $email.To.Add($To)
    $email.Subject = $Subject
    $email.Body = $Body
    $email.isBodyhtml = $true
    $smtp = New-Object Net.Mail.SmtpClient $SMTPServer,$Port
    $smtp.Credentials = New-Object System.Net.NetworkCredential ($SMTPUser,$password)
   
    $smtp.EnableSSL = $False
    $smtp.Port = 366
    $emailAttachment = New-Object Net.Mail.Attachment $Attachments
    $email.Attachments.add($emailAttachment)
    $smtp.Send($email)
    $emailAttachment.Dispose()
    
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogFile = "$PSScriptroot\Logs\$curDate-EmployeeClockedIn.log"
$SQLCMD = "$PSScriptroot\itr-sqlcommand.txt"

$ITRSQLFileName = "ITR-EmployeeClockedIn.log"
$ITRSQLFileNameTemp = "ITR-EmployeeClockedInTemp.log"
$ITRSQLResults = "$PSScriptroot\$ITRSQLFileName"

$SQLInstance = "ACE-SRV-001\ITR"
$SQLUser = "sa"
$SQLPWD = "SQLAdmin"

$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
   #check against employee list and if any changes email new results
   $ITRSQLTemp = "$PSScriptroot\$ITRSQLFileNameTemp"
   Invoke-Sqlcmd -InputFile $SQLCMD -ServerInstance $SQLInstance -Username $SQLUser -Password $SQLPWD | Out-File -FilePath $ITRSQLTemp
   Set-Location $PSScriptroot
   
   $CompareResults = Compare-Object -ReferenceObject (Get-Content -Path $ITRSQLResults) -DifferenceObject (Get-Content -Path $ITRSQLTemp) | Select-Object -ExpandProperty InputObject
    Write-Log "Checking ITR Employee list"
    If ($null -eq $CompareResults)
    {
        Write-Log "The files are the same"
        Remove-item $ITRSQLTemp
    }
    else {
        Write-Log "The files are different"

        Remove-Item "$PSScriptroot\$ITRSQLFileName"
        Rename-Item -Path $ITRSQLTemp -NewName $ITRSQLFileName
        Write-Log "Emailing Results"
        #email out new results
        $Time = Get-Date
        $Subject = "ITR-Employee Checked In List"
        $Body = "ITR Checked In Employees: List created at $Time"
        $Attachments = $ITRSQLResults
        SendEmail $Subject $Body $Attachments
    }    
}
else
{
    #remove old log files
    Remove-Item "$PSScriptroot\Logs\*EmployeeClockedIn.log"
    #create a new log file
    New-Item -ItemType File -Force -Path $logFile
    Write-Log "Starting EmployeeClockedIn"
    Write-Log "Getting first list of the day"
    #Get a list of checked in employees
    Invoke-Sqlcmd -InputFile $SQLCMD -ServerInstance $SQLInstance -Username $SQLUser -Password $SQLPWD | Out-File -FilePath $ITRSQLResults
    Set-Location $PSScriptroot
    Write-Log "Emailing Results"
    #email out the results
    $Time = Get-Date
    $Subject = "ITR-Employee Checked In List"
    $Body = "ITR Checked In Employees: List created at $Time"
    $Attachments = $ITRSQLResults
    SendEmail $Subject $Body $Attachments
}
