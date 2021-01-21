#Compare 2 CSV files and copy the differences into a third CSV.
#Intended to be used to compare Active user list and a list of active AD accounts, the difference are accounts to be removed from AD
#Required Employee ID must be a number and files need to be CSV
#NOTE: It is possible that there is an user in ActiveEmployees.csv that is active but not in AD.


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

$LogLocation = 'F:\Data\Scripts\Powershell\LOGS\CompareAccountLists.log'
$logFile = $LogLocation
$logFileExists = Test-Path -path $logFile

if ( $logFileExists -eq $True)
{
    Remove-Item $logFile
    #New-Item -ItemType File -Force -Path $logFile
}
else
{
    #New-Item -ItemType File -Force -Path $logFile
}

Write-Log "Starting UserAccount Check"

$ADUsers = import-csv -path 'F:\Data\Scripts\Powershell\CompareAccountLists\ADUsers.csv'
$ActiveEmployees = import-csv -path 'F:\Data\Scripts\Powershell\CompareAccountLists\ActiveEmployees.csv'

#put the list in an object and loop through each 
#Using the SideIndicator put the different AD Users (<=) in the TobeDisabled.csv and the different active employee users (=>) in ToBeResolved.csv
$compare = Compare-Object $ADUsers $ActiveEmployees -property Employee

If ($compare) {
    #Create ToBeDeleted CSV file
    $CSVToBeDisabled = "F:\Data\Scripts\Powershell\CompareAccountLists\ToBeDisabled.csv"
    $CSVFileExists = Test-Path -path $CSVToBeDisabled
    if ( $CSVFileExists -eq $True)
    {
        Remove-Item $CSVToBeDisabled
        New-Item -ItemType File -Force -Path $CSVToBeDisabled
        Get-Content -Path $CSVToBeDisabled
        $CreateHeaders= [PSCustomObject]@{
            Employee = ""
            LastName = ""
            FirstName = ""
            Department = ""
            Title = ""
            EmailAddress = ""
        }
        $CreateHeaders | Export-CSV $CSVToBeDisabled -Append -NoTypeInformation
    }
    else
    {
        New-Item -ItemType File -Force -Path $CSVToBeDisabled
        Get-Content -Path $CSVToBeDisabled
        $CreateHeaders= [PSCustomObject]@{
            Employee = ""
            LastName = ""
            FirstName = ""
            Department = ""
            Title = ""
            EmailAddress = ""
        }
        $CreateHeaders | Export-CSV $CSVToBeDisabled -Append -NoTypeInformation
    }

    #Create ToBeResolved CSV file
        $CSVToBeResolved = "F:\Data\Scripts\Powershell\CompareAccountLists\ToBeResolved.csv"
        $CSVFileExists = Test-Path -path $CSVToBeResolved
        if ( $CSVFileExists -eq $True)
        {
            Remove-Item $CSVToBeResolved
            New-Item -ItemType File -Force -Path $CSVToBeResolved
            Get-Content -Path $CSVToBeResolved
            $CreateHeaders= [PSCustomObject]@{
                Employee = ""
                LastName = ""
                FirstName = ""
                Facility = ""
                Service = ""
                Department = ""
                Job = ""
                WLADDR4 = ""
            }
            $CreateHeaders | Export-CSV $CSVToBeResolved -Append -NoTypeInformation
        }
        else
        {
            New-Item -ItemType File -Force -Path $CSVToBeResolved
            Get-Content -Path $CSVToBeResolved
            $CreateHeaders= [PSCustomObject]@{
                Employee = ""
                LastName = ""
                FirstName = ""
                Facility = ""
                Service = ""
                Department = ""
                Job = ""
                WLADDR4 = ""
            }
            $CreateHeaders | Export-CSV $CSVToBeResolved -Append -NoTypeInformation
        }
        

foreach ($User in $compare) 
 {  
    #If the sideindicator is <= then
    #find the entry in ADUsers.csv
    #take the whole row and put into ToBeDisabled.csv.
    $Employee = $user.Employee
    $Side = $user.SideIndicator
  
    If ($Side -eq "<=") 
        {
            Write-Log "$Employee is in ADUsers.csv and needs to be disabled"
            $ADUsers | Where-Object {$_.Employee -eq $Employee} | Export-CSV $CSVToBeDisabled -Append -NoTypeInformation
        }
    #If the sideindicator is => then
    #find the entry in ActiveEmployees.csv
    #take the whole row and put into ToBeResolved.csv.
    if ($Side -eq "=>")
        {
            Write-Log "$Employee is in ActiveEmployees and needs to be resolved"
            $ActiveEmployees | Where-Object {$_.Employee -eq $Employee} | Export-CSV $CSVToBeResolved -Append -NoTypeInformation
        }
    
 }
}

