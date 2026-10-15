# Compila la demo independiente. No utiliza firma ni configuración de producción.
[CmdletBinding()]
param(
    [string]$GodotPath = "$env:LOCALAPPDATA\EternalClashDev\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe",
    [string]$DeviceId = '',
    [switch]$Install
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot 'eternalclash_godot'
$outputPath = Join-Path $repoRoot 'releases\eternal-clash-prototype-0.1.0.apk'
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Indica -GodotPath con la ruta al ejecutable Godot 4.7.2.' }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPath) | Out-Null
& $GodotPath --headless --path $projectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Falló la importación Godot.' }
foreach ($testFile in @('tests/test_game.gd', 'tests/test_ui.gd')) {
    & $GodotPath --headless --path $projectPath --script $testFile
    if ($LASTEXITCODE -ne 0) { throw "Falló $testFile" }
}
& $GodotPath --headless --path $projectPath --export-debug Android $outputPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) { throw 'Falló la exportación Android.' }
Get-Item -LiteralPath $outputPath | Select-Object FullName, Length
if ($Install) {
    if ([string]::IsNullOrWhiteSpace($DeviceId)) { throw 'Para instalar indica -DeviceId, obtenido con adb devices.' }
    $adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    & $adbPath -s $DeviceId install -r $outputPath
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar la APK.' }
    & $adbPath -s $DeviceId shell am force-stop es.eternalxi.clash.prototype
    & $adbPath -s $DeviceId shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p es.eternalxi.clash.prototype
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo abrir la demo.' }
}
