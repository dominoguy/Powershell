# Archived Release Notes for RI PowerShell

## Version 6.1.0, Build 2082, 2019-10-24
This version of RI PowerShell introduces a new mechanism to improve the speed and reliability of updates.
### Additions
  * Export-RIPowerShell packages Release and Beta versions of RI PowerShell to a deploy path.
  * Optimize-WsusServer runs a complete optimization of a WSUS server.
  * Update-RIPowerShellDevelopmentBuild updates a development build of RI PowerShell.
### Changes
  * Merged module RI-Compression into RI-FileSystem.
  * Update-RIPowerShell
    * Now downloads a compressed version of the installation files, improving the speed of the update process by over 1000%.
    * Beta switch will update using the Beta Channel.
### Fixes
There are no bug fixes in this release.
### Deprecated
  * The following behaviors have been deprecated in RI PowerShell v6.1.0:
    * Update-RIPowerShell
      * Dev and Deploy scope options.

## Version 6.0.1, Build 2056, 2019-08-21
### Additions
There are no additions in this release.
### Changes
There are no changes in this release.
### Fixes
  * Corrected bug in Test-TPMEnabled that prevented the start of BitLocker encryption.

## Version 6.0.0, Build 2048, 2019-06-27
This is the first version of RI PowerShell to feature compatibility for PowerShell Core. Due to API changes all logging has been disabled when using PowerShell Core. For more information regarding compatibility, refer to knownissues.md.
### Additions
  * Disable-InternetExplorerESC and Enable-InternetExplorerESC change the state of the IE Enhanced Security Configuration for administrators.
  * Test-IsPowerShellCore returns true if the current shell is a version of PowerShell Core.
### Changes
  * The following commands have been modified to be compatible with PowerShell Core:
    * Disable-PrinterPortSNMP
    * Get-AvailableDriveLetter
    * Get-BatteryChargeRemaining
    * Get-BatteryRuntime
    * Get-SystemSummary
    * Get-UserProfiles
    * Set-LocalAdministratorPassword
    * Start-PowerShell
    * Test-TPMEnabled
### Fixes
  * Corrected missing rcopy alias in WinPE profile.
### Deprecated
  * The following commands have been deprecated in RI PowerShell v6.0.0:
    * Enter-RDShadowSession
    * Get-GitDiffFolders
  * The following behaviors have been deprecated in RI PowerShell v6.0.0:
    * Export-ADUserFiles
      * TakeOwnership option.
    * Watch-Connection (png)
      * SingleLine option.

## Version 5.4.0, Build 2018, 2019-06-11
### Additions
  * Remove-OldPrintJobs removes print jobs older than a specified number of days.
### Changes
  * Copy-FolderRecursively
    * Now automatically removes trailing slashes in paths before sending them to Robocopy.
    * Added BackupMode switch, allowing the copy to be done with the Backup Operator APIs.
    * Added help.
  * Export-ADUserFiles now copies using the Backup Operator APIs.
### Fixes
There are no fixes in this release.
### Deprecated
  * The following behavior will be deprecated in RI PowerShell v6.0.0:
    * Export-ADUserFiles
      * The TakeOwnership switch will be removed as the copy is now done in backup mode.
      
## Version 5.3.0, Build 2004, 2019-05-30
### Additions
  * Install-TelnetClient installs the Telnet client.
### Changes
  * RI PowerShell now logs the user that launched it.
  * Added help to the following commands:
    * Install RSAT
    * Update-RIPowerShell
    * Uninstall-RSAT
  * Added logging to the following commands:
    * Update-StockSyncInventory
  * Removed redundant scope Beta from Update-RIPowerShell.
### Fixes
There are no fixes in this release.

## Version 5.2.0, Build 1987, 2019-05-14
### Additions
  * Get-WindowsVersionNumber returns the major and minor versions of Windows.
  * Hide-DisabledMailboxes hides mailboxes for all disabled user accounts.
### Changes
  * Remove-WindowsUpdatePolicy now restarts the Windows Update service after clearing the policy from the registry.
  * Updated help for Enter-RDSession (rdp).
  * Update-RIPowerShellDownstreamServers now uses the Beta source path.
### Fixes
  * Corrected bug in Get-SystemSummary that would attempt to run an unsupported method on Windows 7/Server 2008 R2 and below operating systems.
  * Update-RIPowerShellDownstreamServers now correctly retrieves a Beta version of RI PowerShell from the Beta source.
### Deprecated
  * The following commands will be deprecated in RI PowerShell v6.0.0:
    * Enter-RDShadowSession
    * Get-GitDiffFolders
  * The following behavior will be deprecated in RI PowerShell v6.0.0:
    * SingleLine will be removed from Watch-Connection (png).

## Version 5.1.0, Build 1947, 2019-05-02
### Additions
  * Grant-AdministratorAccessToFolder grants the local Administrators group access to a folder and its child objects.
  * New-ADMacFineGrainedPasswordPolicy creates a fine-grained password policy for MAC authentication.
  * New-GitCommit creates a new Git commit.
### Changes
  * Export-ADUserFiles now has an optional switch to take ownership of the folders before copying files.
  * Suspend-Computer now supports a delay timer.
  * Update-RIPowerShell
    * Using the Dev scope will now update the Beta Deploy path.
  * Added logging to the following commands:
    * Export-BackupLog
  * The following behaviors will be deprecated in RI PowerShell v6.0.0:
    * Export-BackupLog will no longer take a computer name as a parameter.
### Fixes
  * Corrected bug in Remove-GitNonMasterBranches that would attempt to create a new master branch instead of switching to it.

## Version 5.0.0, Build 1908, 2019-04-17
### Additions
  * New module: RI-NPS
    * Enable-NpsMacAuthentication sets registry keys needed to enable MAC-based authentication in Windows Network Protection Server (NPS).
  * Get-ADWritableDomainController returns a random writable Domain Controller.
  * Get-GitBranches returns a list of branches in a Git repository.
  * Remove-GitNonMasterBranches deletes all non-master branches from a Git repository.
  * Set-BackupDiskOfflineTemporarily temporarily sets backup drives offline.
  * Test-ADAccountPassword tests if a password is valid against an Active Directory account.
### Changes
  * Updated help for the following commands:
    * New-ADMacAccount
    * New-ADMacAccountsFromFile
    * Remove-ExchangeMessagesFrom
    * Remove-ExchangeMessagesWithAttachment
    * Remove-ExchangeMessagesWithSubject
  * Copy-FolderRecursively
    * Added -ExcludeJunctions option to exclude junctions for files and directories from a copy operation.
    * Added -IncludePermissions option to include security and ownership information in the copy.
  * Get-VMHostSummary
    * Removed header from summary.
  * New-ADMacAccount
    * Account names now start with a "MACAuth-" prefix.
    * Added -DeviceType parameter to place the account in a specific group.
  * New-ADMacAccountsFromFile
    * Added DeviceType functionality.
    * Added progress indicator.
  * New-RollingVMCheckpointFile
    * Will now use default path of "C:\ProgramData\RI PowerShell\Settings\RI-Virtualization\rollingcheckpoints.csv" if none is specified.
    * Added -Edit switch to automatically launch Notepad with the newly created file.
    * Added -Force switch to allow overwrite of an existing file.
  * The following deprecated commands have been removed:
    * Start-VMInOrder
    * Test-VMMSServiceIsRunning
    * Test-CommonIPv4TCPPorts
    * Test-IPv4TCPPort
    * Test-VMMServer
  * The following deprecated behavior has been removed:
    * Rate parameter from Watch-Connection (png).
### Fixes
There are no fixes in this release.

## Version 4.6.0, Build 1833, 2019-04-09
### Additions
  * Export-DisabledADUserFiles exports files associated with all disabled ActiveDirectory accounts.
  * Export-ADUserFiles exports files associated with an ActiveDirectory account.
  * New-ADMacAccount creates a new Active Directory account for MAC-based authentication.
  * New-ADMacAccountsFromFile creates Active Directory accounts for MAC-based authentication from a CSV file.
  * New-RandomPassword generates a new random password of a specified length.
### Changes
  * Start-PowerShell will no longer launch sessions if the maximum is exceeded.
  * The following commands will be deprecated in RI PowerShell 5.0.0:
    * Test-VMMSServiceIsRunning
    * Test-CommonIPv4TCPPorts
    * Test-IPv4TCPPort
    * Test-VMMServer
  * The following behavior will be deprecated in RI PowerShell 5.0.0:
    * The Rate parameter in Watch-Connection (png) will be removed.
  * Added logging events to:
    * Show-DeprecatedBehaviourWarning
### Fixes
  * Corrected bug in Enable-LapsForWorkstationsOU that would pass a null OU preventing it from applying LAPS settings in Active Directory.

## Version 4.5.0, Build 1792, 2019-03-26
### Additions
  * Export-DisabledMailboxes exports all mailboxes belonging to disabled users.
  * Export-Mailbox exports a mailbox as a PST to a given folder (provided as a UNC).
  * Remove-FolderWithLongPaths removes a folder containing long paths.
### Changes
  * Get-ADDisabledUsers now uses the Users base OU to limit results.
### Fixes
There are no fixes in this release.

## Version 4.4.0, Build 1771, 2019-03-20
### Additions
  * Install-ADPowerShellRsat installs the Active Directory PowerShell RSAT.
### Changes
  * Get-ADDisabledUsers installs the Active Directory PowerShell RSAT if it is not installed on the local machine.
  * Logging
    * New-RollingVMCheckpointFromFile now logs drive disconnections and reconnections.
    * Register-RIPowerShellEventSource now logs all sources in a single event entry, instead of one entry per source.
  * The following commands are deprecated and will be removed in RI PowerShell 5.0.0:
    * Start-VMInOrder
### Fixes
There are no fixes in this release.

## Version 4.3.0, Build 1758, 2019-03-12
### Additions
 * Get-ADDisabledUsers returns a list of disabled user accounts in Active Directory.
 * Get-UserProfiles returns a list of local user profiles.
 * New-RollingVMCheckpointFile creates a new configuration file suitable for use with New-RollingVMCheckpointFromFile.
 * Remove-DisabledUserProfiles removes user profiles from any disabled accounts in Active Directory.
 * Logging
   * Added User Profiles and Virtualization event sources.
### Changes
 * Removed build number from release channel.
 * Get-VMHostSummary
   * Removed cmdlet message at end of summary.
 * Added help to:
   * Remove-ExchangeMessagesFrom
   * Remove-ExchangeMessagesWithAttachment
   * Remove-ExchangeMessagesWithSubject
 * Logging
   * Added logging to New-RollingVMCheckpoint.
### Fixes
There are no fixes in this release.

## Version 4.2.0, Build 1728, 2019-03-04
### Additions
There are no additions in this release.
### Changes
  * New-FormattedVHD
    * Added -Mount switch to leave the virtual drive mounted after being created.
    * Added help.
  * New-RollingVMCheckpointFromFile
    * Added feature to optionally disconnect a SCSI drive before checkpointing the virtual machine, reconnecting it after the checkpoint process is completed.
    * Updated help.
### Fixes
 * Corrected bug in Get-FolderSize that would cause an error when getting the size of a directory with any empty directories as children.

## Version 4.1.0, Build 1713, 2019-02-27
### Additions
  * Get-AvailableDriveLetter provides a list of available drive letters.
  * New-FormattedVHD creates and formats a new virtual hard drive.
### Changes
There are no changes in this release.
### Fixes
  * Fixed a bug in Copy-FolderRecursively (rcopy) that could cause a copy to fail when the source is on a deduped volume.

## Version 4.0.0, Build 1660, 2019-02-11
### Additions
  * Get-ADBaseServersOUPath returns the path to the Servers OU.
  * New-RollingVMCheckpointFromFile creates rolling checkpoints based on a CSV file.
  * Enable-LapsForServersOU enables Microsoft's Local Administrator Password Solution (LAPS) for the Servers OU.
### Changes
  * Added one second polling delay to New-RollingVMCheckpoint to throttle requests to Hyper-V.
  * The following deprecated commands have been removed from RI PowerShell:
    * Get-LogFilePath
    * Get-LogFolderPath
    * Get-SMTPServer
    * Get-RIPowerShellProgramDataPath
    * Get-RIPowerShellSystemSettingsPath
    * Get-RIPowerShellReleaseNotes
    * New-LogEntry
    * New-LogFileHeader
    * Open-LogFile
    * Remove-CantaxFileIndexes
    * Send-Email
### Fixes
There are no bug fixes in this release.

## Version 3.6.0, Build 1642, 2019-01-21
### Additions
  * Update-RIPowerShellModuleManifests updates all RI-PowerShell manifest files with a specified version number (development environment only).
### Changes
  * There are no changes in this release.
### Fixes
  * Corrected an error when RI PowerShell would attempt to create a log entry when the log name had not been registered yet.
  * Corrected error in RI-NetworkingIPv4 manifest, causing the module to load as a script.

## Version 3.5.0, Build 1628, 2019-01-02
### Additions
  * Added help to the following commands:
    * Clear-PowerShellHistory
  * Logging
    * Added new event source: RI PowerShell WSUS
    * Added logging for the following commands:
      * Optimize-WsusContent
      * Optimize-WsusDatabase
      * Restart-WsusWebAppPool
      * Remove-WsusUnneededUpdates
### Changes
  * WSUS
    * Get-WsusUnneededUpdateSearchTerms returns a list of search terms for unneeded updates.
    * Remove-WsusUnneededUpdates
        * Updated help.
        * Now loads search terms from file.
        * Updated search term list to include:
            * farm-deployment
            * Microsoft SharePoint Enterprise Server
            * Windows 10 Education
            * Windows 10 Enterprise
            * Windows 10 Team
            * Windows 10 Version 1507
            * Windows 10 Version 1607
### Fixes
There are no fixes in this release.

## Version 3.4.0, Build 1619, 2018-12-12
### Additions
  * Active Directory
    * Get-ADBasePrintersOUPath returns the path for the Printers resource OU.
    * New-ADPrinterResourceGroup creates a new printer resource group in Active Directory.
    * Reset-ADUserPasswordExpiry resets an Active Directory user account's password expiry date.
  * Logging
    * Added new event source: RI PowerShell Windows Update
  * Windows Update
    * Remove-WindowsUpdatePolicy purges the local machine's Windows Update policy.
### Changes
  * Active Directory
    * Updated help for Move-FsmoRoles.
### Fixes
  * Corrected incorrect logging of Windows Update events under the the RI PowerShell Update source.

## Version 3.3.0, Build 1607, 2018-12-01
### Additions
  * Added help to the following commands:
    * Backup-BitLockerKeyToAD
    * Copy-ADGroupMembers
    * Reset-PersonifyCache
    * Reset-SophosEvents
    * Test-TPMEnabled
### Changes
  * Moved Restart-ComputerWithDelay from RI-WindowsUpdates to RI-Power.
  * Added event logging to the following commands:
    * Install-WindowsUpdatesRemotely
  * Deprecated the following commands:
    * Get-RIPowerShellReleaseNotes
    * Remove-CantaxFileIndexes
### Fixes
  * Corrected bug that prevented Enter-PSSessionWithConfiguration (rps) from establishing a remote PowerShell session when the RI PowerShell event sources were not registered prior to the connection.

## Version 3.2.0, Build 1589, 2018-11-22
### Additions
No additions are in this release.
### Changes
  * Added help to the following commands:
    * Add-LapsSchema
    * Enable-LapsForWorkstationsOU
  * Removed positional parameter from Enable-LapsForWorkstationsOU.
### Fixes
* Corrected several bugs related to using a Remote PowerShell Session:
  * Console would clear before the RI PowerShell logo is displayed.
  * RI PowerShell would crash when attempting to register event sources in a remote Session.
  * RI PowerShell would attempt to set the remote session configuration every time, causing a connection delay.

## Version 3.1.0, Build 1576, 2018-11-21
### Additions
* RI-Shell
  * Clear-PowerShellHistory clears PowerShell history in Windows 10, Server 2016 and newer operating systems.
* RI-Logging
  * Added RI PowerShell Shell event source.
### Changes
  * Logging
    * Updated Event ID definitions, reducing them by one digit.
### Fixes
There are no fixes in this release.

## Version 3.0.0, Build 1569, 2018-11-21
### Additions
  * Logging now uses Windows Event Log technology built into the operating system.
  * RI-Logging
    * New-RIPowerShellEvent creates a new RI PowerShell event in the Windows PowerShell log.
    * Register-RIPowerShellEventSource registers RI PowerShell as a Windows event source.
      * This is automatically called when RI PowerShell is started in an administrator context.
    * Unregister-RIPowerShellEventSource removes RI PowerShell event registrations and log.
    * Using a deprecated command will log a warning in the RI PowerShell event log.
### Changes
  * RI PowerShell logo:
    * No longer animated in console sessions.
    * Displays the major version in large type.
    * Verbose version label has been shortened.
  * The following deprecated commands have been removed in RI PowerShell 3.x.x:
    * Copy-PersonifyCache
    * Get-ADHypervisors
    * Get-SystemDrive
    * Get-UsersPath
    * Initialize-RIPowerShellFolders
    * Start-DedupOptimizationJob
    * Test-IsNetbiosFormat
    * Update-RIPowerShellForWinPEImage
    * Watch-IPv4TCPPort
  * Removed deprecated behavior from Move-FsmoRoles as described in v2.3.0 release notes.
  * The following commands have been deprecated:
     * Get-LogFilePath
     * Get-LogFolderPath
     * Get-RIPowerShellProgramDataPath
     * Get-RIPowerShellSystemSettingsPath
     * Get-SMTPServer
     * New-LogEntry
     * Open-LogFile
     * Send-Email
  * RI-Print
    * Test-PrintSpoolerHealth no longer sends an email when it restarts the Print Spooler service.
  * RI Update
    * Changed error message in Update-RIPowerShellDownstreamServers.
  * Added help for the following commands:
    * Get-ADWorkstationAdminPasswords
    * Update-ADUserProfilePaths
### Fixes
There are no fixes in this release.

## Version 2.3.0, Build 1520, 2018-11-15
### Additions
  * RI-GroupPolicy
    *  Import-GPOLibrary imports GPOs from a folder.
### Changes
  * Move-FsmoRoles
    * Removed positional parameter for -Server.
    * Deprecated purpose of -Server parameter, replacing it with -Identity.
    * Command is now run against Active Directory Web Services on the same server the roles are moved to, unless both -Identity and -Server parameters are specified.
    * Added help.
  * Set-DRACIPv4Address can no longer be run in a remote PowerShell session.
### Fixes
  * Corrected non-mandatory -Path parameters in Export-GPCentralStore and Export-GPO.
  * Corrected bug in Install-NetFramework35 that had it ignoring inserted media.

## Version 2.2.0, Build 1500, 2018-10-25
### Additions
  * RI-Git
    * Show-GitLog displays the Git repository log.
  * RI-GroupPolicy
    * Export-GPCentralStore exports the Group Policy Central Store to a specified location.
  * RI-System
    * Get-WindowsReleaseID returns the release ID for Windows. Requires Windows 10, Server 2016 or above.
  * RI-TranslationMapping
    * Import-Mapping imports a mapping file.
  * RI-NetworkAdapter
    * Send-WakeOnLAN wakes a system at the specified MAC Address.
    * Send-WakeOnLANToComputer wakes a computer, alias: wake.
  * RI-WindowsFeature
    * Install-RsatOnWorkstation installs the Remote Server Administration Tools on Windows 10 1809 and above using Features On Demand.
  * RI-WSUS
    * Remove-WsusUnneededUpdates declines unneeded Windows updates.
### Changes
  * Renamed module RI-NetworkingAdapter to RI-NetworkAdapter.
  * Export-GPO no longer defaults to exporting to the current directory.
  * Get-VMMemorySummary no longer warns if virtual machines are spanning NUMA nodes.
  * The following commands have been deprecated:
    * Copy-PersonifyCache
    * Get-SystemDrive
    * Get-UsersPath
    * Initialize-RIPowerShellFolders
    * Start-DedupOptimizationJob
    * Update-RIPowerShellForWinPEImage
### Fixes
  * Corrected error where Show-RIPowerShellLogo was missing from the RI-Shell manifest.

## Version 2.1.0, Build 1466, 2018-10-18
### Additions
  * RI PowerShell version information now includes channel information.
  * RI-ActiveDirectory
    * Get-ADResourceMembership returns a list of users for a given class of Active-Directory resource.
  * RI-Application
    * Reset-SophosEvents resets all events listed in the Sophos endpoint interface.
    * Stop-ProcessByFile stops a process based on its filename.
  * RI-UserProfiles
    * Set-LocalAdministratorPassword sets the password of the well-known Administrator account.
  * Added manifests to the following modules:
    * RI-Application
    * RI-AmazonWebServices
    * RI-Compression
    * RI-Credential
    * RI-DellDRAC
    * RI-DellOMSA
    * RI-Diagnostics
    * RI-Environment
    * RI-FileDeduplication
    * RI-FileSystem
    * RI-Git
    * RI-GUID
    * RI-InternetExplorer
    * RI-Logging
    * RI-MediaWiki
    * RI-Memory
    * RI-Meta
    * RI-NetworkingAdapter
    * RI-Parsing
    * RI-Power
    * RI-Services
    * RI-Shell
    * RI-SMB
    * RI-SQL
    * RI-SSH
    * RI-Sysinternals
    * RI-System
    * RI-TranslationMapping
    * RI-UserProfiles
    * RI-VMM
    * RI-Web
    * RI-WindowsSearch
    * RI-WindowsServer
    * RI-WindowsUpdate
### Changes
  * Version, channel and build information is now displayed in both development and production environments.
  * Removed random tips displayed when RI PowerShell starts.
  * RI-Meta
    * Get-RIPowerShellVerboseVersion now returns release channel information.
  * The following commands have been deprecated:
    * RI-NetworkingIPv4
      * Watch-IPv4TCPPort
    * RI-TranslationMapping
      * Test-IsNetbiosFormat
### Fixes
  * RI-ActiveDirectory
    * Fixed bug in Copy-ADGroupMembers that prevented the copy operation from finding the correct source and destination.

## Version 2.0.0, Build 1427, 2018-10-02
### Additions
  * RI-ActiveDirectory
    * Enable-LapsForWorkstationsOU enables Active Directory storage of local admin passwords for members of the base Workstations OU.
    * Get-ADBaseGroupsOUPath replaces Get-ADBaseGroupOUPath.
    * Get-ADBaseUsersOUPath replaces Get-ADBaseUserOUPath.
    * Get-ADBaseWorkstationsOUPath returns the path to the Workstations OU.
    * Get-ADBaseChildOUPath can be used to append the base OU path with a child.
    * Get-ADWorkstationAdminPasswords returns all Active Directory stored local admin passwords for members of the base Workstations OU.
  * RI-FileSystem
    * Copy-FolderRecursively acts as a wrapper around RoboCopy, using common switches to mirror a source folder and ignore junctions. Uses the rcopy alias.
### Changes
  * RI-Update
    * Reduced logging to console for all update operations.
    * Test-RIPowerShellSessionBuild now warns if RI PowerShell has been reverted to an previous build.
    * Remove-WsusHiddenUpdates: corrected grammar in summary message.
  * RI-Virtualization
    * Get-VMHostSummary
      * Changed several messages, such as differencing and saved memory, to be informational instead of a failure.
  * The following deprecated commands have been removed in RI PowerShell v2.0.0:
    * RI-ActiveDirectory
     * Get-ADBaseGroupOUPath
     * Get-ADBaseUserOUPath
     * Get-ADBaseWorkstationsOUPath
     * Get-ADHypervisors
    * RI-Application
      * Backup-IntegraDB
      * Backup-IntegraProgram
      * Restart-IntegraService
    * RI-FileSystem
      * Start-ExplorerAsAdmin
    * RI-MozillaFirefox
     * This module has been removed in its entirety.
### Fixes
There are no fixes in this release.

## Version 1.13.0, Build 1398, 2018-08-22
### Additions
* RI-Git
** Rename-GitLastCommit renames the last commit made in the current branch.
* RI-Meta
** New-RIPowerShellModuleManifest creates a new PowerShell manifest file for a module.
### Changes
* RI-Application
** Update-StockSyncInventory
*** Will now produce an error when no file can be found to upload.
*** Added debugging messages.
*** Update URI as per StockSync support. Maybe it'll work this time.
* RI-Web
** Added debugging messages to Send-MultiPartContent.
### Fixes
There are no fixes in this release.

## Version 1.12.0, Build 1389, 2018-07-18
### Additions
  * RI-Git
    * Merge-GitBranchToMaster merges a branch to master, deleting the local copy (not forced).
### Changes
  * RI-Application
    * Update-StockSyncInventory
        * Now uses curl to perform the upload.
        * Removed files older that 7 days if the upload was successful
  * RI-Web
    * Added Curl provider to Send-MultiPartContent.
### Fixes
There are no fixes in this release.

## Version 1.11.0, Build 1374, 2018-07-16
### Additions
There are no additions in this release.
### Changes
  * RI-Exchange
    * Get-UserMailbox returns a filtered list of user mailboxes.
    * Update-AntispamTransportRules
      * Now operates in a Forest-wide scope.
      * Message prefix changed to "Potential Spam (Delete)".
### Fixes
  * RI-Git
    * Corrected bug in Get-GitFolders that caused an exception when running against a directory with no child directories.

## Version 1.10.0, Build 1361, 2018-07-13
### Additions
  * RI-Application
    * Update-StockSyncInventory uploads an inventory file to StockSync.
  * RI-Git
    * New-GitTag assigns a tag to a commit, pushing it to the remote repository.
    * Publish-GitBranch publishes the specified branch to a remote repository.
    * Remove-GitRemoteBranch removes the specified remote branch.
  * RI-Web
    * Send-MultiPartContent sends a file in multipart/form-data format using HTTP/S POST.
  * RI-Wsus
    * Get-WsusUnneededUpdates returns a filtered list of unneeded Windows updates.
    * Get-WsusUpdateList returns all updates catalogued on a WSUS server.
### Changes
  * RI-Exchange
    * Update-AntispamTransportRules now includes an accepted domain name rule.
  * Moved the following commands from RI-Shell to RI-Meta
   * Get-AboutRIPowerShellPath
   * Get-RIPowerShellPath
   * Get-RIPowerShellProgramDataPath
   * Get-RIPowerShellResourcesPath
   * Get-RIPowerShellSystemSettingsPath
   * Get-RIPowerShellUserSettingsPath
  * The following commands have been deprecated:
    * RI-ActiveDirectory
      * Get-ADHypervisors
  * Moved deprecated commands to the end of their respective modules.
### Fixes
  * RI-ActiveDirectory
    * Fixed error where Copy-ADGroupMembers was missing from manifest file, making command inaccessible.

## Version 1.9.0, Build 1321, 2018-06-28
### Additions
  * Added help content to the following commands:
    * RI-AmazonWebServices
      * Export-AWSRoute53Zone
      * Export-AWSRoute53ZoneList
      * Get-AWSRoute53Zone
      * Install-AWSPowerShell
      * Test-AWSPowerShellInstalled
    * RI-Exchange
      * Enable-ExchangeAnonymousRelay
      * Get-ExchangeMailboxGUID
      * Get-ExchangeSearchHealth
      * Import-ExchangeOnlinePSSession
      * Set-ExchangeScopeToForest
    * RI-FileSystem
      * Rename-UntitledFile
  * RI-Exchange
    * Get-MailboxDisplayName returns the display name of a mailbox.
    * Get-MailboxLocalParts returns the local part of all email addresses associated with a mailbox.
    * Update-AntispamTransportRules updates anti-spam rules designed to combat impersonation attempts.
  * RI-Meta
    * Show-DeprecationWarning displays a deprecation warning for a given command.
### Changes
  * RI-FileSystem
    * Rename-UntitledFile can now take a folder path as a parameter.
  * The following commands are now deprecated:
    * RI-Filesystem
      * Start-ExplorerAsAdmin
    * RI-Application
      * All Integra-related commands
  * The following modules are now deprecated:
    * RI-MozillaFirefox
### Fixes
There are no fixes in this release.

## Version 1.8.0, Build 1304, 2018-06-19
### Additions
  * New module: RI-AmazonWebServices
    * Export-AWSRoute53Zone exports a Route 53 zone to a CSV file.
    * Get-AWSRoute53Zone retrieves a Route 53 zone configuration.
    * Export-AWSRoute53ZoneList exports all zones under a given Amazon Web Services account.
    * Install-AWSPowerShell installs Amazon Web Services PowerShell from the Microsoft PowerShell Gallery.
    * Test-AWSPowerShellInstalled checks if the Amazon Web Services PowerShell module is installed.
  * New module: RI-Web
    * Get-WebPageText retrieves text from a specified URL.
  * RI-ActiveDirectory
    * Update-ADUserInformation updates metadata for an user account.
  * RI-Exchange
    * Enable-ExchangeAnonymousRelay allows anonymous SMTP relay on a receive connector.
### Changes
  * Remove-FilesFromAllUsers will now display deletions as they occur.
  * Get-ExternalIPv4Address
    * Now sends requests over HTTPS instead of HTTP.
    * Switched to ipify REST API call (was using Dyn previously).
### Fixes
There are no fixes in this release.

## Version 1.7.0, Build 1270, 2018-05-29
### Additions
  * Clear-AllMicrosoftOfficeCaches removes Microsoft Office cache files for every user.
  * RI-Git
    * Get-GitFolders returns a list of all Git repositories under a path.
    * Get-GitDiffFolders returns a list of Git repositories that have diffs.
    * Optimize-GitRepositories runs validation and aggressive garbage collection on Git repositories under a path.
    * Test-GitRepository checks if a specified folder contains a Git repository.
    * Start-GitValidation validates a single Git repository specified by a path.
    * Start-GitGarbageCollection starts an aggressive garbage collection of a single Git repository specified by a path.
  * RI-Exchange
    * Get-ExchangeSearchHealth reports the health of the Exchange search index.
  * New module: RI-UserProfiles
     * Start-UserProfiles opens the User Profiles Control Panel applet.
### Changes
  * Added release date information to the release notes.
  * Clear-AllRecycleBins
    * Can now be given a drive letter, clearing the Recycle Bin on that volume.
    * Defaults to C: drive of none is specified.
  * Reset-WindowsSearchCache
    * Added 10 second delay before starting Windows Search service.
### Fixes
There are no fixes in this release.

## Version 1.6.0, Build 1236, 2018-05-22
### Additions
  * Export-BackupLog exports Windows Backup logs to a specified path.
  * RI-FileSystem
    * Clear-AllRecycleBins deletes files from every Recycle Bin on a system.
    * Remove-FilesFromAllUsers deletes files for a given path under every user on a system.
    * Rename-UntitledFile renames untitled files in a prefixed, dated and numbered sequence.
### Changes
  * Format-BarGraph fills the end of a bar with spaces, making it useful for Write-Host -NoNewLine.
  * Watch-Connection (png)
    * Added -SingleLine switch to force updating to only a single line of the console.
### Fixes
  * Fixed bug in Reset-VMHardDiskDrive where pass thru disks would not get reconnected.
  * Corrected help messaging for Install-WindowsUpdates.

## Version 1.5.0, Build 1205, 2018-05-07
### Additions
  * RI-Git
    * Merge-GitRepository automates the merging of two or more Git repositories.
    * Add-GitRemote adds a remote repository.
  * Get-RIPowerShellReleaseNotes displays the current or all release notes for RI PowerShell.
  * Get-IPv4AddressOwner displays information about the owner of a given IP address.
### Changes
  * Past release notes have been moved to releasenotes-archive.md in the Resources folder.
  * Reset-VMHardDiskDrive
    * Added 8 second delay between removal and add of virtual hard drive.
    * Added validation for controller type.
### Fixes
There are no fixes in this release.
    
## Version 1.4.1, Build 1178, 2018-04-20
### Fixes
  * Corrected bug in RI-WSUS that prevented Repair-WsusInstallation from being able to run.

## Version 1.4.0, Build 1176, 2018-04-20
### Additions
  * RI-Diagnostics module
    * New-StopWatch returns a new instance of the StopWatch diagnostic class.
  * RI-WSUS
    * Repair-WsusInstallation rebuilds a WSUS installation on a server (requires Windows Server 2012 or higher).
    * Restart-WsusWebAppPool restarts the Wsus web app pool in IIS on demand.
### Changes
  * Moved Install-HttpActivation45 from RI-WSUS to RI-WindowsServer.
  * RI-WSUS
    * Remove-WsusHiddenUpdates
      * Now displays rate at which updates are being removed in activity display and at end of task.
      * Removed name of last deleted updated from activity display.
      * Reduced WSUS web app pool recycling to every 25 removals.
    * Optimize-WsusContent
      * Now restarts the WSUS web app pool before beginning optimization.
  * Update-RIPowerShell
    * Added Beta switch to optionally install a beta version of RI PowerShell.
### Fixes
  * Corrected behaviour in Update-RIPowerShell that checked for the presence of the Deploy Path instead of the full path to RI PowerShell
  * Restart-WsusWebAppPool now correctly exposed to command line.

## Version 1.3.0, Build 1165, 2018-04-18
### Additions
  * Help content for existing commands:
    * New-GitRepository 
  * RI-Git
    * Copy-GitIgnoreTemplate copies a .gitignore from a template to the current folder.
  * RI-WSUS
    * Restart-WsusWebAppPool recycles the WSUS Web App Pool in IIS.
### Changes
  * Remove-WsusHiddenUpdates
    * This command now requires elevation.
    * Performance improvement by recycling the WSUS web app pool before detection and after every 100 removals.
  * Moved Start-SQLScript from RI-WSUS to RI-SQL 
### Fixes
  * Corrected unnecessary messaging when Remove-WsusHiddenUpdates attempts retries of gathering updates.

## Version 1.2.0, Build 1152, 2018-02-16
### Additions
  * RI-WSUS
    * Remove-WsusHiddenUpdates removes hidden, declined updates from a WSUS server.
  * RI-Git
    * New module for Git related commands.
    * New-GitRepository sets up a Git repository in the current directly, optionally connecting it to a remote.
### Changes
  * Changed case of WSUS commands to be in line with .NET standard (WSUS > Wsus).
### Fixes
  * Corrected behaviour where resolving the FQDN for an HVS in the development domain would resolve for the management domain.
  * Removed extra characters throughout WsusDBMaintenance.sql.

## Version 1.1.0, Build 1127, 2018-02-16
### Additions
  * New-VMIncrementalBackupTask
    * Creates a daily scheduled task to backup a virtual machine incrementally.
  * Help added to the following commands:
    * Backup-VM
    * Install-WindowsServerBackup
### Changes
  * Refactored envar code.
### Fixes
  * Corrected behaviour where incorrect RI-PowerShell envars could be set after a clear screen (cls) command.
  * Corrected incorrect display of version information in the window title bar.
  * Corrected update messaging to include verbose version information.

## Version 1.0.0, Build 1100, 2018-02-13
### Additions
  * Versioning
    * Releases of RI PowerShell will use the Semantic Versioning 2.0.0 standard going forward
    * Build numbers will be displayed for development purposes only
    * Builds numbers will continue to be the underlying criteria to determine if an update has been installed
  * New module: RI-SMB
    * Backup-SMBShare
      * Logs on to a share, copies it to a destination specified by a file, then logs off
  * New module: RI-WindowsSearch
    * Reset-WindowsSearchCache clears the Windows Search cache, resetting the index.
  * RI-Shell
    * Write-MetaMessage replaces methods to write magenta meta messages.
### Changes
  * Moved various build and version functions from RI-Update to RI-Meta
  * Update notifications
    * Removed build indicator for non-development environment
    * Changed wording slightly
  * Restore-VMIncrementalBackup
    * Creates directory if RestorePath is specified and it does not exist
  * Added help information for the following commands:
    * Enter-RDSession
    * Get-VMIncrementalBackupVersions
    * Install-WindowsUpdates
    * Install-WindowsUpdatesRemotely
    * New-VMIncrementalBackupVHD
    * Reset-RemoteDesktopCache
    * Reset-WindowsSearchCache
    * Reset-WindowsUpdateCache
    * Restart-ComputerWithDelay
    * Restore-VMIncrementalBackup
    * Suspend-Computer
  * Removed the following commands from RI-Shell
    * Send-Beep
    * Write-WorkingSummary
  * Update-RIPowerShell
    * Scope additions
    * Dev syncs current branch to local machine, incrementing the build number
    * Deploy updates deploy share, does not affect local machine
    * Scope removals
    * All
### Fixes
  * Update-RIPowerShellDownstreamServers
    * Corrected bug where both release and beta versions of RI PowerShell would be updated if the Beta switch is used
  * Remove-ExchangeMessagesByQuery
    * Properly displays results of deletions
  * Disable-VMQs
    * Fixed bug when attempting to disable a VMQ on a virtual NIC attached to a host