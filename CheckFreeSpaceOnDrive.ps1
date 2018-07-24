#Check for free space on a drive
[int]$driveLimit = '100000000'
[int]$driveLimitMB = [Math]::Round('100000000'/1mb,2)

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='F:'"
Select-Object Size,FreeSapce

$disksize = $disk.size
$diskFree = $disk.Freespace
$disksizeMB = [Math]::Round($disk.size/1mb,2)
$diskFreeMB = [Math]::Round($disk.Freespace/1mb,2)

write-host 'The drive limit is ' $driveLimitMB ' MB'
write-host 'Total disk size is: '$disksizeMB' MB'
Write-Host 'Total free disk space is: '$diskFreeMB' MB'


[xml]$XmlDocument = Get-content -Path 'F:\Data\Scripts\Powershell\ACAWTSQL_Report.xml'

$LTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.lt.name
$LTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.lt.size
[int]$RawLTSize = $LTfolderdatasize -replace '[,]',''

$RTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.rt.name
$RTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.rt.size
[int]$RawRTSize = $RTfolderdatasize -replace '[,]',''


$RawBackupSize = $RTfolderdatasize-$LTfolderdatasize
#[int]$RawBackupSize = '48273683'
$BackupSize = [Math]::Round($RawBackupSize/1mb,2)

Write-Host 'This is the size of the backup: '$BackupSize 'MB'

$SpaceRemain = $diskFree - $RawBackupSize
$SpaceRemainMB = [Math]::Round($SpaceRemain/1mb,2)

If ($SpaceRemain -gt $driveLimit)
 {
    Write-host 'There is room for the backup with ' $SpaceRemainMB 'Mb remaining'
 }
else
{
    Write-host 'Backup is too big. you need ' $SpaceRemain 'MB more'
}