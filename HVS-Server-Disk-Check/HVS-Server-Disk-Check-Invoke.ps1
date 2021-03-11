#HVS-Server-Disk-Check

function ConvertToGB
{
    Param(
        [Int]$Size
    )
    [Math]::Round($Size/1gb,2)
}

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\HVS-FileSizeCheck-Invoke.log'
$ServerCSV = 'F:\Data\Scripts\Powershell\HVS-Server-Disk-Check\HVSServerList.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\HVS-Server-Disk-Check\HVS-FileSizeCheck-Results-Invoke.csv"

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

Get-Content -Path $ResultsCSV

foreach ($row in $Serverlist)
{
    #Get the client acryonom, servername and domain name
    $Servername = $row.ServerName


    Write-Log "Checking $ServerName"

    #Connect to Server
    $cdisk = Invoke-Command -ComputerName $servername -ScriptBlock{Get-WmiObject win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace,DeviceID}
    #$cdiskFreeSpace = [Math]::Round($cdisk.FreeSpace/1gb,2)

    $cdiskSize = [Math]::Round($cdisk.Size/1gb,2)
    $cdiskName = $cdisk.DeviceID
    $cdiskFreeSpace = ConvertToGB $disk.FreeSpace
    #$cdiskSize - ConvertToGB $disk.Size

    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        DriveName = "$cdiskName"
        FreeSpace = "$cdiskFreeSpace"
        DiskSize = "$cdiskSize"
    } 
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force
    
<#
    $ddisk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object Size,FreeSpace
    $ddiskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
    $ddiskSize = [Math]::Round($disk.Size/1gb,2)


    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        $cdisk = "$FilePath"
        FileSize = "$FileSize"
    }
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
#>


}