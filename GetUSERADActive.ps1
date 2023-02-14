#Get List of Users by Name Job and Email address
#Ver 1.0 Brian Long 03June2020
#Ver 1.1 Brian Long 09Dec2021 - Added LastLogonDate

#Users must have an employee number and be enabled to qualify as active

param(
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath
    )

$ADUserFile = $OutPutFilePath + '\ADUsersList.csv'
#Get the domain we are in
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"

Get-ADUser -Filter {Enabled -eq $True} -SearchBase $domain -ResultPageSize 0 -Property Employeenumber,Surname,GivenName,physicalDeliveryOfficeName,Title,Department,EmailAddress,lastLogon | Select-Object Employeenumber,Surname,GivenName,physicalDeliveryOfficeName,Title,Department,EmailAddress,{[datetime]::FromFileTime( $_.lastLogon)} | Export-CSV -NoType $ADUserFile
$Header = 'Employee','LastName','FirstName','Facility','Department','Title','EmailAddress','LastLogon'
$A = Get-Content -Path $ADUserFile
$A = $A[1..($A.Count - 1)]
$A | Out-File -FilePath $ADUserFile
$J = Import-Csv -Path $ADUserFile -Header $Header
$J | Export-CSV -NoType $ADUserFile
