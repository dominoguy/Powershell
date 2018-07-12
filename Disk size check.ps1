#disk size check

$disk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='F:'" | Select-Object Size,FreeSpace

$DiskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
$DiskSize = [Math]::Round($disk.Size/1gb,2)

Write-host 'This is the amount of free space '$DiskFreeSpace' GB'
Write-host 'This is the size of the disk'$DiskSize' GB'
$DataChange = [Math]::Round(8463589127/1gb,2)
write-host 'This is the amount of changed data '$DataChange ' GB'

$datasizediff = $DiskFreeSpace-$DataChange
write-host 'This is how much disk space will be left '$datasizediff ' GB'
 