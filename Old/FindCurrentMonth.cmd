@echo off

Rem This batch gets the current date and converts it into a 3 letter contraction.

setlocal EnableDelayedExpansion

Rem Putting the months into an array.

set MonthArray[1]=Jan
set MonthArray[2]=Feb
set MonthArray[3]=Mar
set MonthArray[4]=Apr
set MonthArray[5]=May
set MonthArray[6]=Jun
set MonthArray[7]=Jul
set MonthArray[8]=Aug
set MonthArray[9]=Sep
set MonthArray[10]=Oct
set MonthArray[11]=Nov
set MonthArray[12]=Dec

Rem Get the current month as an Integer
set intMonth=%date:~4,2%

echo !MonthArray[%intMonth%]!
set /a strMonth=!MonthArray[%intMonth%]!

exit /b
endlocal

