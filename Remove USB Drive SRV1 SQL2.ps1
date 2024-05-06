#ODC-SRV-001 Remove USB Drive
#ODC-SQL-002 Remvoe USB Drive

Remove-VMHardDiskDrive -VMName ODC-SRV-001 -controllertype SCSI -controllernumber 0 -controllerlocation 0
Remove-VMHardDiskDrive -VMName ODC-SQL-002 -controllertype SCSI -controllernumber 0 -controllerlocation 2