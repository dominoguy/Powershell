@echo off
setlocal
rem Setting current and previous months
set nMonth=
set nYear=
set nPrevMonth=
set nPrevYear=
set cdate=%date%
echo %cdate%
rem set cDate=%1 %2
for /f "tokens=1,2" %%a in ("%cDate%") do for /f "tokens=1,2,3 delims=/" %%i in ("%%b") do set nMonth=%%i&set nYear=%%k

echo   DateProvided:[%cDate%]
echo  Current Month:[%nMonth%]
echo  Current  Year:[%nYear%]

set /a nPrevMonth=%nMonth%-1
set /a nPrevYear=%nYear%
if %nPrevMonth% == 0 set nPrevMonth=12&set /a nPrevYear=%nYear%-1

set nPrevMonth=0%nPrevMonth%
set nPrevMonth=%nPrevMonth:~-2%

echo Previous Month:[%nPrevMonth%]
echo Previous  Year:[%nPrevYear%]
echo.

endlocal