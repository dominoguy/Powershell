#Radius Log File Clean Up
#Brian Long 18Jan2021

#Cleans up excessive Radius log files keeping only one month's worth

param(
        [Parameter(Mandatory=$true,HelpMessage='Radius Log File Directory')][string]$LogDirectory
    )

$limit = (Get-Date).AddDays(-30)

#Delete files older than the $limit
Get-ChildItem -Path $LogDirectory -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force

# Delete any empty directories left behind after deleting the old files.
#Get-ChildItem -Path $LogDirectory -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse