@echo off

rem Get the absolute path
set CP2077=C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077

rem Run the compiler
echo Cyberpunk 2077 Path: %CP2077%

"%~dp0\redscript-cli.exe" compile -s "%CP2077%\r6\scripts" -b "%CP2077%\r6\cache\final.redscripts" -o "%CP2077%\r6\cache\final_patched.redscripts"

rem type "%CP2077%\r6\cache\redscript.log"

rem pause
