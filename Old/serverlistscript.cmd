@echo off


for /f "tokens=1,2,3,4,5,6 delims=\ " %%i in (F:\Data\Scripts\RIMonthly\serverslist.txt) do call :SetServerVars %%i %%j %%k %%l %%m %%n %%o

Goto :EOF
:SetServerVars
set drive=%1
set backdir=%2
set var3=%3
set var4=%4
set Client=%5
set ServerName=%6

set clientdir=%drive%\%backdir%\%var3%\%Var4%\%client%\%servername%\Data

set monthlydir=%drive%\%backdir%\BackupDrive\Baselines\%client%\%servername%\Data
If not exist %monthlydir% mkdir %monthlydir%

:EOF