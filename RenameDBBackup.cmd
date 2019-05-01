@echo off

Rem
Rem This file removes any "_xxxxx" from a file and just uses the first part of the filename before the _ and its extension.
Rem
Rem ie.  If a filename is "DataBackup_20140101.bak" it will rename the file to "DataBackup.bak" stripping off the "_20140101" from the file name
Rem 
Rem     NOTE: Because this is for PTAdmin...I am copying the original backup file to the stripped off name and then moving it to the CopyToDir folder
Rem
Rem Neil Shmyr (Nov 6, 2014)
Rem

setlocal

if %1.==. goto :EOF

set RenameFileDir=%1
set CopyToDir=D:\ToBeDeleted

for /f %%a in ('dir %RenameFileDir%\ptas_* /b') do for /f "delims=_ tokens=1,2*" %%b in ("%%a") do for /f "delims=. tokens=1,2*" %%i in ("%%c") do call :FileRename %RenameFileDir%\%%a %%b.%%j

forfiles /p %CopyToDir% /s /d -30 /c "cmd /c del @file : date >= 30 days >NUL" 

endlocal

goto End

:FileRename
echo Copying file %1 to %RenameFileDir%\%2
Copy %1 %RenameFileDir%\%2 /y

echo Moving file %1 to %CopyToDir%
move %1 %CopyToDir%

goto :EOF

:End