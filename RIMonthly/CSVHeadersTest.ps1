#CSVHeadersTest
#Nooopeeee
$CSVPath = "F:\Data\Scripts\Powershell\RIMonthly\TestCSV.csv"

$testcsv = New-Item -ItemType "File" -Force -Path $CSVPath
$Headerset = Get-Content -path $CSVPath | Select-object Client,servername,directory
$Headerset | Export-CSV $CSVPath
