@echo off
rem :2008
rem	for /f "tokens=1-3 delims=-" %%i in ("%date%") do (
rem    	 set year=%%i
rem   	 set month=%%j
rem 	 set day=%%k
rem	)
rem 	set cur_date=%year%-%month%

rem echo %cur_date%


rem :2003
	for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    	 set dow=%%i
    	 set month=%%j
  	 set day=%%k
   	 set year=%%l
	)
	set cur_date=%year%-%month%-%day%
echo %cur_date%


