#RI-Diagnostics

function New-StopWatch
{
    $stopWatch = [system.diagnostics.stopwatch]::StartNew()

    return $stopWatch
}