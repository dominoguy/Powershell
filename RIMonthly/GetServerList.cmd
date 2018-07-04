@echo off
rem This script will get the full path of the client servers
rem the list is used in conjunction with the monthly backups

REM code change - set script to run on selected drives

rem Enter the drive to be scanned - code change, pass drive letters into script to run all releative client drive letters

rem @echo off 
rem set list=1 2 3 4 
rem (for %%a in (%list%) do ( 
rem   echo %%a 
rem ))
set backupdrive=f:

set backupdrive(0)=e:
set backupdrive(1)=f:
(for %%a in (%backupdrive%) do (echo %%a ))


:GetServerList
set RunPath=%~dp0
set backupdir=Backups
set backpath=%backupdrive%\%backupdir%


set serverlist=%runpath%\serversList.txt


rem change to backup dir
cd /D %backpath%


rem get the client folder directories
 setlocal enabledelayedexpansion 
   
    set "i=0"
    for /f "tokens=*" %%D in ('dir /a:d /b') do (
      set arr[!i!]=%%~fD & set /a "i+=1"
    )

rem get the server names with full path and write to text file
 set "len=!i!"    
 set "i=0"
    :loop
    echo !arr[%i%]!
     cd /d !arr[%i%]!
     for /f "delims=" %%D in ('dir /a:d /b') do echo %%~fD >>%serverlist%
    set /a "i+=1"
    if %i% neq %len% goto:loop
 

 endlocal




cd /d %runpath%

