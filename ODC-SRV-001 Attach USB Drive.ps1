#ODC-SRV-001 Attach USB Drive
#ODC-SQL-002 Attach USB Drive

add-VMHardDiskDrive -VMName ODC-SRV-001 -controllertype SCSI -controllernumber 0 -controllerlocation 0 -path I:\Backups\VHDX\ODC-SRV-001-Backup.Vhdx
add-VMHardDiskDrive -VMName ODC-SQL-002 -controllertype SCSI -controllernumber 0 -controllerlocation 2 -path I:\Backups\VHDX\ODC-SQL-002-Backup.Vhdx