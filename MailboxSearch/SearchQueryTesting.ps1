#SearchQuery Testing


function Write-Log
{
    Param(
        [string]$logstring)

    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
}

#get the current date in the format of  month-day-year
$curDate = Get-Date -UFormat "%m-%d-%Y"

$logFile = "$PSScriptRoot\Logs\QuerySearchTest.log"
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

$SearchVarCSV = Import-csv -Path "$PSScriptRoot\SearchVariables.csv"

ForEach($Key in $SearchVarCSV)
{
    $ToEntry = $Key.To
    If(-Not [String]::IsNullOrWhiteSpace($ToEntry))
    {
        IF($null -NE $ToString)
        {
            $ToString = $ToString + " OR " + '"' + $ToEntry + '"'
        }
        else {
            $ToString = "TO:" + '"' + $ToEntry + '"'
        }
    }

    $FromEntry = $Key.From
    If(-Not [String]::IsNullOrWhiteSpace($FromEntry))
    {
        IF($null -NE $FromString)
        {
            $FromString = $FromString + " OR " + '"' + $FromEntry + '"'
        }
        else {
            $FromString = "From:" + '"' + $FromEntry + '"'
        }
    }
    
    $KeyEntry = $Key.Keyword
    If(-Not [String]::IsNullOrWhiteSpace($KeyEntry))
    {
        IF($null -NE $KeyString)
        {
            $KeyString = $KeyString + " OR " + '"' + $KeyEntry + '"'
        }
        else {
            $KeyString = '"' + $KeyEntry + '"'
        }
    }
}

If (-Not [String]::IsNullOrWhiteSpace($FromString))
{
    If(-Not [String]::IsNullOrWhiteSpace($ToString))
    {
    $FromString = " AND " + $FromString
    }
}

If (-Not [String]::IsNullOrWhiteSpace($KeyString))
{
    If(-Not [String]::IsNullOrWhiteSpace($ToString) -or -Not [String]::IsNullOrWhiteSpace($FromString))
    {
    $KeyString = " AND " + $KeyString
    }
}



$SearchQuery = "'" + $ToString + $FromString + $KeyString + "'"

Write-Log "The keywords are $KeyString"
Write-Log "The To addresses are $ToString"
Write-Log "The From addresses are $FromString"
Write-Log "This is the SearchQuery String: $SearchQuery"



#:IsNullOrWhiteSpace

