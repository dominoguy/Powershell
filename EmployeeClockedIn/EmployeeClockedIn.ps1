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
        [String]$To,
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

function Test-SQLConnection
{    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        $ConnectionString
    )
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();
        return $true;
    }
    catch
    {
        return $false;
    }
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"
$LogFileName = "EmployeeClockedIn"
$LogFile = "$PSScriptroot\Logs\$LogFileName.log"
$SQLCMD = "$PSScriptroot\itr-sqlcommand.txt"

$ITRSQLFileName = "ITR-EmployeeClockedIn.csv"
$ITRSQLFileNameTemp = "ITR-EmployeeClockedInTemp.csv"
$ITRSQLResults = "$PSScriptroot\$ITRSQLFileName"

$DateCheckFile = "$PSScriptroot\DateCheck.txt"

$EmailResults = "brianlong@renatus.ca"
$EmailSupport = "Suppprt@renatus.ca"

$SQLInstance = "ACE-SRV-001\ITR"
$SQLUser = "itrscript"
$SQLPWD = "sklDjfq34028217jcNvlan4e"

$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
   #let log grow a certain size, remove -1 log file
   $FileSize = (Get-Item $LogFile).Length/1kb
   if ($FileSize -gt 1000) 
   {
    $logFileDash1Exists = Test-Path -path "$PSScriptroot\Logs\$LogFileName-1.log"
    if ($logFileDash1Exists -eq $True) 
    {
        Remove-Item -Path "$PSScriptroot\Logs\$LogFileName-1.log"
    }
    Rename-Item -Path $LogFile -NewName "$LogFileName-1.log"
    New-Item -ItemType File -Force -Path $logFile
   }
}
else
{
    #create a new log file
    New-Item -ItemType File -Force -Path $logFile  
}

#Check the SQL connection to the ITR Database
$SQLUp = Test-SQLConnection "SERVER=$SQLInstance;user=$SQLUser;password=$SQLPWD"

if ($SQLUp -eq $True) 
{
    $DateCheckFileExists = Test-Path -path $DateCheckFile
    if ($DateCheckFileExists -eq $True)
    {
        $DateCheck = Get-Content -Path $DateCheckFile
        if ($curDate -eq $DateCheck) 
        {
            #check against employee list and if any changes email new results
            $ITRSQLTemp = "$PSScriptroot\$ITRSQLFileNameTemp"
            Invoke-Sqlcmd -InputFile $SQLCMD -ServerInstance $SQLInstance -Username $SQLUser -Password $SQLPWD | Out-File -FilePath $ITRSQLTemp
            Set-Location $PSScriptroot
            [System.Data.SqlClient.SqlConnection]::ClearAllPools()
            $CompareResults = Compare-Object -ReferenceObject (Get-Content -Path $ITRSQLResults) -DifferenceObject (Get-Content -Path $ITRSQLTemp) | Select-Object -ExpandProperty InputObject
            Write-Log "Checking ITR Employee list"
            If ($null -eq $CompareResults)
            {
                Write-Log "The files are the same"
                Remove-item $ITRSQLTemp
            }
            else 
            {
                Write-Log "The files are different"
                Remove-Item "$PSScriptroot\$ITRSQLFileName"
                Rename-Item -Path $ITRSQLTemp -NewName $ITRSQLFileName
                Write-Log "Emailing Results"
                #email out new results
                $Time = Get-Date
                $To = $EmailResults
                $Subject = "ITR-Employee Checked In List"
                $Body = "ITR Checked In Employees: List created at $Time"
                $Attachments = $ITRSQLResults
                SendEmail $To $Subject $Body $Attachments
            }    
        }
        else 
        {
            #remove contents of datecheckfile and put in curdate
            Set-Content -Path $DateCheckFile -Value $curDate
            #get employee list and send out email for first email of the day
            Write-Log "Starting EmployeeClockedIn"
            Write-Log "Getting first list of the day"
            #Get a list of checked in employees
            Invoke-Sqlcmd -InputFile $SQLCMD -ServerInstance $SQLInstance -Username $SQLUser -Password $SQLPWD | Out-File -FilePath $ITRSQLResults
            Set-Location $PSScriptroot
            [System.Data.SqlClient.SqlConnection]::ClearAllPools()
            $ResultsCheck = IF ([string]::IsNullOrWhitespace($ITRSQLResults)){$True} else {$False}
            $Time = Get-Date

            If ($ResultsCheck -eq $False ) {
                Write-Log "Emailing Results"
                #email out the results
                $To = $EmailResults
                $Subject = "ITR-Employee Checked In List"
                $Body = "ITR Checked In Employees: List created at $Time"
                $Attachments = $ITRSQLResults
                SendEmail $To $Subject $Body $Attachments
            }
            else {
            Write-Log "There are no checked in employees at $Time."
            }
        }
    }
    else 
    {
        New-Item -Path $DateCheckFile -ItemType File -Force -Value $curDate
        Write-Log "Starting EmployeeClockedIn"
        Write-Log "Getting first list of the day"
        #Get a list of checked in employees
        Invoke-Sqlcmd -InputFile $SQLCMD -ServerInstance $SQLInstance -Username $SQLUser -Password $SQLPWD | Out-File -FilePath $ITRSQLResults
        Set-Location $PSScriptroot
        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
        $Time = Get-Date

        If ($ResultsCheck -eq $False )
        {
            Write-Log "Emailing Results"
            #email out the results
            $To = $EmailResults
            $Subject = "ITR-Employee Checked In List"
            $Body = "ITR Checked In Employees: List created at $Time"
            $Attachments = $ITRSQLResults
            SendEmail $To $Subject $Body $Attachments
        }
        else 
        {
            Write-Log "There are no checked in employees at $Time."
        }

    }
}
else 
{
    Write-Log "Cannot connect to ITR SQL database - $SQLInstance"
     #email out the results
     $To = $EmailSupport
     $Subject = "ITR-Employee Checked In Script - Cannot Connect to ITR DB"
     $Body = "ITR Employee Script failed to connect to the ITR DB on $SQLInstance"
     SendEmail $To $Subject $Body $Attachments
     
}