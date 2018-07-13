#disk size check

$disk = Get-WmiObject win32_LogicalDisk -Filter "DeviceID='F:'" | Select-Object Size,FreeSpace

$diskFreeSpace = [Math]::Round($disk.FreeSpace/1gb,2)
$diskSize = [Math]::Round($disk.Size/1gb,2)
$dataChange = [Math]::Round(8463589127/1gb,2)
$dataSizeDiff = $diskFreeSpace-$dataChange

if ($dataChange -lt $diskFreeSpace )
{
    Write-host 'There is room for this backup with ' $dataSizeDiff ' GB remaining.'
}
else {
    Write-host 'There is not enough disk space.  The amount of diskspace required is ' $dataChange ' GB and only ' $diskFreeSpace ' GB is remaining.'
}



Write-host 'This is the amount of free space '$diskFreeSpace' GB'
Write-host 'This is the size of the disk'$diskSize' GB'
write-host 'This is the amount of changed data '$dataChange ' GB'
write-host 'This is how much disk space will be left '$dataSizeDiff ' GB'