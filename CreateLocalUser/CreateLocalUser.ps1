#CreateLocalUser

$Username = "VMAdmin"
$Fullname = "VMAdmin"
$Description = "Local VM Administrator"
$Groups = "Users,Hyper-V Administrators"
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
        Write-host "The user account, $Username, exists and Enabled is $Enabled."
    }
}
else {
    Write-Host "$Server is not available."
}
