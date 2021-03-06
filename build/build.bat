@echo off

cd %~dp0

rem Get the absolute path
set CP2077=C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077

rem Run the compiler
echo Cyberpunk 2077 Path: %CP2077%

echo Killing Cyberpunk2077.exe...
taskkill /F /IM Cyberpunk2077.exe

echo Copying files...
mkdir ..\dist\r6\scripts\cyberpunk2077-furigana
copy /y ..\src\redscript\* ..\dist\r6\scripts\cyberpunk2077-furigana\*

mkdir ..\dist\red4ext\plugins
copy /y ..\src\red4ext\x64\Debug\*.dll ..\dist\red4ext\plugins\*

mkdir ..\dist\bin\x64\plugins\cyber_engine_tweaks\mods\cyberpunk2077-furigana
copy /y ..\src\cyber_engine_tweaks\* ..\dist\bin\x64\plugins\cyber_engine_tweaks\mods\cyberpunk2077-furigana\*

rem mkdir ..\dist\bin\x64\plugins\cyber_engine_tweaks\mods\nativeSettings
rem copy /y ..\src\CP77_nativeSettings\nativeSettings\* ..\dist\bin\x64\plugins\cyber_engine_tweaks\mods\nativeSettings\*

xcopy /y /e "..\src\wolvenkit\Cyberpunk 2077 Furigana\packed\*" ..\dist\*

echo Copy to CP2077 folder...
xcopy /y /e ..\dist\* "%CP2077%"

echo Running redscript compiler...
redscript-cli.exe compile -s "%CP2077%\r6\scripts" -b "%CP2077%\r6\cache\final.redscripts.bk" -o "%CP2077%\r6\cache\final_patched.redscripts"

rem type "%CP2077%\r6\cache\redscript.log"

rem pause
