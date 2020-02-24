REM Copy files into Day of the Week

Rem Date variables
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    	 set dow=%%i
    	 set month=%%j
  	 set day=%%k
   	 set year=%%l
	)
set cur_date=%year%-%month%-%day%

Rem Set Day of the Week
set DayOfWeek=%dow%
set BackupPath=f:\Data\Backup\SQL

Set DOW_Dir=%BackupPath%\%DayOfWeek%
If not exist %DOW_Dir% mkdir %DOW_Dir%

Set DirToCopy=F:\Data\Scripts\Powershell\RIMonthly

xcopy %dirToCopy%\*.* %DOW_Dir% /s /Y