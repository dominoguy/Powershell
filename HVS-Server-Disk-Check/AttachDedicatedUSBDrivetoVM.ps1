#AttachDedicatedUSBDrivetoVM
#This script attaches a USB drive to a VM based on the hard drive's signature
#CSV file maps the signature to the vm
#Signature of the drive has to be set manually based on identification code


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\AttachDedicatedUSBDrivetoVM.log'
$DriveMap = 'F:\Data\Scripts\Powershell\LOGS\USBtoVM-Mapping.csv'

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

Write-Log "Attaching USB drive to VMs"