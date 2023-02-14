#ClientServerDataTotals
#This script gathers data sizes on a client server



function ConvertToGB ($Size)
    {$a = [Math]::Round($Size/1gb,2)
    Return $a
}


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = 'F:\Data\Scripts\Powershell\ServerDiskInformation\Logs\ClientServerDataUsage.log'
$ServerCSV = 'F:\Data\Scripts\Powershell\ServerDiskInformation\ServerDataList.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\ServerDiskInformation\$curdate-CleintServerDataUsage-Results.csv"

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

Write-Log "Starting Client Server Data Usage"

#Create results file
$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"ServerName","DriveName","SizeinGB"'
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

foreach ($row in $Serverlist)
{
    #Get the client acryonom, servername and domain name
    $Servername = $row.ServerName
    $ServerDrives = $row.Drives

    Write-Log "Checking $ServerName"
    #Connect to Server
    $driveArray = $null
    $driveArray = $ServerDrives.split(',')
    Foreach ($Drive in $driveArray)
    {
        $paramters = @{
            ComputerName = $servername
            ScriptBlock = {
                Param ($Drive)
                #Get-ChildItem -Recurse -Force $Drive | Measure-Object -Property Length -Sum
                Get-ChildItem -Recurse -Force $Drive -ErrorAction SilentlyContinue | Where-Object {$_.linktype -notmatch "HardLink"} | Measure-Object -Property Length -Sum
            }
            ArgumentList = $Drive
        }
        $disk = Invoke-Command @paramters
        $diskName = $Drive
        $diskUsed = ConvertToGB $disk.sum
    
        $Results = [PSCustomObject]@{
            ServerName = "$Servername"
            DriveName = "$diskName"
            SizeinGB = "$diskUsed"
        } 
        $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation

    }
    
    
    

    
    
<#
    $ddisk = Invoke-Command -ComputerName $servername -ScriptBlock{Get-WmiObject win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object Size,FreeSpace,DeviceID}
    $ddiskName = $ddisk.DeviceID
    $ddiskFreeSpace = ConvertToGB $ddisk.FreeSpace
    $ddiskSize = ConvertToGB $ddisk.Size

    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        DriveName = "$ddiskName"
        FreeSpace = "$ddiskFreeSpace"
        DiskSize = "$ddiskSize"
    }
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
#>


}