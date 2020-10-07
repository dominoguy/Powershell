#RSYNC-Test

$env:RSYNC_PASSWORD='2012B@ckup!'

$RSYNCBaseVar = '-vvrt --modify-window=2 --out-format="TransferInfo: %20t %15l %n" --log-file-format="%i %15l %20M %-10o %n" --stats --timeout=300 --contimeout=120'
$RSYNCExcludeFile = 'F/Data/Scripts/Powershell/RILocal/ExcludeFilter.txt'
$RSYNCExcludeVar = ' --exclude-from="/cygdrive/' + $RSYNCExcludeFile + '"'
$RSYNCLogFile = 'F/Data/Scripts/Powershell/RILocal/Incremental.txt'
$RSYNCLogVar = ' --log-file="/cygdrive/' + $RSYNCLogFile + '"'
$Source = ' "/cygdrive/F/Data/"'
$DestPath = 'Backups/RI/RI-dt-008/Data/'
$Dest = ' "rsync-bkup@10.0.7.79::' + $DestPath +'"'
$RSYNCVars = $RSYNCBaseVar + $RSYNCExcludeVar + $RSYNCLogVar + $Source + $Dest
Write-host $Dest
write-host $RSYNCVars

Start-Process -FilePath "C:\Program files\icw\bin\rsync.exe" -Argumentlist $RSYNCVars


