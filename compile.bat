@echo off

rem Get the absolute path
set CP2077=%~dp0..\..\..
pushd %CP2077%
set CP2077=%CD%
popd

rem Run the compiler
echo Cyberpunk 2077 Path: %CP2077%

"%CP2077%\engine\tools\scc.exe" -compile "%CP2077%\r6\scripts" "%CP2077%\r6\cache\final.redscripts" -threads 4 -no-testonly -no-breakpoint -profile=off

rem type "%CP2077%\r6\cache\redscript.log"

rem pause
