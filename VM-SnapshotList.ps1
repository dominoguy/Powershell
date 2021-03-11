#VM-SnapshotList


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

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\VMSnapShotList.log'
$ServerCSV = 'F:\Data\Scripts\Powershell\VMSnapShotList\HVSServerList.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\VMSnapShotList\VMSnapShotList-Results.csv"

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

Write-Log "Starting VM Snapshot Check"

#Create results file
$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"VMName","SnapshotName","SnapshotTYpe"'
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

#$servername = 'RI-HVS-001'

$ServerList = Import-Csv $ServerCSV

foreach ($row in $Serverlist)
{
    
    $servername = $row.name
    Write-log $servername
    #add line to results for hvs, check drive on c and d, total disk and free space
    #
     #Connect to Server
     $cdisk = Invoke-Command -ComputerName $servername -ScriptBlock{Get-WmiObject win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace,DeviceID}
     $cdiskFreeSpace = [Math]::Round($cdisk.FreeSpace/1gb,2)
     $cdiskSize = [Math]::Round($cdisk.Size/1gb,2)
     $cdiskName = $cdisk.DeviceID
     #$cdiskFreeSpace = ConvertToGB $disk.FreeSpace
     #$cdiskSize - ConvertToGB $disk.Size
 
     $Results = [PSCustomObject]@{
         ServerName = "$Servername"
         DriveName = "$cdiskName"
         FreeSpace = "$cdiskFreeSpace"
         DiskSize = "$cdiskSize"
     } 
     $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force


    $vms = Invoke-Command -Computername $servername -ScriptBlock{get-vm |select-object -Expandproperty Name}

    foreach ($vm in $vms)
    {
        write-log "    $vm"
        Write-Host $vm
        #add line in results for each vm, vm status, 
        $Snapshots = Invoke-Command -Computername $servername -ScriptBlock{param($var1) get-vm $var1 | Get-VMSnapshot} -ArgumentList $vm
        foreach ($item in $Snapshots) 
        {
        $VMName =  $item.VMName
        $SnapshotName = $item.Name
        $SnapshotTYpe = $item.SnapshotType

        Get-Content -Path $ResultsCSV
        $Results = [PSCustomObject]@{
            VMName = "$VMName"
            SnapshotName = "$SnapshotName"
            SnapshotTYpe = "$SnapshotTYpe"
            }
        $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
        }

    }
}

write-log 'Finished VM Snapshot Check'


