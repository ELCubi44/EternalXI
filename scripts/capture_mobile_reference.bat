@echo off
setlocal
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set OUT=%~dp0..\mobile_reference_screenshots
if not exist "%OUT%" mkdir "%OUT%"

"%ADB%" shell am force-stop es.eternalxi.app
timeout /t 1 /nobreak >nul
"%ADB%" shell am start -n es.eternalxi.app/.MainActivity
timeout /t 4 /nobreak >nul
"%ADB%" exec-out screencap -p > "%OUT%\01_launch.png"

"%ADB%" shell input tap 519 702
timeout /t 3 /nobreak >nul
"%ADB%" exec-out screencap -p > "%OUT%\02_fantasy_leagues.png"

"%ADB%" shell input tap 90 1420
timeout /t 2 /nobreak >nul
"%ADB%" exec-out screencap -p > "%OUT%\03_fantasy_logros.png"

"%ADB%" shell input keyevent 4
"%ADB%" shell input keyevent 4
timeout /t 2 /nobreak >nul
"%ADB%" shell input tap 519 950
timeout /t 3 /nobreak >nul
"%ADB%" exec-out screencap -p > "%OUT%\04_clash_home.png"

"%ADB%" shell input tap 270 1420
timeout /t 2 /nobreak >nul
"%ADB%" exec-out screencap -p > "%OUT%\05_clash_equipo.png"

echo Capturas en %OUT%
