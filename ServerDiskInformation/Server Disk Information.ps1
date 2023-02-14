#Server Disk Information
#This script gathers disk information on a computer

#log onto server
# test if data directories exist on datasize check

function ConvertToGB ($Size)
    {$a = [Math]::Round($Size/1gb,2)
    Return $a
}


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$LogLocation = 'F:\Data\Scripts\Powershell\ServerDiskInformation\Logs\ServerDiskUsage.log'
$CredList = Import-CSV -Path "F:\Data\Scripts\Powershell\ServerList\CredList.csv"
$ServerCSV = 'F:\Data\Scripts\Powershell\ServerDiskInformation\ServerList.csv'
$ResultsCSV = "F:\Data\Scripts\Powershell\ServerDiskInformation\$curdate-ServerDiskUsage-Results.csv"

$logFile = $LogLocation
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    New-Item -ItemType File -Force -Path $logFile
}
else
{
    New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Starting Server Disk Usage Check"

#Create results file
$ResultsExists = Test-Path -path $ResultsCSV
$Headers = '"ServerName","DriveName","DiskSize","UsedSpace","FreeSpace","DataSize"'
if ( $ResultsExists -eq $True)
{
    Remove-Item $ResultsCSV
    #New-Item -ItemType File -Force -Path $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}
else
{
    #New-Item -ItemType File -Force -Path $ResultsCSV
    Add-Content -Path $ResultsCSV -Value $Headers
}

Write-Log "A Results File has been created"

$ServerList = Import-Csv $ServerCSV

foreach ($row in $Serverlist)
{
    #Get the client creds
    $Servername = $row.ServerName
    $ServerDrives = $row.Drives
    $ServerDataLoc = $row.DataDirectory

    Write-Log "Working on $ServerName"
    $Client = $CredList.Where({$PSItem.ServerName -eq $ServerName}).Client
    If (!$Client)
    {Write-Log "There is no credential entry for $Servername"}
    else
    {
        Write-Log "Checking $ServerName"
        $Domain = $CredList.Where({$PSItem.ServerName -eq $ServerName}).Domain
        $AdminName = $CredList.Where({$PSItem.ServerName -eq $ServerName}).AdminName
        $Password = $CredList.Where({$PSItem.ServerName -eq $ServerName}).Password
        $FQDN = "$Servername.$Domain"
        #Is the server up
        IF (Test-Connection -ComputerName $FQDN -Quiet)
        {
            #Create the creds to connect
            $Username = $Client + "\" + $AdminName
            $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword
    
            #Calculate hard disk usage
            $driveArray = $null
            $driveArray = $ServerDrives.split(',')
            Foreach ($Drive in $driveArray)
                {
                    $deviceIDName = "DeviceID ='$Drive'"
                    $parameters = @{
                        Credential = $cred
                        ComputerName = $FQDN
                        ScriptBlock = {
                        Param ($deviceIDName)
                            Get-WmiObject win32_LogicalDisk -Filter $deviceIDName | Select-Object Size,FreeSpace,DeviceID
                                }
                        ArgumentList = $deviceIDName
                    }

                    $disk = Invoke-Command @parameters
        
                    $diskName = $disk.DeviceID
                    $diskFreeSpace = ConvertToGB $disk.FreeSpace
                    $diskSize = ConvertToGB $disk.Size
                    $diskUsed = $diskSize - $diskFreeSpace
    
                    $Results = [PSCustomObject]@{
                        ServerName = "$Servername"
                        DriveName = "$diskName"
                        DiskSize = "$diskSize"
                        UsedSpace = "$diskUsed"
                        FreeSpace = "$diskFreeSpace"
                        DataSize = ""
                    } 
                    $Results | Export-Csv -Path $ResultsCSV -Append -NoTypeInformation
                 }
            write-host "Done calculating disk sizes"
            #Calculate Data directory size
            $dataArray = $null
            $dataArray = $ServerDataLoc.split(',')
            $sizeResult = 0
            ForEach ($dataPath in $dataArray)
                {
                    $parameters = @{
                        Credential = $cred
                        ComputerName = $FQDN
                        ScriptBlock = 
                            {
                                Param ($dataPath)
                                "{0:N2}" -f ((Get-ChildItem -Force $dataPath -recurse -ErrorAction SilentlyContinue | Where-Object {$_.linktype -notmatch "HardLink"} | Measure-Object length -s).sum/1gb)
                            }
                        ArgumentList = $dataPath
                    }
                    $dirSize = Invoke-Command @parameters
                    $sizeResult = $sizeResult + $dirSize
                }
            $Results = [PSCustomObject]@{
            ServerName = "$Servername"
            DriveName = ""
            DiskSize = ""
            UsedSpace = ""
            FreeSpace = ""
            DataSize = "$sizeResult"
            } 
            $Results | Export-Csv -Path $ResultsCSV -Force -Append -NoTypeInformation
            write-host "the size of the data is $sizeResult"
        }
        else {
        Write-Log "$FQDN is not available"
        }
    }
    Write-Log "End Check on $ServerName"
}
Write-Log "End Server Disk Usage Check"