#Parse XML File

#Pass in  what you are looking into the script
#create the xml as an object
#locate your object and retrieve your properties.

[xml]$XmlDocument = Get-content -Path 'F:\Data\Scripts\Powershell\ACAWTSQL_Report.xml'
# $XmlDocument.GetType().FullName
$folderdata = $XmlDocument.bcreport.foldercomp.foldercomp.lt.name
$folderdatasize = $XmlDocument.bcreport.foldercomp.foldercomp.lt.size


write-host $folderdata
write-host $folderdatasize