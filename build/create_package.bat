@echo off

set ARCHIVE=..\packages\cyberpunk-furigana.zip

del /q %ARCHIVE%

mkdir ..\packages

rem Use release DLL
copy /y ..\src\red4ext\x64\Release\*.dll ..\dist\red4ext\plugins\*

"C:\Program Files\WinRAR\Rar.exe" a -r -ep1 -m5 -t -x..\dist\bin\x64\plugins\cyber_engine_tweaks\mods\nativeSettings %ARCHIVE% ..\dist\*
