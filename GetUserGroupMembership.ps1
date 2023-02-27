#GetUserGroupMembership

param(
        [Parameter(Mandatory=$true,HelpMessage='Name of User, do not add domain')][string]$UserName,
        [Parameter(Mandatory=$true,HelpMessage='OutPut Location')][string]$OutPutFilePath
    )


function Write-Log
{
    Param(
        [string]$logstring)

    Add-Content $MembersFile -value "$logstring"
}

$UserGroupsFile = $OutPutFilePath + "\$UserName-Groups.csv"

$UserGroupsFileExists = Test-Path -path $UserGroupsFile
$Headers = '"Groups"'
if ( $UserGroupsFileExists -eq $False)
{
 New-Item -ItemType File -Force -Path $UserGroupsFile
 Add-Content -Path $UserGroupsFile -Value $Headers
}
else {
    Remove-Item $UserGroupsFile
    New-Item -ItemType File -Force -Path $UserGroupsFile
    Add-Content -Path $UserGroupsFile -Value $Headers
}
$tempUserGroupsFile  = $OutPutFilePath + "\$UserName-Members-Temp.csv"

$Groups = Get-ADPrincipalGroupMembership $UserName | Select-Object name

ForEach ($item in $Groups)
{
    $Group = $item.Name
    $Results = [PSCustomObject]@{Groups = "$Group (G)"}
    $Results | Export-Csv -Path $tempUserGroupsFile -Append -NoTypeInformation
}

Import-Csv $tempUserGroupsFile | Sort-Object Groups | Export-Csv -Path $UserGroupsFile -NoTypeInformation
Remove-item $tempUserGroupsFile

Write-Host "Your List of Groups for $UserName is located at $UserGroupsFile"