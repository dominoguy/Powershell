#RI-Parsing

function Get-ValueFromContent
{
	param(
		[Parameter(Mandatory=$true,Position=1)][AllowEmptyString()][String[]]$Content,
		[Parameter(Mandatory=$true,Position=2)][string]$Label,
		[string[]]$RemoveCharacters,
		[switch]$RemoveCommonCharacters,
		[switch]$RemoveWhitespace)
		
	$commmonCharacters = '=','"',';','\$','~'
	$leadingWhitespace = '^\s*'
	
	$value = $Content | Where-Object {$_ -like "*$Label*"}
	$value = $value -replace $Label,''
	
	foreach ($character in $RemoveCharacters)
	{
		$value = $value -replace $character,''
	}
	
	if ($RemoveCommonCharacters)
	{
		foreach ($character in $commmonCharacters)
		{
		$value = $value -replace $character,''
		}
	}
	
	$value = $value -replace $leadingWhitespace,''
	
	if($RemoveWhitespace)
	{
		$value = $value -replace "\s",''
	}
	
	return $value
}