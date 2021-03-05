$ripsModulePaths = 'X:\Program Files\RI PowerShell;'
$env:PSModulePath = $ripsModulePaths + $env:PSModulePath

Set-RIPowershellEnvars
Start-RIPowerShell

Set-Alias -Name cls -Value Show-RIPowerShellLogo -Option AllScope
Set-Alias -Name dl -Value Start-BitsTransfer
Set-Alias -Name dopefish -Value Get-TheDopefish
Set-Alias -Name fqdn -Value Convert-NetbiosNameToFQDN
Set-Alias -Name ic -Value Invoke-Command
Set-Alias -Name png -Value Watch-Connection
Set-Alias -Name rcopy -Value Copy-FolderRecursively
Set-Alias -Name rdp -Value Enter-RDSession
Set-Alias -Name rps -Value Enter-PSSessionWithConfiguration
Set-Alias -Name wake -Value Send-WakeOnLANToComputer
Set-Alias -Name zip -Value New-ZipFileFromDirectory

function Prompt
{
	Test-RIPowerShellSessionBuild
	Set-ShellWindowTitle
	Set-ShellPrompt
}