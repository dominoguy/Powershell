#ODC-SRV-001 Attach USB Drive

add-VMHardDiskDrive -VMName ODC-SRV-001 -controllertype SCSI -controllernumber 0 -controllerlocation 0 -path H:\Backups\VHDX\ODC-SRV-001-Backup.Vhdx
