#HVS-Server-Disk-Check

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\HVS-FileSizeCheck.log'
$ServerCSV = 'F:\Data\Scripts\Powershell\HVS-Server-Disk-Check\HVSServerList.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\HVS-Server-Disk-Check\HVS-FileSizeCheck-Results.csv"

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

Write-Log "Starting HVS Disk Check"

#Create results file
$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"ServerName","DriveName","FreeSpace","DiskSize"'
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

$ServerList = Import-Csv $ServerCSV

$Username = RI\riadmin
$Password = N0matt3r20

$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

Get-Content -Path $ResultsCSV

foreach ($row in $Serverlist)
{
    #Get the client acryonom, servername and domain name
    $Client = $row.Client
    $Servername = $row.ServerName


    Write-Log "Checking $ServerName"

    #Connect to Server
    $Session = New-PSSession -ComputerName $servername -Credential $cred
    Enter-PSSession -Session $Session
    $cdisk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace
    $cdiskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
    $cdiskSize = [Math]::Round($disk.Size/1gb,2)

    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        $cdisk = "DriveName"
        $cdiskFreeSpace = "FreeSpace"
        
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
    

    $ddisk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object Size,FreeSpace
    $ddiskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
    $ddiskSize = [Math]::Round($disk.Size/1gb,2)


    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        $cdisk = "$FilePath"
        FileSize = "$FileSize"
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation


}