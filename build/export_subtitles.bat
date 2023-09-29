@echo off

cd %~dp0

set BUILDFOLDER=%CD%
call cp2077path.bat
set SUBTITLEPATH=base\localization\jp-jp\subtitles
set SUBTITLEPATH_EP1=ep1\localization\jp-jp\subtitles
SET WOLVENKITFILES=%BUILDFOLDER%\..\src\wolvenkit\Cyberpunk 2077 Furigana\files
SET MODFILES=%WOLVENKITFILES%\Mod_Exported
SET RAWFILES=%WOLVENKITFILES%\Raw
set SOURCE=%MODFILES%
set TARGETRAW=%RAWFILES%
set ARCHIVEFOLDER=%CP2077FOLDER%\archive\pc\content
set ARCHIVEFOLDER_EP1=%CP2077FOLDER%\archive\pc\ep1

rmdir /s/q "%TARGETRAW%"
mkdir "%TARGETRAW%"

rem goto noexport
echo Removing previous files...
rmdir /s/q "%SOURCE%"
mkdir "%SOURCE%"

echo Exporting subtitles (%ARCHIVEFOLDER%)...
cd /d "%ARCHIVEFOLDER%"

call "%BUILDFOLDER%\WolvenKit.Console\WolvenKit.CLI.exe" unbundle -p lang_ja_text.archive -o "%MODFILES%" -w "%SUBTITLEPATH%\*"

echo Exporting subtitles (%ARCHIVEFOLDER_EP1%)...
cd /d "%ARCHIVEFOLDER_EP1%"

call "%BUILDFOLDER%\WolvenKit.Console\WolvenKit.CLI.exe" unbundle -p lang_ja_text.archive -o "%MODFILES%" -w "%SUBTITLEPATH_EP1%\*"

color 07
cd /d "%BUILDFOLDER%"
:noexport

echo Copying files...
xcopy /s /q "%SOURCE%" "%TARGETRAW%"

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
