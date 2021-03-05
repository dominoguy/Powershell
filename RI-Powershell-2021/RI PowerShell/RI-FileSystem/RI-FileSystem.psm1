#RI-FileSystem

<#
.SYNOPSIS
Copies a folder recursively.

.DESCRIPTION
Copies a folder recursively using RoboCopy. The destination folder becomes a mirror of the source. If the destination folder already exists, the Force switch is required.

.PARAMETER Source
Source folder to copy.

.PARAMETER Destination
Destination folder.

.PARAMETER BackupMode
Copies in Backup Mode, using the Backup Operator APIs. You must be a member of the Backup Operators group to use this option.

.PARAMETER ExcludeJunctions
Excludes file and folder junctions. Do not use when copying files from a deduplicated volume or data loss could occur.

.PARAMETER IncludePermissions
Copies permissions as well as files.

.PARAMETER Force
Overwrites the destination folder if it already exists.

.EXAMPLE
Copy-FolderRecursively \\GL-FS-001\foo \\GL-FS-001\bar -IncludePermissions -Force
#>
function Copy-FolderRecursively
{
	[CmdletBinding()]

	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Source,
		[Parameter(Mandatory=$true,Position=2)][string]$Destination,
		[switch]$BackupMode,
		[switch]$ExcludeJunctions,
		[switch]$IncludePermissions,
		[switch]$Force)
	
	$destinationExists = Test-Path -Path $Destination

	if (!$destinationExists -or $Force)
	{
		$arguments = '/MIR /W:0 /R:0 /NFL /NDL'

		if ($BackupMode)
		{
			$arguments += ' /B'
		}

		if ($ExcludeJunctions)
		{
			$arguments += ' /XJ /XJD'
		}

		if ($IncludePermissions)
		{
			$arguments += ' /COPY:DATSO'
		}

		$trimmedSource = Remove-PathTrailingSlashes -Path $Source
		$trimmedDestination = Remove-PathTrailingSlashes -Path $Destination
		robocopy.exe $trimmedSource $trimmedDestination $arguments.Split(' ')
	}
	else
	{
		Write-Warning -Message 'Destination already exists. Use -Force to overwrite.'
	}
}

function Expand-ZipFile
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$File,
		[Parameter(Mandatory=$true,Position=2)][string]$Destination)
	
	$pathExists = Test-Path $Destination

	if (!$pathExists)
	{
		mkdir $Destination
	}
	
	Add-Type -Assembly 'System.IO.Compression.Filesystem'
	[io.compression.zipfile]::ExtractToDirectory($File,$Destination)
}

function Remove-PathTrailingSlashes
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	$trimmedPath = $Path.TrimEnd('\','/')

	return $trimmedPath
}

function Export-DisabledADUserFiles
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Source,
		[Parameter(Mandatory=$true)][string]$HomeDestination,
		[Parameter(Mandatory=$true)][string]$ProfileDestination,
		[switch]$Force)
	
	$disabledUserList = Get-ADDisabledUsers
	
	for ($i = 0; $i -lt $disabledUserList.Count; $i++)
	{
		$user = $disabledUserList[$i]
		$username = $user.samAccountName

		Export-ADUserFiles `
			-Identity $username `
			-HomeDestination $HomeDestination `
			-ProfileDestination $ProfileDestination `
			-Force:$Force

		$activity = 'Export-DisabledUserFiles' 
		$status = "Exporting home folder for : $name"
		$percentComplete = ($i/$disabledUserList.Count*100)
		Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
	}
}

<#
.SYNOPSIS
Exports files associated with an ActiveDirectory account.

.DESCRIPTION
Exports home and roaming profile folders associated with an ActiveDirectory account.

The user of must be a member of the Backup Operators group.

.PARAMETER Identity
Identity of the account.

.PARAMETER HomeDestination
Path to export the home folder to.

.PARAMETER ProfileDestination
Path to export the roaming profile(s) to.

.PARAMETER TakeOwnership
Takes ownership of the folders before copying files. This switch is now deprecated.

.PARAMETER Force
Overwrites the destination if it already exists.

.EXAMPLE
Export-ADUserFiles -Identity foobar -HomeDestination \\FOO-FS-001\Archive\Users
#>
function Export-ADUserFiles
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Identity,
		[string]$HomeDestination,
		[string]$ProfileDestination,
		[switch]$TakeOwnership,
		[switch]$Force)

	if ($HomeDestination)
	{
		Export-ADHomeFolder `
			-Identity $Identity `
			-HomeDestination $HomeDestination `
			-TakeOwnership:$TakeOwnership `
			-Force:$Force
	}

	if ($ProfileDestination)
	{
		Export-ADProfileFolder `
			-Identity $Identity `
			-ProfileDestination $ProfileDestination `
			-TakeOwnership:$TakeOwnership `
			-Force:$Force
	}
}

function Export-ADProfileFolder
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Identity,
		[Parameter(Mandatory=$true)][string]$ProfileDestination,
		[switch]$TakeOwnership,
		[switch]$Force)

	$userAccount = Get-ADUser -Identity $Identity -Properties *
	$profileFolderPath = $userAccount.ProfilePath

	if ($profileFolderPath)
	{
		$profileFolderList = Get-ChildItem -Path "$profileFolderPath*" -Directory

		foreach ($profileFolder in $profileFolderList)
		{
			$source = $profileFolder.FullName
			$childPath = Split-Path -Path $source -Leaf
			$destination = Join-Path -Path $ProfileDestination -ChildPath $childPath
			Copy-FolderRecursively -Source $source -Destination $destination -BackupMode -Force:$Force
		}
	}
}

function Export-ADHomeFolder
{
	[CmdletBinding()]
	
	param(
		[Parameter(Mandatory=$true)][string]$Identity,
		[Parameter(Mandatory=$true)][string]$HomeDestination,
		[switch]$TakeOwnership,
		[switch]$Force)
	
	$userAccount = Get-ADUser -Identity $Identity -Properties *
	$username = $userAccount.samAccountName
	$homeFolder = $userAccount.HomeDirectory
	$homeFolderExists = Test-Path -Path $homeFolder

	if ($homeFolderExists)
	{
		$destination = Join-Path -Path $HomeDestination -ChildPath $username
		Copy-FolderRecursively -Source $homeFolder -Destination $destination -BackupMode -Force:$Force
	}
}

function Format-Length
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][int64]$Length)
		
	switch ($Length)
	{
		{$_ -ge 1TB}
			{
				$lengthRounded = '{0:N2}' -f ($Length/1TB)
				$lengthFormatted = "$lengthRounded TB"
				break
			}
		{$_ -ge 1GB}
			{
				$lengthRounded = '{0:N2}' -f ($Length/1GB)
				$lengthFormatted = "$lengthRounded GB"
				break
			}
		{$_ -ge 1MB}
			{
				$lengthRounded = '{0:N2}' -f ($Length/1MB)
				$lengthFormatted = "$lengthRounded MB"
				break
			}
		{$_ -ge 1KB}
			{
				$lengthRounded = '{0:N2}' -f ($Length/1KB)
				$lengthFormatted = "$lengthRounded KB"
				break
			}
		default
			{
				$lengthRounded = '{0:N2}' -f $Length
				$lengthFormatted = "$lengthRounded B"
			}
	}
		
	return $lengthFormatted
}

function Get-AvailableDriveLetter
{
	[CmdletBinding()]

	param(
		[parameter(Mandatory=$False)][switch]$First)
	  
		$usedLetterList = @(Get-Volume | ForEach-Object { "$([char]$_.DriveLetter)"}) + @(Get-CimInstance -ClassName Win32_MappedLogicalDisk| ForEach-Object{$([char]$_.DeviceID.Trim(':'))})
		$availableLetterList = @(Compare-Object -DifferenceObject $usedLetterList -ReferenceObject $( 67..90 | ForEach-Object { "$([char]$_)" } ) | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject })
		$availableLetterList = ($availableLetterList | Sort-Object)
		
		if ($First)
		{
		   return $availableLetterList[0]
		}
		else
		{
			return $availableLetterList
		}
}

function Get-FolderSize
{
	param(
	    [Parameter(Position=1)][string]$Path = '.\',
		[switch]$Children)
	
	$pathExists = Test-Path -Path $Path
	
	if ($pathExists)
	{
		if ($Children)
		{
			$table = @()
			$childFolderList = Get-ChildItem -Path $Path -Directory

			foreach ($childFolder in $childFolderList)
			{
				$childPath = $childFolder.fullName
				$length = $childFolder | Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue `
					| Measure-Object -Property Length -Sum
				$tableEntry = New-Object -TypeName psobject -Property @{
							Path = $childPath
							Length = $length.Sum
						}
				$table += $tableEntry
			}

			$table
		}
		else
		{
			$length = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue `
				| Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
			$lengthFormatted = Format-Length $length.Sum
			Write-Output $lengthFormatted 
		}
	}
	else
	{
		Write-Host "`nCannot find path $Path because it does not exist.`n" -ForegroundColor Red
	}
}

function Get-UserFolders
{
	$usersPath = 'C:\Users'
	$userFolders = Get-ChildItem -Path $usersPath -Directory
	
	return $userFolders
}

function New-ZipFileFromDirectory
{
	param(
	    [Parameter(Mandatory=$true,Position=1)][string]$Path,
		[Parameter(Mandatory=$true,Position=2)][string]$FileName)
	
	$compressionLevel = 'Optimal'
	$includeBaseDirectory = $true
	Add-Type -As System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::CreateFromDirectory($Path, $FileName, $compressionLevel, $includeBaseDirectory)
}
function Remove-FilesFromAllUsers
{
	param(	
		[Parameter(Mandatory=$true,Position=1)][string]$Path,
		[switch]$Recurse)
		
	$userFolderList = Get-UserFolders
	
	foreach ($userFolder in $userFolderList)
	{
		$userPath = $userFolder.FullName
		$removePath = Join-Path -Path $userPath -ChildPath $Path
		$pathExists = Test-Path -Path $removePath

		if ($pathExists)
		{
			Remove-Item -Path $removePath -Force -Recurse:$Recurse -Verbose
		}
	}
}

function Clear-AllRecycleBins
{
	param(
		[Parameter(Position=1)][string]$DriveLetter = 'C')
		
	$DriveLetter = $DriveLetter + ':\'
	$recycleBinFolder = '$Recycle.Bin'
	$recycleBinPath = Join-Path -Path $DriveLetter -ChildPath $recycleBinFolder
	$folderList = Get-ChildItem -Path $recycleBinPath -Directory -Force
	
	foreach ($folder in $folderList)
	{
		$folderPath = $folder.FullName
		$removePath = Join-Path -Path $folderPath -ChildPath '*'
		Remove-Item -Path $removePath -Recurse -Force
	}
}

function Clear-AllMicrosoftOfficeCaches
{
	$cachePath = 'AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.MSO\*'
	Remove-FilesFromAllUsers -Path $cachePath
}

function Grant-AdministratorAccessToFolder
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Path)
	
	if (Test-ShellElevation)
	{
		$pathExists = Test-Path -Path $Path
	
		if ($pathExists)
		{
			$permissions = 'Administrators:(OI)(CI)(F)'
			
			takeown.exe /F $Path /A /R /D Y
			icacls $Path /grant $permissions /T /C /Q
		}
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

<#
.SYNOPSIS
Renames all untitled files in folder.

.DESCRIPTION
Renames all untitled files in a folder with a named prefix, date and number. The resulting file name is as below:

prefix-YYYY-MM-DD-nnn.extension

If the command was run on June 22nd, 2018 for a group of files named untitled.png, untitled2.png and untitled3.png, the following new names would be assigned:

prefix-2018-06-22-001.png
prefix-2018-06-22-002.png
prefix-2018-06-22-003.png

.PARAMETER Prefix
Prefix to use for the renamed files.

.PARAMETER Path
Path to the folder to rename files in. If none is specified, the current folder is used.

.EXAMPLE
Rename-UntitledFile foo -Path C:\bar
#>
function Rename-UntitledFile
{
	param(
		[Parameter(Mandatory=$true,Position=1)][string]$Prefix,
		[string]$Path = '.\')
		
	$numberFormat = "000"
	$filePattern = "untitled*.*"
	$fileNumber = 1
	$date = Get-FormattedDate
	$fileList = Get-ChildItem -Path "$Path\$filePattern"

	foreach ($file in $fileList)
	{
		$fileExtension = $file.Extension
		$nameExists = $true
		
		do
		{
			$number = $fileNumber.ToString($numberFormat)
			$newName = "$Prefix-$date-$number$fileExtension"
			$nameExists = Get-ChildItem -Path $newName -ErrorAction SilentlyContinue
			$fileNumber++
		}
		while ($nameExists)

		$filePath = $file.fullName
		Rename-Item -Path $filePath -NewName $newName
	}
}

<#
.SYNOPSIS
Removes a folder containing long paths.

.DESCRIPTION
Removes a folder containing long paths.

.PARAMETER Path
Path to the folder to remove.

.EXAMPLE
Remove-FolderWithLongPaths -Path H:\foo
#>
function Remove-FolderWithLongPaths
{
	param(
		[Parameter(Mandatory=$true)][string]$Path)

	if	(Test-ShellElevation)
	{
		$emptyName = New-GUIDString
		$emptyFolder = Join-Path -Path $env:TEMP -ChildPath $emptyName
		New-Item -Path $emptyFolder -Type Directory | Out-Null
		Copy-FolderRecursively -Source $emptyFolder -Destination $Path -Force | Out-Null
		Remove-Item -Path $emptyFolder,$Path
	}
}

function New-TempFolder
{
	$emptyName = New-GUIDString
	$emptyFolder = Join-Path -Path $env:TEMP -ChildPath $emptyName
	$tempFolder = New-Item -Path $emptyFolder -Type Directory
	
	return $tempFolder
}