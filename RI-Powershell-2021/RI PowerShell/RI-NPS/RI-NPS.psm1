#RI-NPS

<#
.SYNOPSIS
Sets registry keys to enable MAC-based authentication in NPS.

.DESCRIPTION
Sets registry keys needed to enable MAC-based authentication in Windows Network Protection Server (NPS).
#>
function Enable-NpsMacAuthentication
{
    if (Test-ShellElevation)
    {
        $resourceFile = 'Modules\RI-NPS\npsmacauthentication.reg'
        $resourcePath = Get-RIPowerShellResourcesPath -ChildPath $resourceFile
        reg.exe IMPORT $resourcePath
    }
}