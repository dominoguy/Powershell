#RI-Git

<#
.SYNOPSIS
Creates a new Git repository, optionally adding a remote.

.DESCRIPTION
This command simplifies the process of creating a new Git repository. After checking for a .gitignore file, it initalizes the repo in the current folder, adds all files and does an inital commit.

Internally, the following commands are run:

    git init
    git add *
    git commit -a -m "Initial Commit"

If a remote is specified, it is added as origin and a push is made:

    git remote add origin <path to repository>
    git push -u origin master

.PARAMETER Remote
Path to a remote repository.

.EXAMPLE
New-GitRepository http://git.foo.bar/FooBar.git
#>
function New-GitRepository
{
    param(
        [Parameter(Position=1)][string]$Remote)

    $gitignoreFile = '.\.gitignore'
    $gitignoreExists = Test-Path -Path $gitignoreFile

    if ($gitignoreExists)
    {
        git init
        git add *
        git commit -a -m "Initial Commit"

        if ($Remote)
        {
            Add-GitRemote -Remote $Remote
            git push -u origin master
        }
    }
    else
    {
        Write-Warning -Message '.gitignore is missing. Please create one in this directory and try again.'
    }
}

<#
.SYNOPSIS
Creates a new tag in a Git repository.

.DESCRIPTION
Creates a new tag for a given commit in a Git repository, then pushes it the remote repository.

.PARAMETER Tag
Name of the tag to create.

.PARAMETER Commit
The commit to assign the tag to.

.EXAMPLE
New-GitTag -Tag 'v1.7.0' -Commit 6ea919a
#>
function New-GitTag
{
    param(
        [Parameter(Position=1)][string]$Tag,
        [Parameter(Position=2)][string]$Commit)

    git tag $Tag $Commit
    git push origin $Tag
}

<#
.SYNOPSIS
Copies a .gitignore template file to the current directory.

.DESCRIPTION
This command copies a .gitignore file from a folder specified by the Name parameter under Settings\Git (found in the Programming Path) to the current directory.

.PARAMETER Name
Name of the type of template to copy.

.EXAMPLE
Copy-GitIgnoreTemplate Python
#>
function Copy-GitIgnoreTemplate
{
    param(
        [Parameter(Position=1)][string]$Name)

    $programmingPath = Get-ProgrammingPath
    $templatesRoot = Join-Path -Path $programmingPath -ChildPath 'Settings\Git'
    $folder = Join-Path -Path $templatesRoot -ChildPath $Name
    $filePath = Join-Path -Path $folder -ChildPath '.gitignore'
    $pathExists = Test-Path -Path $filePath

    if ($pathExists)
    {
        Copy-Item -Path $filePath
    }
    else
    {
        Write-Warning -Message "Cannot find .gitignore template at $folder."
    }
}

function Get-GitFolders
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $folderList =@()
    $gitRootPathList = @()

    $Path = Remove-PathTrailingSlashes -Path $Path
    $parentFolder = Get-Item -Path $Path
    $childList = Get-ChildItem -Directory -Path $Path -Recurse
    $folderList += $parentFolder
    $folderList += $childList

    foreach ($folder in $folderList)
    {
        $folderPath = $folder.FullName
        $gitRepoExists = Test-GitRepository -Path $folderPath

        if ($gitRepoExists)
        {
            $gitRootPathList += $folderPath
        }
    }

    return $gitRootPathList
}

function Get-GitBareFolders
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $gitRootPathList = @()

    $Path = Remove-PathTrailingSlashes -Path $Path
    $folderList = Get-ChildItem -Directory -Path $Path

    foreach ($folder in $folderList)
    {
        $folderPath = $folder.FullName
        $gitRepoExists = Test-GitBareRepository -Path $folderPath

        if ($gitRepoExists)
        {
            $gitRootPathList += $folderPath
        }
    }

    return $gitRootPathList
}

function Rename-GitLastCommit
{
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=1)][string]$Message)

    git commit --amend -m $Message
}

function Test-GitRepository
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $gitFolder = '.git'
    $gitPath = Join-Path -Path $Path -ChildPath $gitFolder
    $gitExists = Test-Path -Path $gitPath

    return $gitExists
}

function Test-GitBareRepository
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $result = git -C $Path rev-parse --is-bare-repository

    if ($result -eq 'true')
    {
        return $true
    }
    else
    {
        return $false
    }
}

<#
.SYNOPSIS
Merges two or more Git repositories.

.DESCRIPTION
This command merges two or more Git remote repositories into the current local one.

.PARAMETER Remote
URLs to remote repositories to merge into the current local one.

.EXAMPLE
Merge-GitRepository http://foo.bar.foobar/foo.git
#>
function Merge-GitRepository
{
    param(
        [Parameter(Mandatory=$true,Position=1)][string[]]$Remote)

    $excludeList = @('.gitignore')

    foreach ($remoteAddress in $Remote)
    {
        $repoName = Convert-GitRemoteToName -Remote $remoteAddress
        Add-GitRemote -Name $repoName -Remote $remoteAddress -Fetch

        git merge "$repoName/master" --allow-unrelated-histories
        git commit -m "Merge - Commit for $repoName"

        mkdir $repoName
        $excludeList += $repoName
        $fileList = Get-ChildItem -Exclude $excludeList

        foreach ($file in $fileList)
        {
            git mv $file.Name $repoName
        }

        git commit -m "Merge - Moved files into subdirectory $repoName"
        git remote rm $repoName
    }
}

function Convert-GitRemoteToName
{
    param(
        [Parameter(Mandatory=$true)][string]$Remote)

    $name = $Remote -replace "http:\/\/.*\/",''
    $name = $name -replace '.git',''

    return $name
}

<#
.SYNOPSIS
Adds a remote to a Git repository.

.DESCRIPTION
Adds a remote repository to a Git local repository.

.PARAMETER Name
Name to assign to the remote. If none is specified origin is used.

.PARAMETER Remote
URL to the remote repository.

.PARAMETER Fetch
If this parameter is specified a Git fetch is performed.

.EXAMPLE
Add-GitRemote -Remote http://foo.bar.foobar/foo.git -Name foo
#>
function Add-GitRemote
{
    param(
        [Parameter(Mandatory=$true)][string]$Remote,
        [string]$Name='origin',
        [switch]$Fetch)

    if ($Fetch)
    {
        git remote add -f $Name $Remote
    }
    else
    {
        git remote add $Name $Remote
    }
}

function Merge-GitBranchToMaster
{
    param(
        [Parameter(Mandatory=$true,Position=1)][string]$Branch)

    git checkout master
    git merge $Branch
    git branch -d $Branch
}

function Optimize-GitRepositories
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $gitRootPathList = Get-GitFolders -Path $Path
    Start-GitOptimization -Path $gitRootPathList
}

function Optimize-GitBareRepositories
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    $gitRootPathList = Get-GitBareFolders -Path $Path
    Start-GitOptimization -Path $gitRootPathList
}

function Publish-GitBranch
{
    param(
            [Parameter(Mandatory=$true,Position=1)][string[]]$Branch)

    git push -u origin $Branch
}

<#
.SYNOPSIS
Removes all non-master branches from a Git repo.

.DESCRIPTION
Removes all non-master branches from a Git repository.

.PARAMETER Force
Forces the removal of a branch even if its content has not been merged to master.

.EXAMPLE
Remove-GitNonMasterBranches -Force
#>
function Remove-GitNonMasterBranches
{
	[CmdletBinding()]

    param(
        [switch]$Force)
    
    git checkout master
    $nonMasterBranchList = Get-GitNonMasterBranches

    foreach ($nonMasterBranch in $nonMasterBranchList)
    {
        if ($Force)
        {
            git branch -D $nonMasterBranch
        }
        else
        {
            git branch -d $nonMasterBranch
        }
    }
}

function Get-GitNonMasterBranches
{
    $branchList = Get-GitBranches
    $nonMasterBranchList = $branchList | Where-Object {$_ -notlike "*master"}

    return $nonMasterBranchList
}

<#
.SYNOPSIS
Returns a list of branches in a Git repo.

.DESCRIPTION
Returns a list of branches in a Git repository.
#>
function Get-GitBranches
{
    $branchList = git branch | ForEach-Object {$_.Trim('*',' ')}

    return $branchList
}

<#
.SYNOPSIS
Creates a new commit.

.DESCRIPTION
Creates a new commit. Internally, the following command is run:

    git commit -m <your message>

.PARAMETER Message
Message for the commit.

.EXAMPLE
New-GitCommit 'Ths is my commit message'
#>
function New-GitCommit
{
	[CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=1)][string]$Message)

    git commit -m $Message
}

function Remove-GitRemoteBranch
{
    param(
        [Parameter(Mandatory=$true,Position=1)][string[]]$Branch)

        git push --delete origin $Branch
}

<#
.SYNOPSIS
Displays the Git repository log.

.DESCRIPTION
Displays the Git repository log.

Internally, the following command is run:

    git log --graph --decorate --oneline
#>
function Show-GitLog
{
    git log --graph --decorate --oneline
}

function Start-GitOptimization
{
    param(
        [Parameter(Mandatory=$true)][string[]]$Path)

    for ($i = 0; $i -lt $Path.Count; $i++)
    {
        $gitFolder = $Path[$i]

        $activity = 'Optimize-GitRepositories'
        $percentComplete = ($i/$Path.Count*100)
        Write-Progress -Activity $activity -Status $gitFolder -PercentComplete $percentComplete

        Start-GitValidation -Path $gitfolder
        Start-GitGarbageCollection -Path $gitfolder
    }
}

<#
.SYNOPSIS
Validates a Git repo.

.DESCRIPTION
Validates a single Git repository specified by a path.

Internally, the following command is run:

    git fsck

.PARAMETER Path
Path to a Git repository.

.EXAMPLE
Start-GitGarbageCollection P:\Repo
#>
function Start-GitValidation
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    git -C $Path fsck
}

<#
.SYNOPSIS
Starts an aggressive garbage collection of a Git repo.

.DESCRIPTION
Starts an aggressive garbage collection of a single Git repository specified by a path.

Internally, the following command is run:

    git gc --aggressive

.PARAMETER Path
Path to a Git repository.

.EXAMPLE
Start-GitGarbageCollection P:\Repo
#>
function Start-GitGarbageCollection
{
    param(
        [Parameter(Position=1)][string]$Path = '.\')

    git -C $Path gc --aggressive
}