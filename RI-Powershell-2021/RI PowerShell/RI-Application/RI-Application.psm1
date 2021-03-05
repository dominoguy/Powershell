#RI-Application

#Personify

<#
.SYNOPSIS
Resets the Personify cache.

.DESCRIPTION
Resets the user's Personify cache. Upon next logon to Personify, the cache will be rebuilt.
#>
function Reset-PersonifyCache
{
	$cachePath = "TMA Resources Inc\Personify"
	$path = Join-Path -Path $env:APPDATA -ChildPath $cachePath
	Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-HPASTempFiles
{
	if (Test-ShellElevation)
	{
		$hpasAppDataPath = 'AppData\Roaming\HPAS'
		$tempFilePrefix = "frm*.*"
		$fileCount = 0

		$userFolderList = Get-UserFolders

		foreach ($userFolder in $userFolderList)
		{
			$userPath = $userFolder.FullName
			$hpasPath = Join-Path -Path $userPath -ChildPath $hpasAppDataPath
			$pathExists = Test-Path -Path $hpasPath

			if ($pathExists)
			{
				$fileList = Get-ChildItem -Path $hpasPath | Where-Object {$_.Name -like $tempFilePrefix}

				foreach ($file in $fileList)
				{
					$fileName = $file.FullName
					Remove-Item -Path $fileName -ErrorAction SilentlyContinue
					$fileCount++
				}
			}
		}

		Write-Host "`nRemoved $fileCount HPAS temporary file(s).`n"
	}
}

<#
.SYNOPSIS
Resets the Sophos events log.

.DESCRIPTION
Resets the Sophos events log. Tamper Prevention must be disabled to reset the log.
#>
function Reset-SophosEvents
{
	if(Test-ShellElevation)
	{
		$serviceName = 'Sophos Health Service'
		$databasePath = 'C:\ProgramData\Sophos\Health\Event Store\Database\events.db'
		$uiExec = 'Sophos UI.exe'
		$uiPath = 'C:\"Program Files\Sophos\Sophos UI\Sophos UI.exe'

		Stop-Service -Name $serviceName -Force
		Remove-Item -Path $databasePath -Force
		Start-Service -Name $service
		Stop-ProcessByFile -Name $uiExec -Force
		Start-Process -FilePath $uiPath
	}
}

function Stop-ProcessByFile
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$Name,
		[switch]$Force)
	
	$process = Get-Process | Where-Object {$_.Path -like "*\$Name"}
	$process | Stop-Process -Force:$Force
}

function Update-StockSyncInventory
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][string]$FeedID,
		[Parameter(Mandatory=$true)][string]$APIToken,
		[Parameter(Mandatory=$true)][string]$Path)

	$maxFileAgeDays = 7

	$uri = "https://app.stock-sync.com/api/feeds/$FeedID/upload_file?api_token=$APIToken&process_now=true"
	$fileList = Get-ChildItem -Path $Path -File | Sort-Object -Property LastWriteTime -Descending
	$newestFile = $fileList[0]
	$newestFilePath = $newestFile.FullName

	if ($newestFilePath)
	{
		Send-MultiPartContent -Path $newestFilePath -Uri $uri -Provider Curl
		Remove-OldFiles -Path $Path -AgeDays $maxFileAgeDays
		$message = "Uploaded $newestFilePath to StockSync."
		New-RIPowerShellApplicationEvent -Message $message -EntryType Information -EventID 2800
	}
	else
	{
		$message = "No new file found at $Path to upload to StockSync."
		New-RIPowerShellApplicationEvent -Message $message -EntryType Warning -EventID 2900
	}
}