#Get List of Users by Name Job and Email address
#Brian Long 03June2020

#Users must have an employee number and be enabled to qualify as active

param(
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath
    )


$ADUserFile = $OutPutFilePath + '\UserByEmailAddress.csv'
#Get the domain we are in 
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"

Get-ADUser -Filter {employeeNumber -like '*' -And Enabled -eq $True} -SearchBase $domain -ResultPageSize 0 -Property Surname,GivenName,Initials,Title,EmailAddress,Employeenumber | Select-Object Surname,GivenName,Initials,Title,EmailAddress,EmployeeNumber | Export-CSV -NoType $ADUserFile
$Header = 'LastName','FirstName','MiddleInitial','Title','EmailAddress','EmployeeNumber'
$A = Get-Content -Path $ADUserFile
$A = $A[1..($A.Count - 1)]
$A | Out-File -FilePath $ADUserFile
$J = Import-Csv -Path $ADUserFile -Header $Header
$J | Export-CSV -NoType $ADUserFile
