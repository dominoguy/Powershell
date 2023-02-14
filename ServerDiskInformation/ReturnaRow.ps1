#Return a Row
#This script searches a csv and returns a row

$ServerList = Import-CSV -Path "F:\Data\Scripts\Powershell\ServerList\ServerList.csv"

$ServerName = "RI-Backup-008"

$AdminName = $ServerList.Where({$PSItem.ServerName -eq $ServerName}).AdminName
$Password = $ServerList.Where({$PSItem.ServerName -eq $ServerName}).Password

Write-host "The administrator name is $AdminName"

Write-host "The password name is $Password"