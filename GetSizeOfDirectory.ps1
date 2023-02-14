#Get size of a directory

#If using one tiem replace $dirpath with literal directory path
#"{0:N2} GB" -f ((gci -force $dirPath -recurse | measure length -s).sum/1gb)



$dirPath = "D:\data"
$sizeResult = "{0:N2} GB" -f ((Get-ChildItem -force $dirPath -recurse | Measure-Object length -s).sum/1gb)
"The size of $dirPath is $sizeresult" |Out-File -FilePath "$dirPath\DirectorySize.log"