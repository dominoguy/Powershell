#Testing SMB Drive Mapping

$BackupDrive = "m:"
$TestPath = Test-Path -Path $backupDrive
IF ($TestPath) {
    Remove-SMBMapping -Force -LocalPath 'm:'
    New-SMBMapping -LocalPath 'm:' -RemotePath '\\ri-dt-019.ri.ads\l$' -UserName  'ri\backupservice' -password 'sYlhmMh62dNRuP74Sl03'
    Write-Host "M: existed, deleted and re-created"
}
Else {
    New-SMBMapping -LocalPath 'm:' -RemotePath '\\ri-dt-019.ri.ads\l$' -UserName  'ri\backupservice' -password 'sYlhmMh62dNRuP74Sl03'
    Write-host "M: did not exist and created"
}

#Close the mapped drive 
#Remove-SMBMapping -Force -LocalPath 'm:'