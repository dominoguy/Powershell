REM  *   BeyondCompare.exe Baseline_Dir, Backup_Dir, Prev_Mo_SS_File, Current_Month *
REM  *                                                                              *
REM  ********************************************************************************

set bc2path="c:\Deploy\Images\Util\Beyond Compare 3\BCompare.exe"
set bc2scpt=e:\Backups\ENBackup\BeyondCompare

Rem
Rem Change the following values to set the current month and the appropriate drive letter for the incremental baselines
Rem -------------------------------------------------------------------------------------------------------------------

set cur_mth=10-01-2015
set cut_date=06/01/2012
set BasePath=H:\Baselines

Rem -------------------------------------------------------------------------------------------------------------------


set BackPath=e:\Backups
set BcssPath=e:\Baselines
set BcssFile=Baseline

echo %bc2path% 
echo %bc2scpt%

Goto Next


REM var1 = Destination directory of Client
REM var2 = Source directory of Client
REM var3 = BCSS file, this is the 6 month snapshot of the file
REM var4 = current month
REM var5 = Cut date

:Next


set cur_dir=EPA\EPA-SRV-001\data

MD %BasePath%\%cur_dir%
attrib /S /D -A "%BackPath%\%cur_dir%\*.*"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-1.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-2.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
robocopy %BackPath%\%cur_dir% %BasePath%\%cur_dir% /A /s /zb /M /r:3 /w:5 /np /ndl /log:%BasePath%\%cur_dir%\%cur_mth%-CopyLog.log

pause

set cur_dir=ODC\ODC-SRV-001\data

MD %BasePath%\%cur_dir%
attrib /S /D -A "%BackPath%\%cur_dir%\*.*"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-1.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-2.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
robocopy %BackPath%\%cur_dir% %BasePath%\%cur_dir% /A /s /zb /M /r:3 /w:5 /np /ndl /log:%BasePath%\%cur_dir%\%cur_mth%-CopyLog.log

Pause

set cur_dir=ODC\ODC-SQL-001\data

MD %BasePath%\%cur_dir%
attrib /S /D -A "%BackPath%\%cur_dir%\*.*"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-1.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
%bc2path% @%bc2scpt%\DO_Base_Incremental_3-2.txt "%BasePath%\%cur_dir%" "%BackPath%\%cur_dir%" "%BcssPath%\%cur_dir%\%BcssFile%.bcss" "%cur_mth%" "%cut_date%"
robocopy %BackPath%\%cur_dir% %BasePath%\%cur_dir% /A /s /zb /M /r:3 /w:5 /np /ndl /log:%BasePath%\%cur_dir%\%cur_mth%-CopyLog.log





Pause