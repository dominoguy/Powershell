#PSSessionTesting




$Username = "ACE\RIAdmin"
$Password = "PlutoIs@Planet!2020"
$FQDN = "ace-fs-001.ace.ads"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $SecurePassword

#$Session = New-PSSession -ComputerName $FQDN -Credential $cred
$Session = New-PSSession -ComputerName "ACE-FS-001.ace.ads" -Credential $cred

Enter-PSSession $Session

Write-host "This is the session $Session"
Exit-PSSession