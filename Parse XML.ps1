#Parse XML File

#Pass in  what you are looking into the script
#create the xml as an object
#locate your object and retrieve your properties.

[xml]$XmlDocument = Get-content -Path 'F:\Data\Scripts\Powershell\ACAWTSQL_Report.xml'
# $XmlDocument.GetType().FullName
$LTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.lt.name
$LTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.lt.size

[int]$RawLTSize = $LTfolderdatasize -replace '[,]',''

#$LTFolderSize = [Math]::Round($RawLTSize/1mb,2)
#write-host 'The Left folder ' $LTfolderdata 'is' $LTFolderSize 'MB'

$RTfolderdata = $XmlDocument.bcreport.foldercomp.foldercomp.rt.name
$RTfolderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.rt.size

[int]$RawRTSize = $RTfolderdatasize -replace '[,]',''


$backupSize = $RTfolderdatasize-$LTfolderdatasize
$backupSizeMB  = [Math]::Round($backupSize/1mb,2)

write-host 'The data size of the backup is ' $backupSizeMB 'MB'
