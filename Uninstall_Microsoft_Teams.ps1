#Uninstall Microsoft Teams

# Removal Machine-Wide Installer - This needs to be done before removing the .exe below!
#Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq "{39AF0813-FA7B-4860-ADBE-93B9B214B914}"} | Remove-WmiObject

#Variables
$TeamsUsers = Get-ChildItem -Path "C:\Users"
 ForEach($User in $TeamsUsers)
 {
    $Path = "C:\Users\" + $User.Name + "\AppData\Local\Microsoft\Teams"
      Try
      { 
        if (Test-Path $Path)
        {
            $TeamsUpdate = $Path + "\update.exe"
            Start-Process -FilePath $TeamsUpdate -ArgumentList "--uninstall","/s"
        }
      } 
      Catch
        { 
        Out-Null
        }
}

# Remove AppData folder for $($_.Name).
<#
ForEach($User in $TeamsUsers)
{
    $Path = "C:\Users\" + $User.Name + "\AppData\Local\Microsoft\Teams"
    Write-Host $Path
    If ($User.Name -eq "blongadmin") 
    {
        if (Test-Path $Path) 
            {
              Remove-Item –Path $Path -Recurse -Force -ErrorAction Ignore
            }
    }
}
#>