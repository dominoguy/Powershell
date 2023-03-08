#Server Performance Check
#This script will check the following:
#   1) Total CPU used at the time
#   2) Total Memory used and total memory available
#   3) Free space on designated logical disk

function ConvertToMB ($Size)
    {$a = [Math]::Round($Size/1mb,2)
    Return $a
}

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

#$OutPutFilePath = "F:\Data\Scripts\Powershell\ServerMonitoring\Logs"
$OutPutFilePath = "D:\Data\Scripts\ServerMonitoring\Logs"
$logFile = "$OutPutFilePath\ServerPerformanceCheck.log"
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $False)
{
    New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Starting Server Performace Check"
$ServerName = $env:computername

$MemoryFile = $OutPutFilePath + "\$ServerName-Memory.csv"
$MemoryFileExists = Test-Path -path $MemoryFile
$Headers = '"TimeStamp","MemoryUsed","MemoryAvail"'
if ($MemoryFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $MemoryFile
 Add-Content -Path $MemoryFile -Value $Headers
}
<#
else {
    Remove-Item $MemoryFile
    New-Item -ItemType File -Force -Path $MemoryFile
    Add-Content -Path $MemoryFile -Value $Headers
} 
#>

$CPUTotalFile = $OutPutFilePath + "\$ServerName-CPUTotal.csv"
$CPUTotalFileExists = Test-Path -path $CPUTotalFile
$Headers = '"TimeStamp","CPUTotalUsed"'
if ($CPUTotalFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $CPUTotalFile
 Add-Content -Path $CPUTotalFile -Value $Headers
}

$DiskFile = $OutPutFilePath + "\$ServerName-DiskInfo.csv"
$DiskFileExists = Test-Path -path $DiskFile
$Headers = '"TimeStamp","DriveName","DiskSize","UsedSpace","FreeSpace"'
if ($DiskFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $DiskFile
 Add-Content -Path $DiskFile -Value $Headers
}

Write-Log "Getting Used Memory"
$Counters = get-counter -counter "\Memory\Committed Bytes" -sampleInterval 2 -MaxSamples 2                               
ForEach ($row in $Counters.CounterSamples)
{
    $TimeStamp = $row.TimeStamp
    $CookedValue = ConvertToMB($row.CookedValue)
    $Results = [PSCustomObject]@{
        TimeStamp = "$TimeStamp"
        MemoryUsed = "$CookedValue"
    }
    $Results | Export-Csv -Path $MemoryFile -Append -NoTypeInformation -Force
    Write-Log "   $TimeStamp, Used memory is $CookedValue"
}

Write-Log "Getting Free Memory"
$Counters = get-counter -counter "\Memory\Available Bytes" -sampleInterval 2 -MaxSamples 2                                
ForEach ($row in $Counters.CounterSamples)
{
    $TimeStamp = $row.TimeStamp
    $CookedValue = ConvertToMB($row.CookedValue)
    $Results = [PSCustomObject]@{
        TimeStamp = "$TimeStamp"
        MemoryAvail = "$CookedValue"
    }
    $Results | Export-Csv -Path $MemoryFile -Append -NoTypeInformation -Force
    Write-Log "   $TimeStamp, Available memory is $CookedValue"
}


Write-Log "Getting Total CPU Used"
$Counters = get-counter -counter "\Processor(_total)\% Processor Time" -sampleInterval 2 -MaxSamples 2                 
ForEach ($row in $Counters.CounterSamples)
{
    $TimeStamp = $row.TimeStamp
    $CookedValue = $row.CookedValue
    $Results = [PSCustomObject]@{
        TimeStamp = "$TimeStamp"
        CPUTotalUsed = "$CookedValue"
    }
    $Results | Export-Csv -Path $CPUTotalFile -Append -NoTypeInformation -Force
    Write-Log "   $TimeStamp, Total CPU Used is $CookedValue"
}

Write-Log "Getting Disk Information"
#$deviceIDName = "DeviceID ='$Drive'"
$deviceIDName = "DeviceID ='C:'"
$disk = Get-WmiObject win32_LogicalDisk -Filter $deviceIDName | Select-Object Size,FreeSpace,DeviceID
    $diskName = $disk.DeviceID
    $diskFreeSpace = ConvertToGB $disk.FreeSpace
    $diskSize = ConvertToGB $disk.Size
    $diskUsed = $diskSize - $diskFreeSpace
    
    $Results = [PSCustomObject]@{
    TimeStamp = $Time
    DriveName = "$diskName"
    DiskSize = "$diskSize"
    UsedSpace = "$diskUsed"
    FreeSpace = "$diskFreeSpace"
    } 
    $Results | Export-Csv -Path $DiskFile -Append -NoTypeInformation
    Write-Log "   Diskname = $DiskName, Disk Size is $disksize, Disk Used is $diskUsed, Disk Free Space is $diskFreeSpace"

Write-Log "End Server Performace Check"
