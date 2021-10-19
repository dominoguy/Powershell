#ACE-HDC-001 Attach USB Drive
#ACE-FS-001 Attach USB Drive
#ACE-RDS-001 Attach USB Drive

Get-vm ACE-HDC-001 | get-vmharddiskdrive -controllertype SCSI -controllernumber 0 -controllerlocation 4 | remove-vmharddiskdrive
Get-vm ACE-FS-001 | get-vmharddiskdrive -controllertype SCSI -controllernumber 0 -controllerlocation 6 | remove-vmharddiskdrive
Get-vm ACE-RDS-001 | get-vmharddiskdrive -controllertype SCSI -controllernumber 0 -controllerlocation 4 | remove-vmharddiskdrive
