#Get VM Drive Info

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$Loglocation = 'D:\Scripts\Logs\VMDriveInfo.log'
$logFile = $LogLocation

$logFileExists = Test-Path -path $logFile
if ( $logFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $logFile
}
 
$VM = "RI-TESTBCL-001"

Write-Log "Getting $VM Drive Info"

$vmDrives = Get-VM $VM | Get-VMHarddiskDrive

$diskInfo = New-Object System.Collections.ArrayList

ForEach ($Drive in $vmDrives) {
$DriveName = $Drive.Name
$Controller = $Drive.ControllerType
$ControllerNumber = $Drive.ControllerNumber
$ControllerLocation = $Drive.ControllerLocation
$Path = $Drive.Path
$DiskNumber = $Drive.DiskNumber
Write-Log "******************************"
Write-Log "The Name of the Drive is $DriveName"
Write-Log "The Controller type is $Controller"
Write-Log "The Controller Number is $ControllerNumber"
Write-Log "The Controller Location is $ControllerLocation"
Write-Log "The drive path is $Path"
Write-Log "The drive number is $DiskNumber"
Write-Log "******************************"
#disk info into an array
$diskInfo.add($($DriveName;$Controller;$ControllerNumber;$ControllerLocation;$Path;$DiskNumber)) | Out-Null
}

for ( $index = 0; $index -lt $diskInfo.count; $index++)
{
    Write-Log $diskInfo[$index] | Select-Object -Property DriveName,Controller,ControllerNumber,ControllerLocation,Path,DiskNumber
}

