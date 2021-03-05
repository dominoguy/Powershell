#New-WindowsUpdateScheduledTask

$taskName = 'Install Windows Updates Remotely'
$description = 'Temporary RI PowerShell task to install Windows updates remotely.'
$user = 'nt authority\system'
$delaySeconds = 60;

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask)
{
    $existingTask | Unregister-ScheduledTask -Confirm:$false 
}

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument '-Command Install-WindowsUpdates -Restart -Force'
$time = (Get-Date) + (New-TimeSpan -Second $delaySeconds)
$trigger = New-ScheduledTaskTrigger -Once -At $time
Register-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -TaskName $taskName `
    -Description $description `
    -User $user `
    -RunLevel Highest | `
    Out-Null