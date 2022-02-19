@echo off

cd %~dp0

set CP2077FOLDER=C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077
set SUBTITLEPATH=base\localization\jp-jp\subtitles
SET MODFILES=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Mod
SET RAWFILES=..\src\wolvenkit\Cyberpunk 2077 Furigana\files\Raw
set TARGET=%MODFILES%\%SUBTITLEPATH%
set TARGETRAW=%RAWFILES%\%SUBTITLEPATH%
set ARCHIVE=%CP2077FOLDER%\archive\pc\content\lang_ja_text.archive

echo Removing previous files...
rmdir /s/q "%TARGET%"
mkdir "%TARGET%"

rmdir /s/q "%TARGETRAW%"
mkdir "%TARGETRAW%"

echo Exporting subtitles...
call WolvenKit.Console\WolvenKit.CLI.exe unbundle -p "%ARCHIVE%" -o "%MODFILES%" -w "%SUBTITLEPATH%\*"
color 07

echo Copying files...
xcopy /s /q "%TARGET%" "%TARGETRAW%"

echo Decoding subtitles...
call WolvenKit.Console\WolvenKit.CLI.exe cr2w -p "%TARGETRAW%" -s
color 07

echo Deleting copied exported files...
attrib +R "%TARGETRAW%\*.json.json" /s

del /s /q /a:-R "%TARGETRAW%\*.json" > __killme__
del /q __killme__

attrib -R "%TARGETRAW%\*.json.json" /s

echo Decode unicode characters...
python unescapeunicode.py "%TARGETRAW%"
