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
$Headers = '"ServerName","VMName"'
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

$Username = 'RI\riadmin'
$Password = 'N0matt3r20'

#$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
#$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

$servername = 'RI-HVS-001'

#Connect to Server
#$Session = New-PSSession -ComputerName $servername -Credential $cred
#Enter-PSSession -Session $Session
$vms = Invoke-Command -Computername $servername -ScriptBlock{get-vm | Select-Object -ExpandProperty Name}

#$vms = get-vm

foreach ($vm in $vms)
{
write-log "the $vm.name is $vm.state" 

}





Exit-PSSession