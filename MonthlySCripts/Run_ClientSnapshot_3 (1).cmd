REM  *   BeyondCompare.exe Baseline_Dir, Backup_Dir, Prev_Mo_SS_File, Current_Month *
REM  *                                                                              *
REM  ********************************************************************************

set bc2path="d:\Deploy\Images\Util\Beyond Compare 3\BCompare.exe"
set bc2scpt=d:\Backups\ENBackup\BeyondCompare

Rem
Rem Change the following values to set the current month and the appropriate drive letter for the incremental baselines
Rem -------------------------------------------------------------------------------------------------------------------

 set cur_mth=07-01-2012
 set BCSavePath=d:\Data\Backup\BCSS
 set clientName=Nail

Rem -------------------------------------------------------------------------------------------------------------------

set DataPath=d:


echo %bc2path% 
echo %bc2scpt%

Goto Next


REM var1 = DestClientDir, var2 = SourceClientDir, var3=lastmonth's BCSS file, var4 = current month

:Next

set cur_dir=Data


%bc2path% @%bc2scpt%\Run_ClientSnapshot_3.txt "%BCSAVEPath%" "%DataPath%\%cur_dir%" "%cur_mth%_%ClientName%"
rem %bc2path% @%bc2scpt%\Run_ClientSnapshot_3.txt d:\data\backup\BCSS d:\Data %cur_mth%_%ClientName%"


REM Del %BcssPath%\%cur_dir%\%BcssFile%_old.bcss /Q
REM Rename %BcssPath%\%cur_dir%\%BcssFile%.bcss %BcssFile%_old.bcss
REM Copy %BasePath%\%cur_dir%\%cur_mth%.* %BcssPath%\%cur_dir%\*.* /Y
REM Copy %BasePath%\%cur_dir%\%cur_mth%.bcss %BcssPath%\%cur_dir%\Baseline.Bcss /Y



:End
Pause