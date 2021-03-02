#VM-SnapshotList

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
    $vms = Invoke-Command -Computername $servername -ScriptBlock{get-vm |select-object -Expandproperty Name}

    foreach ($vm in $vms)
    {
        write-log "    $vm"
        Write-Host $vm

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


