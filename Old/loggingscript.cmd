@echo off
set curdate=%date%
set curdate=%curdate:/=-%
set curdate=%curdate:~4%
set LogName=F:\Data\Scripts\RIMonthly\BCSSLog_%curDate%.log
rem ::set LogName=f:\backups\ribaseline\BCSSLog.log

echo %curDate% > %LogName%
echo Hello World >> %LogName%
echo More stuff >> %LogName%
echo last stuff >> %LogName%

