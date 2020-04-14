<# 
.SYNOPSIS 
This script can be used for backup and restore of scheduled tasks.

.DESCRIPTION 
This script can be used for backup and restore of scheduled tasks. This also can be used to backup scheduled tasks from one system and restore it other system.

.PARAMETER BackupRestore

Accepts  a single computer name or an array of computer names. You may also provide IP addresses.
Default value : local computer
 

 .PARAMETER Path
 
Provide path to for backup scheduled tasks or to specify path for xml file restore


 .EXAMPLE 
Restore Scheduled Tasks

.\Backup-Restore-ScheduledTasks.ps1 -BackupRestore Restore -Path C:\Scripts


.Link 
 
If you have any question, you can post to
http://vikramathare.wordpress.com/ or
https://gallery.technet.microsoft.com/PowerShell-Bakcup-and-e4482583
 
.Notes
Version - 1.0
#>
 param( 
    [parameter(Mandatory=$true)] 
    [ValidateSet(“Backup”,”Restore”)]  
    [String]$BackupRestore, 
    [parameter(Mandatory=$true)] 
    [ValidateScript({Test-Path $_ })] 
    [string]$Path 
) 
if ($BackupRestore -eq 'Backup') { 
# Bakcup Scheduled tasks 
    $Tasks = Get-ScheduledTask -TaskPath \ | Select TaskName 
    foreach($Task in $Tasks){ 
        $TaskName = $Task.TaskName 
        Write-Host "Backup of Task: $TaskName" -ForegroundColor White 
        Export-ScheduledTask -TaskName $TaskName | Out-File "$Path\$TaskName.xml" -Force 
    } 
    Write-Host "Backup of scheduled task is completed" -ForegroundColor White 
} 
if ($BackupRestore -eq 'Restore') { 
# Restore Scheduled tasks 
    $UserName = Read-Host -Prompt "Enter UserName to configure scheduled task(Domain\UserName)" 
    $Password = Read-Host -Prompt "Enter Password For $UserName"  -AsSecureString 
    $Password = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password) 
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($Password) 
    $Items = Get-ChildItem $Path -Filter '*.XML' 
    foreach($Item in $Items){ 
        $TaskName = ($Item.Name).Split('.')[0] 
        Write-Host "Restoring Task: $TaskName" -ForegroundColor White 
        cmd.exe /c schtasks /create /xml $Item.FullName /tn $TaskName  /ru $UserName /rp $Password 
    } 
    Write-Host "Restore of scheduled task is completed" -ForegroundColor White 
}