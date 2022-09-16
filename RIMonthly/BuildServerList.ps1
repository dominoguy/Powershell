#This script builds the monthly backup serverlist for specified clients.

<#
.SYNOPSIS
This script is part of a monthly backup process where a client server has too much data to use Beyond Compare to do a backup in one sitting.

.DESCRIPTION
This script compiles a list of the directories under the data and so that Beyond Compare will act on each one individually.

.PARAMETER LogLocation
Location of log file and its name
IE. F:\Data\Scripts\Powershell\RIMonthly\LOGS\<date>.log

#>

#Get a list of servers
#$ListofServers = "F:\Data\Scripts\Powershell\RIMonthly\BuildBackupServerList.csv"
$ListofServers = "D:\Backups\RIBackup\RIMonthly\BuildBackupServerList.csv"
$Servers = Import-CSV $ListofServers | select-object -Property Client,Server,BaselinesDir,BackupsDir,ListDir,Divide,Root,MonthlyDrive
$Entry  = $Servers | Select-Object -Property Listdir | Select-Object -First 1
$ListDir = $Entry.ListDir
$ServersList = "$ListDir\ServersList.csv"
$CSVFileExists = Test-Path -path $ServersList

if ($CSVFileExists -eq $True)
{
    Remove-Item $ServersList
    New-Item -ItemType File -Force -Path $ServersList
    Get-Content -Path $ServersList
    $CreateHeaders= [PSCustomObject]@{
        Client = ""
        ServerName = ""
        BaselinesDir = ""
        BackupsDir = ""
        DataDir = ""
        MonthlyDir = ""
        Exempt = ""
    }
    $CreateHeaders | Export-CSV $ServersList -Append -NoTypeInformation
    (Get-Content $ServersList |  Select -First 1) | Out-File $ServersList
}
else
{
    New-Item -ItemType File -Force -Path $ServersList
    Get-Content -Path $ServersList
    $CreateHeaders= [PSCustomObject]@{
        Client = ""
        ServerName = ""
        BaselinesDir = ""
        BackupsDir = ""
        DataDir = ""
        MonthlyDir = ""
        Exempt = ""
    }
    $CreateHeaders | Export-CSV $ServersList -Append -NoTypeInformation
    (Get-Content $ServersList |  Select -First 1) | Out-File $ServersList
}

#loop through list, building a server list for the monthly backups
Foreach ($Server in $Servers) 
{ 
    $client = $Server.Client
    $Servername = $Server.Server
    $Baselines = $Server.BaselinesDir
    $BackupsDir = $Server.BackupsDir
    $ListDir = $Server.ListDir
    $Divide = $Server.Divide
    $Root = $Server.Root
    $MonthlyDrive = $Server.MonthlyDrive

    $ServerPath = "$BackupsDir\$Client\$ServerName\$Root"
    $Results = [PSCustomObject]@{
        Client = "$Client"
        ServerName = "$ServerName"
        BaselinesDir = "$Baselines\$client\$Servername"
        BackupsDir = "$BackupsDir\$client\$Servername"
        DataDir = "$Root"
        MonthlyDir = "$MonthlyDrive"
        Exempt = $Divide
    }
   $Results | Export-CSV -Path $ServersList -Append -NoTypeInformation

   $ExemptionList = "$ListDir\$ServerName-$Root-ExemptionList.csv"
   $ExemptionListExists = Test-Path -path $ExemptionList
    if ($ExemptionListExists -eq $True)
    {
        Remove-Item $ExemptionList
        New-Item -ItemType File -Force -Path $ExemptionList
        Get-Content -Path $ServersList
        $ExemptHeaders= [PSCustomObject]@{
            ExemptDir = ""
        }
        $ExemptHeaders | Export-CSV $ExemptionList -Append -NoTypeInformation
        (Get-Content $ExemptionList |  Select -First 1) | Out-File $ExemptionList
    }
    else
    {
        New-Item -ItemType File -Force -Path $ExemptionList
        Get-Content -Path $ExemptionList
        $ExemptHeaders = [PSCustomObject]@{
             ExemptDir = ""
        }
        $ExemptHeaders | Export-CSV $ExemptionList -Append -NoTypeInformation
        (Get-Content $ExemptionList |  Select -First 1) | Out-File $ExemptionList
    }


    If ($Divide -eq "T")
    {
        #Get the subdirecties from "Root" and add them to the server list
        $ServerPath = "$BackupsDir\$Client\$ServerName\$Root"
        $FolderList = Get-ChildItem -Directory -Path $ServerPath
        Foreach ($folder in $FolderList)
        {
            $Results = [PSCustomObject]@{
                Client = "$Client"
                ServerName = "$ServerName"
                BaselinesDir = "$Baselines\$client\$Servername"
                BackupsDir = "$BackupsDir\$client\$Servername"
                DataDir = "$Root\$folder"
                MonthlyDir = "$MonthlyDrive"
                Exempt = "F"
            }
           $Results | Export-CSV -Path $ServersList -Append -NoTypeInformation
        #Create a an exemption list for root monthly
            $Exemptions = [PSCustomObject]@{
                ExemptDir = "$Folder"
            }
            $Exemptions | Export-CSV -Path $ExemptionList -Append -NoTypeInformation


        }
    }
}