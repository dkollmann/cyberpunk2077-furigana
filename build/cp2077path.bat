@echo off

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\GOG.com\Games\1423049311" /v path ^|findstr /ri "REG_SZ"') do set CP2077FOLDER=%%b

echo "Cyberpunk 2077 Folder:" "%CP2077FOLDER%"
