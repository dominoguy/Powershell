#RI-Shell

<#
.SYNOPSIS
Clears PowerShell's history.

.DESCRIPTION
Clears PowerShell's history for the current user, and notifies the user to start a new session.
#>
function Clear-PowerShellHistory
{
   $historyFile = (Get-PSReadlineOption).HistorySavePath
   Remove-Item -Path $historyFile -ErrorAction SilentlyContinue

   $hostMessage = "PowerShell history has been cleared. Please start a new PowerShell session."
   $eventMessage = "PowerShell history file at $historyFile has been cleared."
   Write-Host $hostMessage
   New-RIPowerShellShellEvent -Message $eventMessage -EntryType Information -EventID 1000
}

function Start-RIPowerShell
{
   if (Test-RemoteSession)
    {
        Show-RIPowerShellLogo -DoNotClear
    }
    else
    {
        Show-RIPowerShellLogo
   }

   Start Cmd.Exe
   Get-SystemSummary
   $version = Get-RIPowerShellVerboseVersion -Scope Session
   $currentUser = Get-CurrentUser
   $eventMessage = "RI PowerShell $version started as $currentUser."
   New-RIPowerShellEngineEvent -Message $eventMessage -EntryType Information -EventID 101

   if (Test-ShellElevation -HideMessage)
   {
      Register-RIPowerShellEventSource
      Set-LocationToSystemDrive

      if (Test-VMHost)
      {
         Get-VMHostSummary -RemoteSessionDisabled
      }
   }
}

function Set-RIPowerShellEnvars
{
   $env:RIPOWERSHELLVERSION = Get-RIPowerShellInstalledVersion
   $env:RIPOWERSHELLCHANNEL = Get-RIPowerShellInstalledChannel
   $env:RIPOWERSHELLBUILD = Get-RIPowerShellInstalledBuild
}


function Set-LocationToSystemDrive
{
   $systemDrive = $env:SystemDrive + '\'
   Set-Location -Path $systemDrive
}

function Get-RIPowerShellLogo
{
   $logoFile = 'logo.txt'

   $logoPath = Get-RIPowershellResourcesPath -ChildPath $logoFile
   $logo = Get-Content -Path $logoPath
   
   return $logo
}

function Test-RemoteSession
{
   $remoteSession = (Get-Host).Name
   
   if ($remoteSession -eq 'ServerRemoteHost')
   {
      return $true
   }
   
   return $false
}

function Get-ShellColor
{
   if (Test-ShellElevation -HideMessage)
   {
      $color = 'Red'
   }
   else
   {
      $color = 'Green'
   }
   
   return $color
}

function Show-RIPowerShellLogo
{
   param(
      [switch]$DoNotClear)
   
   $versionPlaceholder = '~version~'

   $version = Get-RIPowerShellVerboseVersion -Scope Session
   $color = Get-ShellColor
   $logo = Get-RIPowerShellLogo
   
   if ($paddingLength -lt 0)
   {
      $paddingLength = 0
   }
   
   for ($i = 0; $i -lt $logo.Count; $i++)
   {
      $logo[$i] = $logo[$i] -replace $versionPlaceholder,$version
   }
   
   if (!$DoNotClear)
   {
      Clear-Host
   }
   
   foreach ($line in $logo)
   {
      Write-Host $line -ForegroundColor $color
   }
}

function Start-PowerShell
{
   param (
      [Parameter(Position=1)][int]$SessionCount = 1,
      [switch]$Exit)
   
   $maxSessions = 8

   if ($SessionCount -gt $maxSessions)
   {
      Write-Warning -Message "The maximum number of sessions is $maxSessions."
   }
   else
   {
      $executable = 'powershell.exe'

      if (Test-IsPowerShellCore)
      {
         $executable = 'pwsh.exe'
      }
      
      for ($i = 0; $i -lt $SessionCount; $i++)
      {
         Start-Process -FilePath $executable
      }
      
      if ($Exit)
      {
         exit
      }
   }
}

function Test-IsAdmin
{
   $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($windowsIdentity)
    $adminPrincipal = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdmin = $principal.IsInRole($adminPrincipal)
   
   return $isAdmin
}

function Test-IsPowerShellCore
{
   $minCoreVersion = 6

   $currentVersion = $PSVersionTable.PSVersion.Major

   if ($currentVersion -ge $minCoreVersion)
   {
      return $true
   }
   else
   {
      return $false
   }
}

function Enter-PSSessionWithConfiguration
{
   [CmdletBinding()]

   param (
      [Parameter(Mandatory=$true,Position=1)][string]$ComputerName)
      
   $configurationName = 'default'
   
   try
   {
      Enter-PSSession `
         -ComputerName $ComputerName `
         -ConfigurationName $configurationName `
         -ErrorAction Stop
   }
   catch
   {
      $delaySeconds = 5
      
      Write-Host "`nRemote RI PowerShell profile not found. Configuring default profile... " `
         -ForegroundColor Yellow -NoNewline
      Invoke-Command `
         -ComputerName $ComputerName `
         -ScriptBlock {Register-PSSessionConfiguration -Name default -StartupScript $pshome\profile.ps1 -Force} `
         -ErrorAction SilentlyContinue | Out-Null
      Start-Sleep -Seconds $delaySeconds
      Write-Host "done.`n" -ForegroundColor Yellow
      Enter-PSSession -ComputerName $ComputerName -ConfigurationName $configurationName
   }
}

function Get-CurrentComputer
{
   $computer = "$env:COMPUTERNAME"
   
   return $computer
}

function Get-CurrentUser
{
   $user = "$env:USERDOMAIN\$env:USERNAME"
   
   return $user
}

function Get-UserContext
{
   $user = Get-CurrentUser
   $computer = Get-CurrentComputer
   $userContext = "$user on $computer"
   
   return $userContext
}

function Set-ShellWindowTitle
{
   $version = Get-RIPowerShellVerboseVersion -Scope Session
   $userContext = Get-UserContext
   $windowTitle = "RI PowerShell $version - $userContext - PID $pid"
   
   if (Test-IsAdmin)
   {
      $windowTitle = 'Administrator: ' + $windowTitle
   }
   
   $host.UI.RawUI.WindowTitle = $windowTitle
}

function Get-FormattedTime
{
   $timeFormat = 'HH:mm:ss'

   $time = Get-Date -Format $timeFormat
   
   return $time
}

function Set-ShellPrompt
{
   $time = Get-FormattedTime
   $path = Get-Location
   
   if (Test-IsAdmin)
   {
      Write-Host "ADMIN " -NoNewline -ForegroundColor Red
   }
   else
   {
      Write-Host "USER " -NoNewline -ForegroundColor Green
   }  
   
   Write-Host "$time $path" -NoNewline
   
   return "> "
}

function Test-ShellElevation
{
   param (
      [switch]$HideMessage)
   
   if (Test-IsAdmin)
   {
      return $true
   }
   else
   {
      if (!$HideMessage)
      {
         Write-Host "`nThe requested operation requires elevation.`n"
      }

      return $false
   }
}

function Format-BarGraph
{
   param (
      [Parameter(Mandatory=$true,Position=1)][int]$Number,
      [Parameter(Mandatory=$true,Position=2)][int]$Scalar,
      [int]$Limit)
         
   [int]$length = $Number/$Scalar
   
   if ($Limit)
   {
      if ($length -gt $Limit)
      {
         $length = $Limit
      }
   }
   
   $bar = '■' * $length

   return $bar
}

function Write-CriticalSummary ($message)
{
   Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
   Write-Host $message
}

function Write-OptimalSummary ($message)
{
   Write-Host '[PASS] ' -ForegroundColor Green -NoNewline
   Write-Host $message
}

function Write-WarningSummary ($message)
{
   Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
   Write-Host $message
}

function Write-InformationalSummary ($message)
{
   Write-Host '[INFO] ' -ForegroundColor Cyan -NoNewline
   Write-Host $message
}

function Write-MetaMessage
{
   [CmdletBinding()]
   
   param(
      [Parameter(Mandatory=$true)][string]$Message)

   Write-Host "`n$Message`n" -ForegroundColor Magenta
}

function Get-TheDopefish
{
   $imageFile = 'thedopefishlives.txt'
   $imagePath = Get-RIPowershellResourcesPath -ChildPath $imageFile
   Get-Content -Path $imagePath
}
