#VM-SnapshotList
#This script connects to each HVS in the server list and gets size and free space on its C: and D: drive
#It then gets each vm on the HVS and gets it state and any snapshots associated with it.

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
$Headers = '"ServerName","DriveName","FreeSpace","DiskSize","VMName","State","SnapshotName","SnapshotTYpe"'
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
    
    $servername = $row.name
    Write-log $servername
    
    #Get the size and free space on C: and D of the HVS, size in GBs
    $cdisk = Invoke-Command -ComputerName $servername -ScriptBlock{Get-WmiObject win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace,DeviceID}
    $cdiskName = $cdisk.DeviceID
    $cdiskFreeSpace = ConvertToGB $cdisk.FreeSpace
    $cdiskSize = ConvertToGB $cdisk.Size

    $Results = [PSCustomObject]@{
        ServerName = "$Servername"
        DriveName = "$cdiskName"
        FreeSpace = "$cdiskFreeSpace"
        DiskSize = "$cdiskSize"
    } 
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force
    

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
    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force

    #Get all the VMs on the HVS - detailing VM name, its state, snapshots
    $vms = Invoke-Command -Computername $servername -ScriptBlock{get-vm |select-object -Expandproperty Name}

    foreach ($vm in $vms)
    {
        write-log "    $vm"
        $State = Invoke-Command -Computername $servername -ScriptBlock{param($var1) get-vm $var1 | select-object -expandproperty State} -ArgumentList $vm
        Get-Content -Path $ResultsCSV
        $Results = [PSCustomObject]@{
            VMname = "$vm"
            State = $State
        }
        $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force
        
        $Snapshots = Invoke-Command -Computername $servername -ScriptBlock{param($var1) get-vm $var1 | Get-VMSnapshot} -ArgumentList $vm
        foreach ($item in $Snapshots) 
        {
        $VMName =  $item.VMName
        $SnapshotName = $item.Name
        $SnapshotTYpe = $item.SnapshotType

        Get-Content -Path $ResultsCSV
        $Results = [PSCustomObject]@{
            #VMName = "$VMName"
            SnapshotName = "$SnapshotName"
            SnapshotTYpe = "$SnapshotTYpe"
            }
        $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation -Force
        }

    }
}

write-log 'Finished VM Snapshot Check'


