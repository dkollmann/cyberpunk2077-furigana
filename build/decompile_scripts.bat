@echo off

cd %~dp0

set BUILDFOLDER=%CD%
call cp2077path.bat

redscript-cli.exe decompile -i "%CP2077FOLDER%\r6\cache\final.redscripts" -o dump.reds
