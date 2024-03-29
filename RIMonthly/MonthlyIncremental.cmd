@echo off
REM ***** Monthly Incremental Backups *****

REM This procedure is to take a incremental backup once per month using Beyond Compare.
REM A BC snapshot (1) is taken of the existing data, one month later another BC snapshot is taken (2).
REM At this time the snapshots are compared and the differences are copied to the monthly backup.
REM A yearly Baseline (data and BCSS) is taken to start the year anew.

set RunPath=%~dp0

rem code logging feature for this procedure
set curdate=%date%
set curdate=%curdate:/=-%
set curdate=%curdate:~4%
set LogName=%RunPath%\LOGS\Monthly_%curDate%.log

If not exist %RunPath%\LOGS mkdir %RunPath%\LOGS

echo Starting Monthly Incremental Backup for %curDate% >> %LogName%

set bcApp="C:\Program Files\Beyond Compare 4\BCompare.exe"

set bcscptsnap=%RunPath%\BCSnap.txt
set bcscptcopy=%RunPath%\CompareCopy.txt
set bcscptsize=%RunPath%\Comparesize.txt

set serverslist=%RunPath%\serverslist.txt

set monthlydrive=E:

for /f "tokens=1,2,3,4 delims=\ " %%i in (%serverslist%) do call :MonthlyBackup %%i %%j %%k %%l %%m

GOTO :EOF

:MonthlyBackup

rem set client information
set drive=%1
set backdir=%2
set Client=%3
set ServerName=%4
set baselinesdir=Baselines


rem Setting current and previous months based on current date
set nMonth=
set nYear=
set nPrevMonth=
set nPrevYear=
set cDate=%date%

echo Starting Monthly Incremental Backup for %ServerName% : %Time%  >> %LogName%


for /f "tokens=1,2" %%a in ("%cDate%") do for /f "tokens=1,2,3 delims=/" %%i in ("%%b") do set nMonth=%%i&set nYear=%%k
If %nMonth% LSS 10 set nMonth=%nMonth:0=%
set /a nPrevMonth=%nMonth%-1
If %nMonth% LSS 10 set nMonth=0%nMonth%
set /a nPrevYear=%nYear%
if %nPrevMonth% == 0 set nPrevMonth=12&set /a nPrevYear=%nYear%-1
If %nPrevMonth% LSS 10 set nPrevMonth=0%nPrevMonth%
 
set clientdir=%drive%\%backdir%\%client%\%servername%

set monthlydir=%monthlydrive%\Baselines_%nPrevMonth%_%nPrevYear%\%client%\%servername%
If not exist %monthlydir% mkdir %monthlydir%


set bcssnewFile=%nMonth%_%nYear%
set bcssprevFile=%nPrevMonth%_%nPrevYear%
set bcssFileDir="%drive%\%Baselinesdir%\%client%\%servername%"

set bcssFileworking=%bcssFiledir%\%bcssprevFile%.bcss

rem directory checks
if not exist %monthlydir% mkdir %monthlydir%
If not exist %bcssFileDir% mkdir %bcssFileDir%


rem code drive space check
for /f "usebackq delims== tokens=2" %%x in (`wmic logicaldisk where "DeviceID='%monthlydrive%'" get FreeSpace /format:value`) do set FreeSpace=%%x
echo There is %FreeSpace% bytes remaining on %monthlydrive% drive>> %LogName%

rem Run BC Snapshot of Current Client data
	echo Creating new BCSS snapshot %bcssnewFile% for %Servername% : %Time% >> %LogName%
	%bcApp% @%bcscptsnap% %clientdir% %bcssnewFile% %bcssFileDir%
	echo ...Finished new BCSS snapshot %bcssnewFile% for %Servername% : %Time% >> %LogName%

If not exist %bcssFileworking% echo Error: There is no %bcssFileworking% >> %LogName% & Goto :EOF

rem Run the monthly incremental

	echo Running the monthly incremental for %bcssnewFile% on %Servername% : %Time% >> %LogName%
rem	%bcApp% @%bcscptsize% %clientdir% %bcssFileWorking% %bcssFileDir% %bcssprevFile%
	%bcApp% @%bcscptcopy% %clientdir% %bcssFileWorking% %MonthlyDir% %bcssprevFile%

	copy %bcssFileWorking% %MonthlyDir%\%bcssprevFile%.bcss
	echo ...Finished monthly incremental for %Servername% : %Time% >> %LogName%

:EOF



