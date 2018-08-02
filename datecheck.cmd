@echo off

rem Setting current and previous months based on current date

set nMonth=
set nYear=
set nPrevMonth=
set nPrevYear=
set cDate=%date%

for /f "tokens=1,2" %%a in ("%cDate%") do for /f "tokens=1,2,3 delims=/" %%i in ("%%b") do set nMonth=%%i&set nYear=%%k

set nMonth=%nMonth:0=%

set /a nPrevMonth=%nMonth%-1

If %nMonth% LSS 10 set nMonth=0%nMonth%

set /a nPrevYear=%nYear%
if %nPrevMonth% == 0 set nPrevMonth=12&set /a nPrevYear=%nYear%-1

If %nPrevMonth% LSS 10 set nPrevMonth=0%nPrevMonth%

Echo This is PrevMonth %nPrevMonth%