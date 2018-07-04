#Reading a file
$List = Get-Content 'F:\Data\Scripts\pstlist.txt'

Foreach ($Row in $List)
{$Row = $Row.Split(",")
   write-host 'This is the source '$row[0]
#get a list of pst files (recursive into sub dirs) using source a root dir
$SourceDir = $row[0]
$FileList = New-Object System.Collections.ArrayList
Get-ChildItem $SourceDir -Recurse | Where {$_.extension -eq ".pst"} | % {
    Write-host "      Found "$_.FullName
    Write-host "      This is the filename" $_.Name

}

   write-host 'This is the destination '$row[1]




}