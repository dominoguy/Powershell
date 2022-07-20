#DateTesting

$curMonth = Get-Date -UFormat "%m"
#$curMonth = "01"
$curYear = Get-Date -UFormat "%Y"
If ($curMonth -eq "01")
 {
    $prevMonth = "12"
    $prevYear = $curYear-1
 }
else
 {
    $prevMonth = $curmonth-1
    $prevYear = $curYear
 }
#Adds a leading "0" if month is a single digit
$prevMonth = "{0:d2}" -f $prevmonth

Write-host "The current month is $curmonth"
Write-host "The current year is $curYear"
Write-host "The previous month is $prevMonth"
Write-host "The previous year is $prevYear"




