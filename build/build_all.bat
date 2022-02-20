@echo off

cd %~dp0

rem Does not compile C++ binaries

call build.bat
call export_subtitles.bat
python process_subtitles.py
call import_subtitles.bat
