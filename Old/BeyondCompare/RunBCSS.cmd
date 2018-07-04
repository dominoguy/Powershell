@echo off
REM  *  This Script runs Beyond Compare on the client server's data directory *
REM  *                                                                              *
REM  ********************************************************************************
	set DrivePath=d:
	set DataDir=data
	set DataPath=%DrivePath%\%DataDir%

Rem The path of the Beyond Compare executable
	set bcpath="%DrivePath%:\BeyondCompare\BCompare.exe"

Rem The path of the Beyond Compare scripts
	set bcscpt="%DataPath%\Scripts\BeyondCompare"

Rem Set year, set the path where the BCSS file is saved, set the client name
Rem -------------------------------------------------------------------------------------------------------------------

 	set cur_year=%date:~10%
	set cur_month=%date:~4,2%
	set cur_date=%cur_year%-%cur_month%
	set clientname=%userdomain%
	set BCSavePath="%DataPath%\Backups\BCSS"

Rem -------------------------------------------------------------------------------------------------------------------



%bcpath% @%bcscpt%\BCSSOptions.txt "%BCSavePath%" "%DataPath%" "%cur_date%_%ClientName%"

:End
Pause
