# Captura pantallas de referencia del mvil Eternal XI va ADB
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$out = Join-Path (Split-Path $PSScriptRoot -Parent) "mobile_reference_screenshots"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }

function Shot($name) {
    & $adb exec-out screencap -p > (Join-Path $out $name)
    Start-Sleep -Milliseconds 800
}

function Tap-Desc($desc) {
    & $adb shell uiautomator dump /sdcard/ui.xml | Out-Null
    & $adb pull /sdcard/ui.xml "$env:TEMP\ui.xml" 2>$null | Out-Null
    $xml = Get-Content "$env:TEMP\ui.xml" -Raw
    if ($xml -match "content-desc=`"$([regex]::Escape($desc))`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"") {
        $cx = ([int]$matches[1] + [int]$matches[3]) / 2
        $cy = ([int]$matches[2] + [int]$matches[4]) / 2
        & $adb shell input tap $cx $cy
        Start-Sleep -Seconds 2
        return $true
    }
    return $false
}

& $adb shell am start -n es.eternalxi.app/.MainActivity | Out-Null
Start-Sleep -Seconds 3
Shot "01_app_launch.png"

if (Tap-Desc "Entrar a Fantasy") { Shot "02_fantasy_leagues.png" }
if (Tap-Desc "Ligas`nPestaa 1 de 2") { Shot "03_fantasy_ligas_tab.png" }
if (Tap-Desc "Logros`nPestaa 2 de 2") { Shot "04_fantasy_logros_tab.png" }

& $adb shell input keyevent KEYCODE_BACK
Start-Sleep -Seconds 1
& $adb shell input keyevent KEYCODE_BACK
Start-Sleep -Seconds 1

if (Tap-Desc "Entrar a Clash") { Shot "05_clash_home.png" }
if (Tap-Desc "Equipo`nPestaa 2 de 4") { Shot "06_clash_equipo.png" }
if (Tap-Desc "Invocar`nPestaa 3 de 4") { Shot "07_clash_invocar.png" }
if (Tap-Desc "Tienda`nPestaa 4 de 4") { Shot "08_clash_tienda.png" }

Write-Host "Capturas en $out"
