#Get List of Active Members in a Group
#Ver 1.0 Brian Long 14Feb2023

param(
        [Parameter(Mandatory=$true,HelpMessage='Name of Group')][string]$GroupName,
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath
        #[Parameter(Mandatory=$False,HelpMessage='name of Group')][string]$GroupName,
        #[Parameter(Mandatory=$False,HelpMessage='OutPut Location')][string]$OutPutFilePath
    )


    function Write-Log
{
    Param(
        [string]$logstring)

    Add-Content $MembersFile -value "$logstring"
}

#$GroupName = "Renatus - Support Staff"
#$OutPutFilePath = "F:\Temp"
$MembersFile = $OutPutFilePath + "\$GroupName-Members.csv"
$GroupMemberofFile = $OutPutFilePath + "\$GroupName-MemberOf.csv"

$MembersFileExists = Test-Path -path $MembersFile
$Headers = '"Members"'
if ( $MembersFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $MembersFile
 Add-Content -Path $MembersFile -Value $Headers
}
else {
    Remove-Item $MembersFile
    New-Item -ItemType File -Force -Path $MembersFile
    Add-Content -Path $MembersFile -Value $Headers
}
$tempMembersFile = $OutPutFilePath + "\$GroupName-Members-Temp.csv"

$GroupmemberOfExists = Test-Path -path $GroupMemberofFile
$GHeaders = '"Memberof"'
if ( $GroupmemberOfExists -eq $False)
{
 New-Item -ItemType File -Force -Path $GroupMemberofFile
 Add-Content -Path $GroupMemberofFile -Value $GHeaders
}
else {
    Remove-Item $GroupMemberofFile
    New-Item -ItemType File -Force -Path $GroupMemberofFile
    Add-Content -Path $GroupMemberofFile -Value $GHeaders
}
$tempMembersOfFile = $OutPutFilePath + "\$GroupName-MembersOf-Temp.csv"

#Get the domain we are in
$userdomain = Get-ADDomain
$dc1 = $userdomain.DNSRoot.split('.')[0]
$dc2 = $userdomain.DNSRoot.split('.')[1]
$domain = "dc=$dc1,dc=$dc2"

$Members = Get-ADGroupMember $GroupName | Select-Object Name,ObjectClass

Foreach ($Member in $Members)
{
    $memberClass = $member.ObjectClass
    If ($memberClass -eq "User")
    {
        $User = $member.Name
        $UserObj = Get-ADUser -Filter "Name -eq '$User'" -SearchBase $domain -ResultPageSize 0 -Properties Enabled | Select-Object Enabled
        $Status = $UserObj.Enabled
   
        IF ($Status -eq $true)
            {
                $Results = [PSCustomObject]@{Members = "$User"} 
                $Results | Export-Csv -Path $tempMembersFile -Append -NoTypeInformation
            }
    }
    else 
    {
        $GroupMember = $member.Name
        $Results = [PSCustomObject]@{Members = "$GroupMember (G)"}
        $Results | Export-Csv -Path $tempMembersFile -Append -NoTypeInformation
        
    }
}
Import-Csv $tempMembersFile | Sort-Object Members | Export-Csv -Path $MembersFile -NoTypeInformation
Remove-item $tempMembersFile

$Groups = Get-ADPrincipalGroupMembership $GroupName | Select-Object Name
Foreach ($Group in $Groups)
{
    $GroupMemberOf = $Group.name
    $Results = [PSCustomObject]@{Memberof = "$GroupMemberOf (G)"}
    $Results | Export-Csv -Path $tempMembersOfFile -Append -NoTypeInformation
}

Import-Csv $tempMembersOfFile | Sort-Object Memberof | Export-Csv -Path $GroupMemberofFile -NoTypeInformation
Remove-item $tempMembersOfFile

Write-Host "Your List of members for $GroupName is located at $MembersFile"
Write-Host "Your List of groups $GroupName is a member of is located at $GroupMemberofFile"