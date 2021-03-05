#RI-BitLocker

function Start-BitLockerEncryption
{
    param(
        [switch]$Restart)
        
    if (Test-ShellElevation)
    {
        $tpm = Test-TPMEnabled
        $bitLockerVolume = Test-BitLockerSystemVolume
        
        if ($tpm -and $bitLockerVolume)
        {
            if (Test-BitLockerSystemVolumeNotEncrypted)
            {
                New-BitLockerRecoveryPasswordKey
                New-BitLockerTPMKey
                Start-BitLockerEncryptionOfSystemDrive
                Backup-BitLockerKeyToAD
                
                if ($Restart)
                {
                    Restart-ComputerWithDelay -DelaySeconds 60
                }
            }
        }
    }
}

<#
.SYNOPSIS
Tests for a TPM device.

.DESCRIPTION
Tests for the presence of a Trusted Platform Module (TPM) device.
#>
function Test-TPMEnabled
{ 
    $tpm = Get-CimInstance -ClassName win32_tpm -Namespace root\cimv2\security\microsofttpm

    if ($tpm)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Test-BitLockerSystemVolume
{
    $bitLockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive

    return $bitLockerVolume
}

function Test-BitLockerSystemVolumeNotEncrypted
{
    $bitLockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive
    
    if ($bitLockerVolume.VolumeStatus -eq  'FullyDecrypted')
    {
        return $true
    }
    else
    {
        return $false
    }
}

function New-BitLockerRecoveryPasswordKey
{
    Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector
}

function New-BitLockerTPMKey
{
    Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -TpmProtector
}

function Start-BitLockerEncryptionOfSystemDrive
{
    $encyptionMethod = "xts_aes256"
    Start-Process 'manage-bde.exe' -ArgumentList " -on $env:SystemDrive -em $encyptionMethod" -Verb runas -Wait
}

<#
.SYNOPSIS
Stores the BitLocker key to AD.

.DESCRIPTION
Stores a copy of the BitLocker key to Active Directory.
#>
function Backup-BitLockerKeyToAD
{
    $recoveryKeyID = (Get-BitLockerVolume -MountPoint $env:SystemDrive).keyprotector | `
        Where-Object {$_.Keyprotectortype -eq 'RecoveryPassword'} | `
        Select-Object -ExpandProperty KeyProtectorID
    Backup-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $recoveryKeyID
}