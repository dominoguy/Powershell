#RI-UserProfiles


function Set-LocalAdministratorPassword
{
	[CmdletBinding()]

    param(
        [Parameter(Position = 1,Mandatory = $true)][string]$Password)
        
    $userAccounts = Get-CimInstance -ClassName win32_useraccount;
    $administratorAccount = $userAccounts | Where-Object {$_.name -eq 'Administrator'};
    $administratorAccount.SetPassword($Password)
}

function Start-UserProfiles
{
    if (Test-ShellElevation)
    {
        $process = 'rundll32.exe'
        $arguments = 'sysdm.cpl,EditUserProfiles'
        Start-Process -FilePath $process -ArgumentList $arguments
    }
}


<#
.SYNOPSIS
Returns a list of user profiles.

.DESCRIPTION
Returns a list of user profiles registered on the system.
#>
function Get-UserProfiles
{
    $userProfiles = Get-CimInstance -ClassName Win32_UserProfile

    return $userProfiles
}

<#
.SYNOPSIS
Removes profiles for disabled user accounts.

.DESCRIPTION
Removes locally-stored profiles for accounts disabled in Active Directory.
#>
function Remove-DisabledUserProfiles
{
    if (Test-ShellElevation)
    {
        $disabledUserList = Get-ADDisabledUsers
        $userProfileList = Get-UserProfiles
        $removedProfileList = @()

        for ($i = 0; $i -lt $disabledUserList.Count; $i++)
        {
            $disabledUser = $disabledUserList[$i]
            $sid = $disabledUser.Sid
            $samAccountName = $disabledUser.SamAccountName
            $userProfile = $userProfileList | Where-Object {$_.sid -eq $sid}

            $activity = 'Remove-DisabledUserProfiles' 
            $status = "Searching system for user profile $samAccountName with SID $sid"
            $percentComplete = ($i/$disabledUserList.Count*100)
            Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete

            if ($userProfile)
            {
                $userProfile | Remove-WmiObject
                $removedProfileList += $userProfile

                $message = "Removed disabled user profile $samAccountName with SID $sid."
                New-RIPowerShellUserProfilesEvent -Message $message -EntryType Information -EventId 1900
            }
        }
        
        $count = $removedProfileList.count
        Write-Host "Removed $count disabled user profiles."
    }
}
