#SetDriveLetter
#This script sets the drive letter based on the Disk's UniqueID

param(
        [Parameter(Mandatory=$False,HelpMessage='Disk UniqueID')][string]$vmDiskUniqueID,
        [Parameter(Mandatory=$False,HelpMessage='Windows Server Drive')][string]$vmBackupTarget
)

$disk = get-disk | Where-Object UniqueId -eq $vmDiskUniqueID
$diskNumber = $disk.DiskNumber

#Check to see if drive letter is being used by CD/DVD device
$DriveCheck = (Get-WmiObject -class win32_cdromdrive -property drive).drive
$DriveCheck = $DriveCheck.trim(":")
If ($DriveCheck -eq $vmBackupTarget)
{
    Return $False,"Drive letter is in use by CD/DVD device"
}
else {
    #check to see if the driver letter is in use by a disk and it is assigned to the proper disk if not error otherwise set it
    $partition = Get-Partition | Where-Object -FilterScript {$_.DriveLetter -Eq "$vmBackupTarget"}
    IF ($null -eq $partition)
    {
        Get-Partition | Where-Object {($_.DiskNumber -eq $diskNumber) -and ($_.Type -eq "Basic")} | Set-Partition -NewDriveLetter $vmBackupTarget
        Return $true,"No Drive E Letter assigned. Assigning Drive E to target drive"
    }
    elseif ($partition.Disknumber -eq $diskNumber) 
    {
        Return $true,"Drive E is assigned to the correct drive"
    }
    else 
    {
        Return $False,"Drive E is NOT assigned to the correct drive"
    }
}




