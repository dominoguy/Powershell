@echo off
rem setlocal enabledelayedexpansion 

set backupdrive[0]=e:
set backupdrive[1]=f:
rem set backupdrive[2]=g:

for /F "tokens=2 delims==" %%a in ('set backupdrive[') do (echo %%a)

rem for /l %%n in (0,1,2) do (echo !backupdrive[%%n]!)