#Check for free space on a drive
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='F:'"
Select-Object Size,FreeSapce
$disksize = [Math]::Round($disk.size/1gb)
$diskFree = [Math]::Round($disk.Freespace/1gb)

write-host 'Total disk size is: '$disksize' GB'
Write-Host 'Total free disk space is: '$diskFree' GB'


[int]$RawBackupSize = "30514297"/1gb
$BackupSize = [Math]::Round($RawBackupSize)

Write-Host 'This is the size of the backup: '$BackupSize 'GB'

