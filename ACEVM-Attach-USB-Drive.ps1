#ACE-HDC-001 Attach USB Drive
#ACE-FS-001 Attach USB Drive
#ACE-RDS-001 Attach USB Drive

add-VMHardDiskDrive -VMName ACE-HDC-001 -controllertype SCSI -controllernumber 0 -controllerlocation 4 -path F:\Backups\VHDX\ACE-HDC-001-Backup.Vhdx
add-VMHardDiskDrive -VMName ACE-FS-001 -controllertype SCSI -controllernumber 0 -controllerlocation 6 -path F:\Backups\VHDX\ACE-FS-001-Backup.Vhdx
add-VMHardDiskDrive -VMName ACE-RDS-001 -controllertype SCSI -controllernumber 0 -controllerlocation 4 -path F:\Backups\VHDX\ACE-RDS-001-Backup.Vhdx
