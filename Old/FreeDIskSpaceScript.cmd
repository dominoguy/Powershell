@echo off

rem wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:value

setlocal
Set drive=c:
for /f "usebackq delims== tokens=2" %%x in (`wmic logicaldisk where "DeviceID='%drive%'" get FreeSpace /format:value`) do set FreeSpace=%%x
echo %FreeSpace%
set /A FreeSpace=2048/1024
echo %FreeSpace%