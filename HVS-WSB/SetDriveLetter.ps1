#SetDriveLetter
#This script sets the drive letter based on the Disk's UniqueID

param(
        [Parameter(Mandatory=$False,HelpMessage='Disk UniqueID')][string]$vmDiskUniqueID,
        [Parameter(Mandatory=$False,HelpMessage='Windows Server Drive')][string]$vmBackupTarget
)

$disk = get-disk | Where-Object UniqueId -eq $vmDiskUniqueID
$diskNumber = $disk.DiskNumber

#check to see if the driver letter is in use and it is assigned to the proper disk if not error otherwise set it
$partition = Get-Partition | Where-Object -FilterScript {$_.DriveLetter -Eq "$vmBackupTarget"}

IF ($null -eq $partition)
    {
        Get-Partition | Where-Object {($_.DiskNumber -eq $diskNumber) -and ($_.Type -eq "Basic")} | Set-Partition -NewDriveLetter $vmBackupTarget
        Return $true
    }
elseIf ($partition.Disknumber -eq $diskNumber) 
    {
        Return $true
    }
else 
    {
        Return $False
    }





