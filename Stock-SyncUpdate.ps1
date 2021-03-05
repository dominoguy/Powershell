#Stock-Sync Update

function New-HttpClient
{
	Add-Type -AssemblyName System.Net.Http
	$httpClientHandler = New-Object System.Net.Http.HttpClientHandler
	$httpClient = New-Object System.Net.Http.HttpClient $httpClientHandler

	return $httpClient
}


function Send-MultiPartContent
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true)][ValidateSet('Curl','PowerShell')][string]$Provider,
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][string]$Uri)

	if ($Provider -eq 'Curl')
	{
		$curlPath = 'C:\Program Files\Curl\curl.exe'
		$curlExists = (Test-Path -Path $curlPath)

		if ($curlExists)
		{
			$processArgs = '-X POST',
				'--header "Content-Type: multipart/form-data"',
				'--header "Accept: application/json"',
				'-F',
				"file=@`"$Path`"",
				$uri,
				'--insecure'
			Write-Verbose -Message "Sending $Path to $Uri"
			Start-Process -FilePath $curlPath -ArgumentList $processArgs -NoNewWindow -Wait -PassThru
		}
		else
		{
			Write-Host 'The requested operation requires Curl.'
		}
	}

	if ($Provider -eq 'PowerShell')
	{
		Add-Type -AssemblyName System.Net.Http
		$contentType = Get-ContentType -Path $Path
		$httpClient = New-HttpClient
		$fileStream = New-FileStream -Path $Path
		$contentDispositionHeaderValue = New-FileDispositionHeader -Path $Path
		$streamContent = New-Object System.Net.Http.StreamContent $fileStream
		$streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
		$streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $contentType
		$multiPartContent = New-Object System.Net.Http.MultiPartFormDataContent
		$multiPartContent.Add($streamContent)
		$response = $httpClient.PostAsync($Uri, $multiPartContent).Result

		return $response
	}
}

function Remove-OldFiles
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$Path,
		[Parameter(Mandatory=$true,Position=2)][string]$AgeDays)
	
	$limit = (Get-Date).AddDays(-$AgeDays)

	Get-ChildItem -Path $Path -Recurse -Force | `
		Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | `
		Remove-Item -Force
}

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
