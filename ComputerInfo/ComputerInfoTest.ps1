#ComputerInformationWMIC 
#from an imported list (CSV) get the following:
#Manufacturer, Model, Total Ram and RAM by slot, size of HD and remaining freespace



function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\ComputerInfolog.log'
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

Write-Log "Gathering Computer Information"

$CompCSV = "F:\Data\Scripts\Powershell\ComputerInfo\RIWKSList.csv"
$CompList = Import-Csv $CompCSV

foreach ($row in $CompList)
{
    $compName = $row.name
    Write-Log "Getting $compName's Information"
    $compResults = "F:\Data\Scripts\Powershell\ComputerInfo\$compname.txt"
    
    $compResultsExists = Test-Path -path  $compResults
    
    if ( $compResultsExists -eq $True)
    {
        Remove-Item $compResults
        New-Item -ItemType File -Force -Path $compResults
    }
    else
    {
        New-Item -ItemType File -Force -Path $compResults
    }
    $compAlive = Test-connection -Buffersize 32 -count 1 -computername $compName -Quiet

    If ($compAlive -eq $true) {
        Write-Log "$compName is online"
        Add-Content $compResults -value "System Info"
        $ResultsSystem = Get-WmiObject win32_computersystem -computername $compName | select-object -Property Manufacturer,Model,TotalPhysicalMemory
        Add-Content $compResults -value $ResultsSystem
        Add-Content $compResults -value "Memory Info"
        $ResultsMem = Get-WmiObject win32_physicalmemory -computername $compName | Select-Object -property capacity,devicelocator
        Add-Content $compResults -value $ResultsMem
        Add-Content $compResults -value "Disk Info"
        $ResultsDisk = Get-WmiObject win32_logicaldisk -computername $compName | Select-Object -property deviceid,size,freespace
        Add-Content $compResults -value $ResultsDisk
 
    }
  Else {
        Write-Log "$CompName is Offline"
        Add-Content $compResults -value "Computer is offline"
  }

    Write-Log "Completed $compName's Information"

}

Write-Log "Completed $compName's Information"


#Get-WmiObject win32_computersystem -computername ace-dt-005 | select-object -property Manufacturer,Model,totalphysicalmemory | FL
#Get-WmiObject win32_logicaldisk -computername ace-dt-005 | Select-Object -property deviceid,size,freespace
#Get-WmiObject win32_physicalmemory -computername ace-dt-005 | Select-Object -property capacity,devicelocator




