#PSTBackup Version 1.0

#Logging
$logFile = 'F:\Data\Scripts\Powershell\LOGS\PSTCopy.log'
$logPFileExists = Test-Path -path $logFile
If ( $logFileExists -eq $True) {
    Remove-Item $LogFile
    New-Item -ItemType File -Force -Path $LogFile
} 
Else {
    New-Item -ItemType File -Force -Path $LogFile}
Function LogWrite
{
    Param ([string]$logstring)
    $Time=Get-Date
    Add-Content $Logfile -value "$Time $logstring"
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
        $ErrorMessage = $_.Exception.Message
        LogWrite "$FilePath $ErrorMessage"
        return $True
    } Finally{
        If (-Not $ErrorMessage) {
            LogWrite "$FilePath is ready for backup"
            Robocopy.exe $SourceDir $DestDir $Filename /e /ndl /np /tee /w:0 /r:0 /log:$RobocopyLog
            LogWrite "$FileName has been backed up"
        }
    }
}

LogWrite "PSTBackup Begins"
$List = Import-Csv 'F:\Data\Scripts\Powershell\pstlist.csv'

Foreach ($Row in $List)
{
#get a list of pst files (recursive into sub dirs) using source a root dir
$StartDir = $row.StartDir
$UserName = $row.UserName
$FolderExists = Test-Path $StartDir
IF ($FolderExists -eq $True) {
    Get-ChildItem $StartDir -Recurse | Where-Object {$_.extension -eq ".pst"} | ForEach-Object {
        $FileName = $_.Name
        $SourceDir = [String]($_.Directory)
        $FilePath = $_.FullName
        $UserDir = $row.UserDir    
        $DiffDir = $SourceDir.replace($StartDir,'')
        $DestDir = $Userdir +'\' + $DiffDir
        $RobocopyLog = $DestDir +'\' + $Filename + '.log'
        BackupPST $Filename $SourceDir $DestDir $FilePath $RobocopyLog    
        } 
    }
    Else {LogWrite "$Time $StartDir is not available"}
}
LogWrite "PSTBackup Ends"