#RI-AmazonWebServices

<#
.SYNOPSIS
Exports an AWS Route 53 zone to a CSV file.

.DESCRIPTION
Exports a DNS zone hosted by AWS Route 53 to a CSV file.

.PARAMETER ID
ID of the zone to export.

.PARAMETER ProfileName
AWS profile to use.

.PARAMETER Path
Path to export the CSV file to.

.EXAMPLE
Export-AWSRoute53Zone -ID Z124098231 -ProfileName Foo -Path .\bar.csv
#>
function Export-AWSRoute53Zone
{
    param(
	    [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$ProfileName,
        [Parameter(Mandatory=$true)][string]$Path)
    
    if (Test-AWSPowerShellInstalled)
    {
        $recordSets = Get-AWSRoute53Zone -Id $ID -ProfileName $ProfileName
        $recordSets | `
            Select-Object name,type,ttl,{$_.resourceRecords.value} | `
            Export-Csv -Path $Path -NoTypeInformation
    }
}

<#
.SYNOPSIS
Exports all AWS Route 53 zones to CSVs.

.DESCRIPTION
Exports all Route 53 zones under a given AWS account to individual CSV files.

.PARAMETER ProfileName
AWS profile to use.

.PARAMETER Path
Path to folder to export the CSVs to. If no folder is specified, files are saved to the current directory.

.EXAMPLE
Export-AWSRoute53ZoneList -ProfileName Foo -Path .\DNS
#>
function Export-AWSRoute53ZoneList
{
    param(
        [Parameter(Mandatory=$true)][string]$ProfileName,
        [string]$Path = '.\')

    if (Test-AWSPowerShellInstalled)
    {
        $zonePrefix = '/hostedzone/'
        $zoneList = Get-R53HostedZoneList -ProfileName $ProfileName

        foreach ($zone in $zoneList)
        {
            $zoneID = $zone.ID -replace $zonePrefix,''
            $fileName = "record-$zoneID.csv"
            $filePath = Join-Path -Path $Path -ChildPath $fileName
            Export-AWSRoute53Zone -ID $zoneID -ProfileName $ProfileName -Path $filePath
        }
    }
}

<#
.SYNOPSIS
Returns records for an AWS Route 53 zone.

.DESCRIPTION
Returns DNS records sets for an AWS Route 43 zone.

.PARAMETER ID
ID of the zone to export.

.PARAMETER ProfileName
AWS profile to use.

.EXAMPLE
Get-AWSRoute53Zone -ID Z124098231 -ProfileName Foo
#>
function Get-AWSRoute53Zone
{
    param(
	    [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$ProfileName)

    if (Test-AWSPowerShellInstalled)
    {
        $zone = Get-R53ResourceRecordSet -Id $ID -ProfileName $ProfileName
        $recordSets = $zone.ResourceRecordSets
    
        return $recordSets
    }
}

<#
.SYNOPSIS
Installs the AWS PowerShell module.

.DESCRIPTION
Install the AWS PowerShell module from the Microsoft PowerShell gallery.
#>
function Install-AWSPowerShell
{
    if (Test-ShellElevation)
    {
        Install-Module -Name AWSPowerShell
    }
}

<#
.SYNOPSIS
Checks if AWS PowerShell is installed.

.DESCRIPTION
Checks if AWS PowerShell is installed.
#>
function Test-AWSPowerShellInstalled
{
    $installed = Get-Module -FullyQualifiedName AWSPowerShell -ListAvailable

    if ($installed)
    {
        return $true
    }
    else
    {
        Write-Host "Amazon Web Services (AWS) PowerShell module is not installed."
        
        return $false
    }
}