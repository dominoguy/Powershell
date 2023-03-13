#TimeOutFunction
#This function will timeout on a set of code allow to break a loop



Function TimeOut
{
    [CmdletBinding()]
    Param(
        [String]$ServiceToCheck,
        [String]$TimeOut,
        [String]$SleepPeriod
    )
    #Start Timer
    $timer = [Diagnostics.Stopwatch]::StartNew()
    Write-Host "Waiting for the $ServiceToCheck service check"
    $Condition = $False
    While (($Condition -eq $False) -and ($timer.Elapsed.TotalSeconds -lt $Timeout))
    {
        #Check timer
        $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
        IF ((Get-Service $ServiceToCheck).Status -NE "Running")
        {
            Start-Sleep -Seconds $SleepPeriod
            Write-Host "$ServiceToCheck still not started after $totalSecs seconds."
        }
        elseIf ((Get-Service $ServiceToCheck).Status -eq "Running") {
            $Condition = $True
        }
    }
    #Stop the timer - The action either completed or timed out. 
    $timer.Stop()

    If ($timer.Elapsed.TotalSeconds -gt $Timeout) 
    {
        Return $False,$totalSecs
    } 
    else 
    {
        Return $True,$totalSecs
    }

}
  
$TimeOut = 30
$ServiceToCheck = "WISVC"
#$ServiceToCheck = "VMMS"
$SleepPeriod = 5

$ServiceStarted = Timeout $ServiceToCheck $TimeOut $SleepPeriod 

IF($ServiceStarted[0] -eq $True){
    Write-host "$ServiceToCheck is started after"$ServiceStarted[1]"seconds"
    #Continue with your code
}
ElseIF($ServiceStarted[0] -eq $False){
    Write-Host "$ServiceToCheck did not start before the timeout period of $Timeout seconds"
}

