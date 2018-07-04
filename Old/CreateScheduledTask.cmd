@echo off
rem \\
rem This script creates a Beyond Compare scheduled task on a set of defined remote servers
rem Pass in the list of servers. <FQDN servername> <client domain>; admin username; admin password
rem //

set Serverlist=%1
set username=%2
set password=%3

net use x: \\ri-fs-002.ri.ads\deploy /u:ri\%username% %password%

Echo Creating BSCC scedule task on targeted servers ...

set RunPath=%~dp0
for /F "tokens=1,2*" %%i in (%ServerList%) do Call :CreateScheduleTask %%i %%j

net use x: /d

goto :EOF

:CreateScheduleTask

set target_server=%1
set clientdomain=%2
set BCSSFileDir=Data\Backups\BCSS
set BCScriptSource=f:\data\scripts\beyondcompare
set BCScriptDir=Data\Scripts\BeyondCompare
set BCExecSource="X:\Images\Util\Beyond Compare\Beyond Compare 3"
set BCExecDir=BeyondCompare

echo %target_server%
echo %clientdomain%

rem Copy file and scripts to target server
rem Connect to target server's drive

net use m: \\%target_server%\d$ /u:%clientdomain%\%username% %password%

rem Check/create the directory where the BCSS file will be saved.
If not exist m:\%BCSSFileDir% mkdir m:\%BCSSFileDir%

rem Check/create the directory where the scripts and copy the files
If not exist m:\%BCScriptDir% mkdir m:\%BCScriptDir%
robocopy %BCScriptSource% m:\%BCScriptDir% /e /ndl /np /tee /r:0 /w:0 /log:m:\%BCScriptDir%\copy.log

rem Check/create the directory where the Beyond Compare executables will reside and copy
If not exist m:\%BCExecDir% mkdir m:\%BCExecDir%
robocopy %BCExecSource% m:\%BCExecDir% /e /ndl /np /tee /r:0 /w:0 /log:m:\\%BCExecDir%\copy.log

net use m: /d

rem Remove the old Beyond Compare task
schtasks /delete /s %target_server% /u %username% /p %password% /tn RunBCCSnapshot /f

rem Create the new Beyond Compare task
schtasks /create /s %target_server% /u %username% /p %password% /ru System /sc Monthly /m jun,dec /tn "CreateBCSS" /tr "d:\Data\Scripts\BeyondCompare\RunBCSS.Cmd" /st 19:00 /rl Highest /f





