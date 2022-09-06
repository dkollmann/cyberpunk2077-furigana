@echo off

cd %~dp0

rem Get the absolute path
call cp2077path.bat

rem Run the compiler
echo Cyberpunk 2077 Path: %CP2077FOLDER%

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

echo Copy to CP2077FOLDER folder...
xcopy /y /e ..\dist\* "%CP2077FOLDER%"

echo Running redscript compiler...
redscript-cli.exe compile -s "%CP2077FOLDER%\r6\scripts" -b "%CP2077FOLDER%\r6\cache\final.redscripts.bk" -o "%CP2077FOLDER%\r6\cache\final_patched.redscripts"

rem type "%CP2077FOLDER%\r6\cache\redscript.log"

rem pause
