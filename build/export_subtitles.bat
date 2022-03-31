@echo off

cd %~dp0

set BUILDFOLDER=%CD%
set CP2077FOLDER=C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077
set SUBTITLEPATH=base\localization\jp-jp\subtitles
SET WOLVENKITFILES=%BUILDFOLDER%\..\src\wolvenkit\Cyberpunk 2077 Furigana\files
SET MODFILES=%WOLVENKITFILES%\Mod_Exported
SET RAWFILES=%WOLVENKITFILES%\Raw
set SOURCE=%MODFILES%\%SUBTITLEPATH%
set TARGETRAW=%RAWFILES%\%SUBTITLEPATH%
set ARCHIVEFOLDER=%CP2077FOLDER%\archive\pc\content

rmdir /s/q "%TARGETRAW%"
mkdir "%TARGETRAW%"

rem goto noexport
echo Removing previous files...
rmdir /s/q "%SOURCE%"
mkdir "%SOURCE%"

echo Exporting subtitles...
cd "%ARCHIVEFOLDER%"

for /r %%i in (*.archive) do (
	call "%BUILDFOLDER%\WolvenKit.Console\WolvenKit.CLI.exe" unbundle -p "%%i" -o "%MODFILES%" -w "%SUBTITLEPATH%\*"
)

color 07
cd "%BUILDFOLDER%"
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
