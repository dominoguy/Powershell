#PSTBackup

#Logging
$logPath = 'F:\Data\Scripts\LOGS'
$logPathExists = Test-Path -path $logPath
If ( $logPathExists -eq $False) {
    New-Item -ItemType Directory -Force -Path $LogPath
} 
$Logfile = $logPath + '\PSTCopy.Log'
Function LogWrite
{
    Param ([string]$logstring)
    Add-Content $Logfile -value $logstring
}
Function BackupPST ($Filename, $SourceDir, $DestDir, $FilePath, $RobocopyLog)
{$oFile = New-Object System.IO.FileInfo $FilePath
    
    Try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        If ($oStream) {

            $oStream.Close()
        }
        $False
    } Catch {
        $Time=Get-Date
        $ErrorMessage = $_.Exception.Message
        LogWrite "$Time $FilePath $ErrorMessage"
        return $True
    } Finally{
        $Time=Get-Date
        If (-Not $ErrorMessage) {
            LogWrite "$Time $FilePath is ready for backup"
            Robocopy.exe $SourceDir $DestDir $Filename /e /ndl /np /tee /w:0 /r:0 /log:$RobocopyLog
            LogWrite "$Time $FileName has been backed up"
        }
    }
}

$List = Get-Content 'F:\Data\Scripts\pstlist.txt'

Foreach ($Row in $List)
{
   # write-host $Row
   $Row = $Row.Split(",")

#get a list of pst files (recursive into sub dirs) using source a root dir
$StartDir = $row[0]
#$FileList = New-Object System.Collections.ArrayList

Get-ChildItem $StartDir -Recurse | Where {$_.extension -eq ".pst"} | % {
        Write-host "      This is the fullpath "$_.FullName
        Write-host "      This is the filename" $_.Name
        Write-host '      This is the SourcePath ' $_.Directory
        $FileName = $_.Name
        $SourceDir = $_.Directory
        $FilePath = $_.FullName
        $DestDir = $row[1]
        #$UserDir = $row[1]
        #$DestDir = $SourceDir | Where-Object {$_ -notin $UserDir}
        #Write-host " This is the destination dir  " $DestDir
        $RobocopyLog = $DestDir +'\' + $Filename + '.log'
        #BackupPST $Filename $SourceDir $DestDir $FilePath $RobocopyLog
       

    }
}
