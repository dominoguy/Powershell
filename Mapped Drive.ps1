#Mapped Drive



param(
        [Parameter(Mandatory=$true,HelpMessage='Location of Log file')][string]$LogLocation
)

function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

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

#get the credentials to access the read share on the vm
$Username = "ri\bakreadservice"
$Password = "VreBkE7PSC8yUfM5xKu1"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

$VMIP = "10.0.7.201"
$VMName = "RI-FS-001"

Import-Module -Name "F:\Data\Scripts\Powershell\TestFunctions\TestFunctions.psm1"
#get into the share to access the read file of the vm
$StatusPath = "\\$VMIP\$VMName-Status$" 
Write-Log $VMName": Checking share $StatusPath"
try
    {If (Test-Path -Path $StatusPath -ErrorAction Stop)
        {
            $StatusPathExists = $true
        }
    Else
        {
            $StatusPathExists = $False
            Write-Log $VMName": $VMName-Status$ share is not visible"
        }
    }
    Catch [UnauthorizedAccessException]
    {
        $StatusPathExists = $true
    }
#IF there are an  equal number of start files end files then we can proceed 
IF ($StatusPathExists -eq $True)
    {
        New-PSDrive -Name "Q" -Root $StatusPath -PSProvider "FileSystem" -Credential $cred
        $StatusStarts = (get-ChildItem -Path "Q:" *Start.txt | Measure-Object).count
        $StatusFinish = (get-ChildItem -Path "Q:" *Finish.txt | Measure-Object).count

        Write-Log $VMName": Number of Starts is $StatusStarts"
        Write-Log $VMName": Number of Finish is $StatusFinish"
        
        If ($StatusStarts -eq $StatusFinish)
        {
            write-log $VMName": We can do a Checkpoint"
            #check to see if there is a backup drive attached to the vm
            #IF there is a drive capture the path, in case the drive is VHD and not a usb drive
            If (Get-VM $VMName | Get-VMHardDiskDrive -ControllerType SCSI -controllernumber 0 -controllerlocation 0 -ne $Null)
            {
                    Write-Log "$VMName has no backup drive"
            }
            #Remove WSB drive from VM
            #Get-vm $VMName | get-vmharddiskdrive -controllertype SCSI -controllernumber 0 -controllerlocation 0 | remove-vmharddiskdrive
            
            #If the drive cannot be unmounted email alert
            #Do the Rolling Checkpoint on the VM
                #if the dismount of the drive is successful or there is no backup drive then add vm to a file that the existing rolling checkpoint function will use 
               
                $FormatedDate = Formated-Date
                Write-Log "The formated date is $FormatedDate"
                
                $TestFunction = testvariable
                Write-Log "Text from TestFunction is $testFunction"
                # after checkpoint is done - how is this returned?
                # if the checkpoint guid id can be  returned then i can be searched on the eventvwr on host
            #Attach the WSB drive to the VM
            #add-VMHardDiskDrive -VMName $VMName -controllertype SCSI -controllernumber 0 -controllerlocation 0 -path D:\Virtual\SHEP-EXCH-001\SHEP-EXCH-001-Backup.Vhdx
            #Get-VM $VMName | Add-VMHardDiskDrive -ControllerType SCSI -ControllerNumber 0 -controllerlocation 0 -disknumber 3
        }
        else
        {
            write-log $VMName": Error: Cannot CheckPoint: a process is still unfinished"
        }
        Remove-PSDrive -Name "Q"
    }