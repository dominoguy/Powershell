@echo off
rem Setting current and previous months based on current date
set nMonth=
set nYear=
set nPrevMonth=
set nPrevYear=
set cDate=%date%

for /f "tokens=1,2" %%a in ("%cDate%") do for /f "tokens=1,2,3 delims=/" %%i in ("%%b") do set nMonth=%%i&set nYear=%%k

echo 1 nMonth is %nMonth%

If %nMonth% LSS 10 set nMonth=%nMonth:0=%
set /a nPrevMonth=%nMonth%-1

echo 2 nMonth is %nMonth%
echo 3 nPrevMonth is %nPrevMonth%

If %nMonth% LSS 10 set nMonth=0%nMonth%
set /a nPrevYear=%nYear%
if %nPrevMonth% == 0 set nPrevMonth=12&set /a nPrevYear=%nYear%-1
If %nPrevMonth% LSS 10 set nPrevMonth=0%nPrevMonth%

echo The current full date is %date%
echo The current month is %nMonth%
echo The curent year is %nYear%
echo The previous month %nPrevMonth%
echo The previous year pertaining to the month is %nPrevYear%

