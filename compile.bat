@echo off

..\..\..\engine\tools\scc.exe compile --src . --bundle bundle --output out --verbose

type ..\..\cache\redscript.log

pause
