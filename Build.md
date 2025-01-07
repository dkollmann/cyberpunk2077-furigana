# cyberpunk2077-furigana Build Guide

These are the steps usually required to update the mod.

## Initial Setup
- Make sure the game is installed. The game path is detected and set in "build\cp2077path.bat"
- Make sure you have Python 3 installed.
- Download WolvenKit.Console-x.x.x.zip from https://github.com/WolvenKit/WolvenKit/releases and extract it in "build\WolvenKit.Console".
- Open "build\process_subtitles.py", for example in PyCharm and make sure all dependencies are installed. For Windows make sure "jamdict-data-fix" is installed instead of "jamdict-data", if you encounter file access errors when installing that package. The required packages are: mecab-python3, unidic, pykakasi, jamdict, wheel, jamdict-data-fix.

## Update Subtitles
- Open a terminal in the "build" folder, to make sure you see any errors which occur.
- Run "export_subtitles.bat", which extracts the subtitles from the game data.
- Run "process_subtitles.py", to generate and add the Furigana.
- Run "import_subtitles.bat", to import the updated subtitles back into the game format.

## Update Binaries
Requires Visual Studio 2022 setup for C++.

- Open the submodule "src\red4ext\sdk" and make sure you check out the remote "master" branch.
- Open "src\red4ext\cyberpunk2077-furigana.sln" in Visual Studio 2022.
- Update the version "RED4EXT_SEMVER" at the bottom of "dllmain.cpp" to bump up the version of the mod.
- Rebuild the "Release x64" version.

## Package version
Requires WinRAR to be installed.

- Update the mod version and dependencies in "Readme.md".
- Run "build\create_package.bat".
- Find the finished and ready package in "packages".
- Rename the package so it contains the new version of the mod.
