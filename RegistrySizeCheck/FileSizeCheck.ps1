#FileSizeCheck

<#
.SYNOPSIS
Checks each listed server from a CSV file and checks the size of files listed in the CSV file.
Currently written to just check Registry file size on c:
Should be expanded to any file on any drive


.DESCRIPTION
This script goes to each listed server and checks the size of the files listed and logs the results

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\LOGS\FileSizeCheck.log
.PARAMETER ServerCSV
The path to the server list
IE. 'F:\Data\Scripts\Powershell\RegistrySizeCheck\ServerList.csv'
.PARAMETER FileCSV
The location of the new backup database
IE. 'F:\Data\Scripts\Powershell\RegistrySizeCheck\FileLocation.csv'
.PARAMETER ResultsCSV
The name of the ServerInst
IE. F:\Data\Scripts\Powershell\RegistrySizeCheck\FileSizeCheck-Results.csv
#>

param(
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of Log FIle')][string]$LogLocation,
        [Parameter(Mandatory=$False,Position=2,HelpMessage='Location of list of servers')][string]$ServerCSV,
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of list of files')][string]$FileCSV,
        [Parameter(Mandatory=$False,Position=1,HelpMessage='Location of size check results')][string]$ResultsCSV
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

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\FileSizeCheck.log'
$ServerCSV = 'F:\Data\Scripts\Powershell\RegistrySizeCheck\ServerList.csv'
$FileCSV = 'F:\Data\Scripts\Powershell\RegistrySizeCheck\FileLocation.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\RegistrySizeCheck\FileSizeCheck-Results.csv"

$logFile = $LogLocation
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    #New-Item -ItemType File -Force -Path $logFile
}
else
{
    #New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Starting File Check"

Write-Log "Creating Results File"
#Create results file
$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"ServerName","FilePath","FileSize"'
if ( $ResultsExists -eq $True)
{
    Remove-Item $ResultsCSV
    #New-Item -ItemType File -Force -Path $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}
else
{
    #New-Item -ItemType File -Force -Path $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}

Write-Log "A Results File has been created"

#List of Files to check
$FileList = Import-Csv $FileCSV
$ServerList = Import-Csv $ServerCSV

foreach ($row in $Serverlist)
{
    #Get the client acryonom, servername and domain name
    $Client = $row.Client
    $Servername = $row.ServerName
    $Domain = $row.Domain
    $AdminName =$row.AdminName
    $Password = $row.Password

    Write-Log "Checking $ServerName"

    #map the drive to the server
    $Username = $Client + "\" + $AdminName
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

    $ServerPath = "\\" + $ServerName +"." + $Domain + "\C$" 
    New-PSDrive -Name "Q" -Root $ServerPath -PSProvider "FileSystem" -Credential $cred

    #Is the Server share available
    try
    {If (Test-Path -Path "Q:" -ErrorAction Stop)
        {
            $ServerPathExists = $true
            Write-Log "$ServerName Share is available"
        }
    Else
        {
            $ServerPathExists = $False
            Write-Log "********** $ServerName Share is NOT available *************"
        }
    }
    Catch [UnauthorizedAccessException]
    {
        $ServerPathExists = $true
        Write-Log "$ServerName Share is available"
    }
    #IF there is a connection to the drive on the server then we can proceed
    IF ($ServerPathExists -eq $True)
        {
            foreach ($Line in $Filelist)
            {
                $FIlePath = "Q:" + $Line.FilePath
                Write-Log "   Checking $ServerName at $FilePath"

                $FileSize = (Get-ItemProperty $FilePath).Length/1MB
                Get-Content -Path $ResultsCSV
                $Results = [PSCustomObject]@{
                    ServerName = "$Servername"
                    FilePath = "$FilePath"
                    FileSize = "$FileSize"
                }
                Write-Log "      File Check $Server $FilePath $FileSize"
                $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
            }
        }
    #Close the mapped drive
    Remove-PSDrive -Name "Q" -Force

}
Write-Log "Finished File Check"