#RI-SSH

function Get-PLinkPath
{
    $path = 'C:\Program Files\PLink\plink.exe'

    return $path
}

function Test-PLinkInstall
{
    $path =  Get-PLinkPath
    $installed = Test-Path -Path $path

    return $installed
}

function Get-SSHProvider
{
    if (Test-PLinkInstall)
    {
        $provider = 'PLink'

        return $provider
    }

    return $false
}

function Send-SSHCommand
{
    param(
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][int]$Port,
        [Parameter(Mandatory=$true)][string]$HostKey,
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password,
        [Parameter(Mandatory=$true)][string]$Command)

    $provider = Get-SSHProvider

    if ($provider -eq 'PLink')
    {
        $providerPath = Get-PLinkPath
        $argumentList = "-ssh -P $Port $Username@$Server -hostkey $HostKey -pw $Password `"$Command`""

        Start-Process -FilePath $providerPath -ArgumentList $argumentList -NoNewWindow -Wait
    }
    else
    {
        Write-Error -Message 'No SSH providers were found. Install a compatible provider and retry the command.'
    }
}

function Send-SSHCommandFromFile
{
    param(
        [Parameter(Mandatory=$true)][string]$CSVPath,
        [Parameter(Mandatory=$true)][string]$CommandPath)
    
    $hostList = Import-Csv -Path $CSVPath
    $command = Get-Content -Path $CommandPath | Out-String
    $provider = Get-SSHProvider

    if ($provider)
    {
        foreach ($host in $hostList)
        {
            $server = $host.server
            $port = $host.port
            $hostKey = $host.hostKey
            $username = $host.username
            $password = $host.password

            Send-SSHCommand `
                -Server $server `
                -Port $port `
                -HostKey $hostKey `
                -Username $username `
                -Password $password `
                -Command $command
        }
    }
    else
    {
        Write-Error -Message 'No SSH providers were found. Install a compatible provider and retry the command.'
    }
}