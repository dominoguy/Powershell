#Get List of ADUsers by SID
#Brian Long 26AUG2021


param(
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath
    )


$ADUserFile = $OutPutFilePath + '\ADUsersSIDList.csv'
#Get the domain we are in 
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"

Get-ADUser -Filter * -SearchBase $domain -ResultPageSize 0 -Property Surname,GivenName,objectSID | Select-Object Surname,GivenName,objectSID | Export-CSV -NoType $ADUserFile
$Header = 'LastName','FirstName','SID'
$A = Get-Content -Path $ADUserFile
$A = $A[1..($A.Count - 1)]
$A | Out-File -FilePath $ADUserFile
$J = Import-Csv -Path $ADUserFile -Header $Header
$J | Export-CSV -NoType $ADUserFile
