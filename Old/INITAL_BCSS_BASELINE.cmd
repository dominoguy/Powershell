REM INITIAL BASELINE BCSS


set bcApp="C:\Beyond Compare\Beyond Compare 3\BCompare.exe"
set RunPath=%~dp0

set bcscptsnap=%RunPath%\BCSnap.txt

set serverslist=F:\Data\Scripts\RIMonthly\serverslist.txt

for /f "tokens=1,2,3,4,5,6 delims=\ " %%i in (%serverslist%) do call :INITIALBCSS %%i %%j %%k %%l %%m %%n %%o

GOTO :EOF

:INITIALBCSS
rem set client information
set drive=%1
set backdir=%2
set var3=%3
set var4=%4
set Client=%5
set ServerName=%6

rem Setting current and previous months based on current date
set nMonth=
set nYear=
set nPrevMonth=
set nPrevYear=
set cDate=%date%

for /f "tokens=1,2" %%a in ("%cDate%") do for /f "tokens=1,2,3 delims=/" %%i in ("%%b") do set nMonth=%%i&set nYear=%%k

set /a nPrevMonth=%nMonth%-1
set /a nPrevYear=%nYear%
if %nPrevMonth% == 0 set nPrevMonth=12&set /a nPrevYear=%nYear%-1

set nPrevMonth=0%nPrevMonth%
set nPrevMonth=%nPrevMonth:~-2%
 
set clientdir=%drive%\%backdir%\%var3%\%Var4%\%client%\%servername%

set monthlydir=%drive%\%backdir%\BackupDrive\Baselines\%client%\%servername%
If not exist %bcssFileDir% mkdir %bcssFileDir%

set bcssnewFile=%nMonth%_%nYear%
set bcssFileDir="%drive%\%backdir%\Server\Baselines\%client%\%servername%"

rem Run BC Snapshot of Current Client data
	echo Creating new BCSS snapshot %bcssnewFile% for %Servername% : %Time% >> %LogName%
	%bcApp% @%bcscptsnap% %clientdir% %bcssnewFile% %bcssFileDir%


:EOF















