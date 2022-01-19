@echo off

rem Get the absolute path
set CP2077=C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077

rem Run the compiler
echo Cyberpunk 2077 Path: %CP2077%

echo Copying files...
mkdir ..\dist\r6\scripts\cyberpunk2077-furigana
copy /y ..\src\redscript\* ..\dist\r6\scripts\cyberpunk2077-furigana\*

mkdir ..\dist\bin\x64\plugins
copy /y ..\src\red4ext\x64\Debug\*.dll ..\dist\bin\x64\plugins\*.asi

echo Copy to CP2077 folder...
xcopy /y /e ..\dist\* "%CP2077%"

echo Running redscript compiler...
"%~dp0\redscript-cli.exe" compile -s "%CP2077%\r6\scripts" -b "%CP2077%\r6\cache\final.redscripts" -o "%CP2077%\r6\cache\final_patched.redscripts"

rem type "%CP2077%\r6\cache\redscript.log"

rem pause
