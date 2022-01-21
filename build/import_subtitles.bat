@echo off

cd %~dp0

set SUBTITLEPATH=base\localization\jp-jp\subtitles
set SOURCE=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Raw_Subtitles\%SUBTITLEPATH%
set TARGET=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Mod\%SUBTITLEPATH%

echo Removing previous files...
rmdir /s/q "%TARGET%"
mkdir "%TARGET%"

echo Copying files...
xcopy /s /q "%SOURCE%" "%TARGET%"

echo Converting files...
call WolvenKit.Console\WolvenKit.CLI.exe cr2w -d -p "%TARGET%"
color 07

echo Deleting copied source files...
del /s /q "%TARGET%\*.json.json" > __killme__
del /q __killme__
