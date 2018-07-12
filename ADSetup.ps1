param(
    [Parameter(Mandatory)][string]$myCustomDomain,
    [string]$usersPath = "Userdata.csv",
    [string]$ousPath = "OUdata.csv"
    #[string]$myDomainPath = 
)

$password = Read-Host -AsSecureString "Universal Password"

#make use of AD module
Import-Module ActiveDirectory

#Dissect Domain Name
$domainPath = ''
[array]$sections = $myCustomDomain.Split('.')
foreach ($section in $sections){
    $domainPath = $domainPath + 'DC=' + $section + ','
}
#trim the extra comma
$domainPath = $domainPath.Substring(0,$domainPath.Length-1)

#Retrieve ous and users
$ListOU = Get-Content $ousPath
$ListUSER = Get-Content $usersPath

#Create each OU -Tested successfully!
foreach ($Unit in $ListOU){
    $path = ''

    [Array]$fields = $Unit -split ','
    $name = $fields[0]

    [Array]$nameFields = $name -split '-'
    foreach($ouName in $nameFields){
        $ouName = $ouName.Trim()
        if($path -eq ''){
            $ouPath = $path + $domainPath    
        } else {
            $ouPath = $path + ',' + $domainPath
        }
        $checkPath = 'LDAP://OU=' + $ouName + ',' + $ouPath
        try{
            if([adsi]::Exists($checkPath)){
                #write-host $checkPath ' exists'
            } else {
                write-host Creating $checkPath
                New-ADOrganizationalUnit -Name $ouName -Path $ouPath 
            }
        }
        catch{
            write-host 'There was something wrong with: ' $checkPath
        }
        if($path -eq ''){
            $path = 'OU=' + $ouName
        } else {
            $path = 'OU=' + $ouName + ',' + $path
        }
    }
}


#order of fields: EmployeeID	FirstName	LastName	Gender	City	UnitName	JobTitle	Address	username
#This creates each user according to their OU.
foreach ($userDetails in $ListUSER){
    #Dissect information
    #EmployeeID,FirstName,LastName,Gender,City,UnitName,JobTitle,Address,username
    [array]$feature = $userDetails -split ','

    [String]$fname = $feature[1]
    [String]$lname = $feature[2]
    [String]$city = $feature[4]
    [String]$UnitName = $feature[5]
    [String]$title = $feature[6]
    [String]$streetAddress = $feature[7]
    [String]$samAccountName = $feature[8]
    

    #dissect OU
    [array]$parts = $UnitName -split '-'
    $path = '' + $domainPath
    foreach($part in $parts){
        $path = 'OU=' + $part.Trim() + ',' + $path        
    }

    
    
    #Write-Host $path
    #$checkPath = 'LDAP://CN=' + $fname + ' ' + $lname + ',' + $path
    #Write-Host $checkPath

    try{
        if([bool] (Get-ADUser -Filter { SamAccountName -eq $SamAccountName })){
            Write-Host User: $samAccountName already exists! Renaming to: $samAccountName'1'
            $samAccountName = $samAccountName + '1'
            Write-Host Creating: $samAccountName
            New-ADUser -DisplayName "$fname $lname" -Name "$fname $lname" -GivenName $fname -Surname $lname -Path $path -Title $title -City $city -StreetAddress $streetAddress -SamAccountName $samAccountName -UserPrincipalName $samAccountName -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Company 'World Film Organization'
        } else {
            Write-Host Creating: $samAccountName
            New-ADUser -DisplayName "$fname $lname" -Name "$fname $lname" -GivenName $fname -Surname $lname -Path $path -Title $title -City $city -StreetAddress $streetAddress -SamAccountName $samAccountName -UserPrincipalName $samAccountName -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Company 'World Film Organization'
        }
        
    } catch {
        Write-Host There was an issue creating: $fname $lname with username: $samAccountName
        Write-Host Please ensure the user does not already exist
    }
}