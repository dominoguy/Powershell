#CompareTwoFiles

#$CompareResults = Compare-Object -ReferenceObject (Get-Content -Path "F:\Data\Scripts\Github\Powershell\EmployeeClockedIn\ITR-EmployeeClockedIn.txt") -DifferenceObject (Get-Content -Path "F:\Data\Scripts\Github\Powershell\EmployeeClockedIn\ITR-EmployeeClockedInTemp.txt") | Select-Object -ExpandProperty InputObject

#If ($null -eq $CompareResults)
#{
#    Write-Host "The files are the same"
#}
#else {
#    Write-host "The files are different"
#}

#$File = "F:\Data\scripts\Github\Powershell\EmployeeClockedIn\Test2.log"

#$contents = (Get-Content -Path $File).Trim([char]'`r')
#$contents = (Get-Content -Path $File) -Replace "`n",","
#$contents = (Get-Content -Path $File).Trim()
#$contents = (Get-Content -Path $File)
#$charcount = $contents.Length
#Write-host "Character count = $charcount"
#IF($NULL -eq $contents){
#write-host "File contents are empty"
#}
#else {
#    write-host "File is populated. contents = $contents"
#}

<#
$contents = (Get-Content -Path $File)
#IF ([string]::IsNullOrWhitespace($contents)){'empty'} else {'not empty'}
$EmptyOrNot = IF ([string]::IsNullOrWhitespace($contents)){$True} else {$False}

Write-host $EmptyOrNot
if ($EmptyOrNot -eq $False) {
    write-host "File is populated. contents = $contents"
}
#>

function Test-SQLConnection
{    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        $ConnectionString
    )
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();

        return $true;
    }
    catch
    {
        return $false;
    }
}

$SQLInstance = "ACE-SRV-001\ITR"

$SQLServer = "ACE-SRV-001"
$SQLDatabase = "ITR"
$SQLUser = "itrscript"
$SQLPWD = "sklDjfq34028217jcNvlan4e"

#$SQLUp = Test-SQLConnection "Data Source=$SQLServer;database=$SQLDatabase ;User ID=$SQLUser;Password=$SQLPWD;"
$SQLUp = Test-SQLConnection -ServerName $SQLServer -DatabaseName $SQLDatabase User ID=$SQLUser;Password=$SQLPWD;"

write-host "IS the SQL Server up: $SQLUP"