#Test



#$date = Get-Date
#Write-host $date

Get-Date
get-vm too-tse-001 | get-vmharddiskdrive | select-object -Property VMName, path
get-vm ri-testbcl-001 | get-vmharddiskdrive | select-object -Property VMName,path
