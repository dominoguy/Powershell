#CreateLocalUser

$Username = "VMAdmin"
$Fullname = "VMAdmin"
$Description = "Local VM Administrator"
$Groups = "Users,Hyper-V Administrators"
$Server = "RI-HVS-901"
$FQDN = "RI-HVS-901.ri.ads"

IF (Test-Connection -ComputerName $FQDN -Quiet)
{
    $Session = New-PSSession -ComputerName $FQDN

    $parameters = @{
        #Credential = $cred
        Session = $Session
        ScriptBlock = {Param ($Username) Get-LocalUser -Name $Username -ErrorAction SilentlyContinue}
        ArgumentList = ($Username)
    }

    $UserAccount  = Invoke-Command @parameters

    IF($UserAccount.Name -ne $Username)
    {
        Write-Host "Creating User $Username"
        #$Password = Read-Host -AsSecureString
        $Password = "GMoney2023"
        $Password = ConvertTo-SecureString "GMoney2023" -AsPlainText -Force 
        $parameters = @{
            #Credential = $cred
            Session = $Session
            ScriptBlock = {
                Param ($Username,[SecureString]$Password,$FullName,$Description)
                New-LocalUser -Name $Username -Password $Password -AccountNeverExpires -PasswordNeverExpires -FullName $FullName -Description $Description}
            ArgumentList = ($Username,$Password,$FullName,$Description)
        }
        Invoke-Command @parameters
        Write-Host "$Username is created"

        $ArrGroups = $Groups.Split(',')
        IF($ArrGroups -NE "")
        {
            ForEach($Group in $ArrGroups)
            {
                $parameters = @{
                    #Credential = $cred
                    Session = $Session
                    ScriptBlock = {Param ($Username,$Group) Add-LocalGroupMember -Group $Group -Member $Username}
                     ArgumentList = ($Username,$Group)
                }
                Invoke-Command @parameters
                Write-Host "$username added to $Group"
            }
        }
         Write-Host "$UserName added to designated groups"
    }
    else
    {
        $Enabled = $UserAccount.Enabled
        Write-host "The user account $Username exists and Enabled is $Enabled."
        $parameters = @{
            #Credential = $cred
            Session = $Session
            ScriptBlock = {Get-LocalGroup}
        }

        $LocalGroups  = Invoke-Command @parameters
        ForEach($localGroup in $LocalGroups)
        {
            Write-Host "the local group testing is $localgroup"
            $parameters = @{
                #Credential = $cred
                Session = $Session
                #$Username = "RI-HVS-901\$Username"
                ScriptBlock = {Param ($LocalGroup,$Server,$Username)Get-LocalGroupMember -Name $LocalGroup}
                ArgumentList = ($LocalGroup,$Server,$Username)
            }
        
            $GroupMembers  = Invoke-Command @parameters
            ForEach($Member in $GroupMembers)
            {
                #Write-Host "   the members of the group are $member"
                $FullName = "$Server\$UserName"
                Write-host "The full name is $Fullname"
                Write-Host "The groupmember we are checking is $member"
                If($Member -eq $Fullname)
                {
                    Write-Host  "$username is in $LocalGroup group"
                }
                
            }
            
        }
    }
}
else {
    Write-Host "$Server is not available."
}
