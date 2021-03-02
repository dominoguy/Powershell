#RI-TranslationMapping

<#
.SYNOPSIS 
Imports a mapping file.

.DESCRIPTION
Imports a mapping file for a specified module and command from the respective RI PowerShell settings file.

.PARAMETER Module
Module for the mapping file.

.PARAMETER File
Name of the mapping file.

.EXAMPLE
Import-Mapping -Module RI-TranslationMapping -Command map.csv
#>
function Import-Mapping
{
    [CmdletBinding()]

	param(
        [Parameter(Mandatory = $True)][string]$Module,
        [Parameter(Mandatory = $True)][string]$File)
        
    $filePath = "$Module\$File"
    $settingsPath = Get-RIPowerShellUserSettingsPath
    $path = Join-Path -ChildPath $filePath -Path $settingsPath
    $fileExists = Test-Path -Path $path
    
    if ($fileExists)
    {
        $mappings = Import-Csv -Path $path

        return $mappings
    }
    else
    {
        return $null    
    }
}

function Import-TranslationMapping
{
    $mappings = Import-Mapping -Module 'RI-TranslationMapping' -File 'map.csv' 

	return $mappings
}

function Convert-OwnerToFQDN
{
    param(
        [Parameter(Mandatory=$true)][string]$Owner)
        
    $mappingList = Import-TranslationMapping
    $mapping = $mappingList | Where-Object {$_.prefix -eq $Owner}

    return $mapping    
}

function Convert-NetbiosNameToFQDN
{
    param(
        [Parameter(Mandatory=$true)][string]$ComputerName,
        [string]$Owner)
    
    $mapping = @()
    
    if ($Owner)
    {
        $mapping = Convert-OwnerToFQDN -Owner $Owner
    }
    else
    {
        $computerNamePrefix = $ComputerName -replace '-\w*-\d*$',''
        $mapping = Convert-OwnerToFQDN -Owner $computerNamePrefix
    }
        
    if ($mapping)
    {
        $computerFQDN = $ComputerName + '.' + $mapping[0].domain

        if (!$Owner)
        {
            $hvsNetbiosFormat = '^\w*-HVS-\d*$'
            
            if ($computerName -match $hvsNetbiosFormat)
            {
                $inDevelopmentEnvironment = Test-DevelopmentEnvironment -HideMessage
                
                if (!$inDevelopmentEnvironment)
                {
                    $managementDomain = Get-ManagementDomain
                    $computerFQDN = $computerName + '.' + $managementDomain
                }
            }
        }

        return $computerFQDN
    }
    else
    {
        return $ComputerName    
    }
}