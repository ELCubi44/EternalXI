@echo off
setlocal
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set OUT=%~dp0..\mobile_reference_screenshots\after_build
if not exist "%OUT%" mkdir "%OUT%"

"%ADB%" shell am start -n es.eternalxi.app/.MainActivity
ping 127.0.0.1 -n 4 >nul
"%ADB%" exec-out screencap -p > "%OUT%\01_mode_selection.png"

"%ADB%" shell input tap 519 702
ping 127.0.0.1 -n 4 >nul
"%ADB%" exec-out screencap -p > "%OUT%\02_fantasy_leagues.png"

"%ADB%" shell input tap 519 950
ping 127.0.0.1 -n 4 >nul
"%ADB%" exec-out screencap -p > "%OUT%\03_clash_home.png"

echo Post-build capturas en %OUT%
