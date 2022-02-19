@echo off

cd %~dp0

set SUBTITLEPATH=base\localization\jp-jp\subtitles
set SOURCE=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Raw_Subtitles\%SUBTITLEPATH%
SET MODFILES=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Mod
set TARGET=%MODFILES%\%SUBTITLEPATH%
set ARCHIVEFOLDER=..\src\wolvenkit\Cyberpunk 2077 Furigana\packed\archive\pc\mod

echo Removing previous files...
rmdir /s/q "%TARGET%"
mkdir "%TARGET%"

echo Copying files...
xcopy /s /q "%SOURCE%" "%TARGET%"

echo Encode unicode characters...
python escapeunicode.py "%TARGET%"

echo Converting files...
call WolvenKit.Console\WolvenKit.CLI.exe cr2w -d -p "%TARGET%"
color 07

echo Deleting copied source files...
del /s /q "%TARGET%\*.json.json" > __killme__
del /q __killme__

echo Packaging files...
call WolvenKit.Console\WolvenKit.CLI.exe pack -p "%MODFILES%" -o "%ARCHIVEFOLDER%"
color 07

move /y "%ARCHIVEFOLDER%\Mod.archive" "%ARCHIVEFOLDER%\cyberpunk2077-furigana.archive"
