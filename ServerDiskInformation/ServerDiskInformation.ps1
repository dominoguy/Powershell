#Server Disk Information
#This script gathers disk information on a computer

#log onto server
# test if data directories exist on datasize check

#NOTES:
#WINRM must be running on target servers
#2012 and later it is on by default
#Need to run locally on 2008 and earlier machines to configure WINRM - winrm quickconfig
#On the workstation/Server running the script, need WSMAN trustedhosts set
#in code should add -value * for trusted hosts then use clear-item to clear the setting
#unless other code requires it. Be aware of what is currently in the trusted hosts.
#also this will not work on 2003 servers
#Get-Item WSMan:\localhost\Client\TrustedHosts, store the list
#Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*'
#Clear-Item -Path WSMan:\localhost\Client\TrustedHosts -Force, then put back the prior list

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

$LogLocation = 'F:\Data\Scripts\GitHub\Powershell\ServerDiskInformation\Logs\ServerDiskUsage.log'
$CredList = Import-CSV -Path "F:\Data\Scripts\GitHub\Powershell\ServerList\CredList.csv"
$ServerCSV = 'F:\Data\Scripts\GitHub\Powershell\ServerList\ServerList.csv'
$ResultsCSV = "F:\Data\Scripts\GitHub\Powershell\ServerDiskInformation\$curdate-ServerDiskUsage-Results.csv"

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
#Allow PSRemoting to servers - TrustedHosts
#Write-Log "Setting TrustedHosts"
#Write-Host "Setting TrustedHosts"
#Set-Item WSMan:\localhost\Client\TrustedHosts -Value *

foreach ($row in $Serverlist)
{
    #Get the client creds
    $Servername = $row.ServerName
    $ServerDrives = $row.Drives
    $ServerDataLoc = $row.DataDirectory

    Write-Log "Working on $ServerName"
    $Client = $CredList.Where({$PSItem.ServerName -eq $ServerName}).Client
    If (!$Client)
    {Write-Log "***** There is no credential entry for $Servername *****"}
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
            Write-Log "A connection to $FQDN can be made."
            Write-Host "Connecting to $FQDN"
            $Username = $Client + "\" + $AdminName
            $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword
    
            $Session = New-PSSession -ComputerName $FQDN -Credential $cred
            Write-host $Session
            IF ($Session.State -eq "Opened")
            {
                #Calculate hard disk usage
                $driveArray = $null
                $driveArray = $ServerDrives.split(',')
                #USE a new ps session
                Foreach ($Drive in $driveArray)
                {
                    Write-host "The drive we are working on is $Drive"
                    $deviceIDName = "DeviceID ='$Drive'"
                    $parameters = @{
                        #Credential = $cred
                        Session = $Session
                        #ComputerName = $FQDN
                        ScriptBlock = {
                        Param ($deviceIDName)
                            Get-WmiObject win32_LogicalDisk -Filter $deviceIDName | Select-Object Size,FreeSpace,DeviceID
                                }
                        ArgumentList = $deviceIDName
                    }

                    #Clearing the disk variables
                    $diskName = ""
                    $diskFreeSpace = ""
                    $diskSize = ""
                    $diskUsed = ""

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
                 Write-Log "Done calculating disk sizes"
                #Calculate Data directory size
                $dataArray = $null
                $dataArray = $ServerDataLoc.split(',')
                $sizeResult = 0
                ForEach ($dataPath in $dataArray)
                {
                    write-host "the data path is $datapath"
                    Write-Host "session for data size is $session"
                    $parameters = @{
                        #Credential = $cred
                        Session = $Session
                        #ComputerName = $FQDN
                        ScriptBlock = 
                            {
                                Param ($dataPath)
                                "{0:N2}" -f ((Get-ChildItem -Force $dataPath -recurse -ErrorAction SilentlyContinue | Where-Object {$_.linktype -notmatch "HardLink"} | Measure-Object length -s).sum/1gb)
                            }
                        ArgumentList = $dataPath
                    }
                    $dirSize = Invoke-Command @parameters
                    Write-Log "$FQDN the data size on $datapath is $dirsize"
                    Write-host "$FQDN the data size on $datapath is $dirsize"
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
                Write-Log "Done calculating data size."
              
            }
            else {
                Write-Log "***** Could NOT open session to $FQDN *****"
                Write-Host "***** Could NOT open session to $FQDN *****"
            }
            Disconnect-PSSession -Name $Session
        }
        else {
        Write-Log "***** $FQDN is not available *****"
        }
    }
    Write-Log "End Check on $ServerName"
}
#End PSRemoting: Clear the Trustedhosts file
#Clear-Item WSMan:\localhost\Client\TrustedHosts
Write-Log "End Server Disk Usage Check"