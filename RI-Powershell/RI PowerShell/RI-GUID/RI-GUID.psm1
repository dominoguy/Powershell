#RI-GUID

function New-GUIDString
{
	$guidObject = [guid]::NewGuid()
	$guid = $guidObject.ToString()
	
	return $guid
}