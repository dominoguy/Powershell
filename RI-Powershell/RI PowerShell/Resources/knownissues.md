# Known Issues in RI PowerShell

The following is a list of known issues in RI PowerShell:

* Remoting
  * Enter-PSSessionWithConfiguration (rps) throws an error when connecting to a computer that does not have the RI PowerShell event log already setup.
* PowerShell Core Compatibility
  * Logging does not function and has been disabled.
  * Start-BitsTransfer does not function. The following commands are therefore affected:
    * Copy-SysinternalsTools
    * dl (alias)
  * Watch-Connection (png) displays verbose information.
