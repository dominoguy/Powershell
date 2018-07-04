@echo off

setlocal

Rem
Rem Create shadow copy of D: drive on 2008 servers using diskshadow command.
Rem

set cRunPath=%~dp0
set cShadowDrive=f:
set cExposeDrive=Z:
set DiskShadowFile=%cRunPath%ShadowFile.txt
set DiskShadowLog=%~dpn0.Log
set cShadowID=

del *.cab

if exist z: echo Shadow Created: %date%-%time% > %cRunPath%ShadowCopy.log

if exist z: echo delete shadows exposed %cExposeDrive% > %DiskShadowFile%
echo set context persistent >> %DiskShadowFile%
echo add volume %cShadowDrive% alias cShadowID >> %DiskShadowFile%
echo create >> %DiskShadowFile%
echo expose %%cShadowID%% %cExposeDrive% >> %DiskShadowFile%

diskshadow /s %DiskShadowFile% /log %DiskShadowLog%
net share z$=z:\
del %DiskShadowFile%

endlocal
