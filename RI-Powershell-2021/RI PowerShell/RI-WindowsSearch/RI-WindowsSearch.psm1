#RI-WindowsSearch

<#
.SYNOPSIS
Resets the Windows Search cache.

.DESCRIPTION
Purges the Windows Search cache, forcing a re-index.

.EXAMPLE
Reset-WindowsSearchCache
#>
function Reset-WindowsSearchCache
{
    if(Test-ShellElevation)
    {
        $startDelaySeconds = 10
        $serviceName = 'wsearch'
        $cacheFilePath = 'C:\ProgramData\Microsoft\Search\Data\Applications\Windows\windows.edb'

        Stop-Service -Name $serviceName
        Remove-Item -Path $cacheFilePath -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds $startDelaySeconds
        Start-Service -Name $serviceName
    }
}