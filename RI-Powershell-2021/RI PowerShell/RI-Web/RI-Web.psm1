#RI-Web

function Copy-HttpFile
{
	param(
		[Parameter(Mandatory=$true)][string]$URL)
		
	$fileName = Split-Path -Path $URL -Leaf 
	$filePath = ".\$fileName"
	$webClient = New-Object System.Net.WebClient
	$webClient.DownloadFile($URL, $filePath)
}

function Get-ContentType
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	Add-Type -AssemblyName System.Web
	$mimeType = [System.Web.MimeMapping]::GetMimeMapping($Path)

	if ($mimeType)
	{
		$contentType = $mimeType
	}
	else
	{
		$contentType = 'application/octet-stream'
	}

	return $contentType
}

function Get-WebPageText
{
	param(
        	[Parameter(Mandatory=$true)][string]$URL)

	$webClient = New-Object System.Net.WebClient
	$text = $webClient.DownloadString($URL)

	return $text
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

function New-HttpClient
{
	Add-Type -AssemblyName System.Net.Http
	$httpClientHandler = New-Object System.Net.Http.HttpClientHandler
	$httpClient = New-Object System.Net.Http.HttpClient $httpClientHandler

	return $httpClient
}

function New-FileDispositionHeader
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	Add-Type -AssemblyName System.Net.Http
	$contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue 'form-data'
	$contentDispositionHeaderValue.Name = 'fileData'
	$contentDispositionHeaderValue.FileName = (Split-Path $Path -leaf)

	return $contentDispositionHeaderValue
}

function New-FileStream
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	$fileStream = New-Object System.IO.FileStream @($Path, [System.IO.FileMode]::Open)

	return $fileStream
}