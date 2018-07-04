#FileInUse

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
Function BackupPST ($Filename, $Source, $Dest, $RobocopyLog)
{
    Try
    {
        $Check = Get-Content $Filename -ErrorAction Stop
    }

    Catch
    {
        $Time=Get-Date
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Logwrite "$Time Error $ErrorMessage"
    }

    Finally
    {
        $Time=Get-Date
        If (-Not $ErrorMessage) {
            LogWrite "$Time $FileName is ready for backup"
            Robocopy.exe $Source $Dest /e /ndl /np /tee /w:0 /r:0 /log:$RobocopyLog
            LogWrite "$Time $FileName has been backed up"
        }
    }
}

$Filename = 'F:\TEST1\Users\Betty\Outlook\Test.pst'
$Source = 'F:\TEST1\Users\Betty\Outlook'
$Dest = 'F:\TEST2\Users\Betty\Outlook'
$RobocopyLog = $Dest+'\copy.log'
BackupPST $Filename $Source $Dest $RobocopyLog
