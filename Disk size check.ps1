#disk size check

$disk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='F:'" | Select-Object Size,FreeSpace

$diskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
$diskSize = [Math]::Round($disk.Size/1gb,2)

Write-host 'This is the amount of free space '$diskFreeSpace' GB'
Write-host 'This is the size of the disk'$diskSize' GB'
$dataChange = [Math]::Round(8463589127/1gb,2)
write-host 'This is the amount of changed data '$dataChange ' GB'

$dataSizeDiff = $diskFreeSpace-$dataChange
write-host 'This is how much disk space will be left '$dataSizeDiff ' GB'
 