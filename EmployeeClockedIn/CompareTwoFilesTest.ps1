#CompareTwoFiles

$CompareResults = Compare-Object -ReferenceObject (Get-Content -Path "F:\Data\Scripts\Github\Powershell\EmployeeClockedIn\ITR-EmployeeClockedIn.txt") -DifferenceObject (Get-Content -Path "F:\Data\Scripts\Github\Powershell\EmployeeClockedIn\ITR-EmployeeClockedInTemp.txt") | Select -ExpandProperty InputObject

If ($null -eq $CompareResults)
{
    Write-Host "The files are the same"
}
else {
    Write-host "The files are different"
}