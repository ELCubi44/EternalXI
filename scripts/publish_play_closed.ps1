# Publica una nueva actualización en Google Play Prueba cerrada - Alpha (track: alpha).
# Ejecutar desde la raíz del repositorio.
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'play_release_common.ps1')

function Write-PublishSummary {
    param(
        [string]$VersionName,
        [int]$VersionCode,
        [string]$AabPath,
        [string]$UploadResult,
        [string]$Track
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " RESUMEN DE PUBLICACION (Prueba cerrada - Alpha)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " versionName  : $VersionName"
    Write-Host " versionCode  : $VersionCode"
    Write-Host " track        : $Track"
    Write-Host " AAB          : $AabPath"
    Write-Host " resultado    : $UploadResult"
    Write-Host "========================================" -ForegroundColor Cyan
}

Write-Host "==> Eternal XI - publicacion en Google Play Prueba cerrada - Alpha" -ForegroundColor Cyan
Write-Host ""

$prereq = Test-PlayReleasePrerequisites
Write-PlayReleaseCheckReport -Result $prereq
Write-Host ""

if (-not $prereq.Ok) {
    throw "Prerequisitos incompletos. Ejecuta .\scripts\check_play_release_ready.ps1 para mas detalle."
}

$paths = $prereq.Paths
$fastlane = $prereq.FastlaneCommand

Write-Host "==> Incrementando version en pubspec.yaml" -ForegroundColor Cyan
$version = Update-PubspecVersion -PubspecPath $paths.Pubspec
Write-Host "Nueva version: $($version.VersionName) (versionCode $($version.VersionCode))" -ForegroundColor Green

Write-Host "==> flutter clean" -ForegroundColor Cyan
Push-Location $paths.FlutterDir
try {
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean fallo con codigo $LASTEXITCODE" }

    Write-Host "==> flutter pub get" -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get fallo con codigo $LASTEXITCODE" }

    Write-Host "==> flutter build appbundle --release" -ForegroundColor Cyan
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build appbundle fallo con codigo $LASTEXITCODE" }
} finally {
    Pop-Location
}

if (-not (Test-Path $paths.AabPath)) {
    throw "No se genero el AAB en $($paths.AabPath)"
}

$aabResolved = (Resolve-Path $paths.AabPath).Path
Write-Host "AAB generado: $aabResolved" -ForegroundColor Green

if (-not $env:GOOGLE_PLAY_JSON_KEY) {
    $env:GOOGLE_PLAY_JSON_KEY = $paths.CredentialsPath
}

Write-Host "==> Subiendo a Play Console via Fastlane (track: alpha)" -ForegroundColor Cyan
Push-Location $paths.AndroidDir
try {
    $fastlaneArgs = @($fastlane.Arguments + @('closed_testing'))
    & $fastlane.Executable @fastlaneArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Fastlane fallo con codigo $LASTEXITCODE"
    }
    $uploadResult = 'Subida correcta a Prueba cerrada - Alpha (track: alpha, release_status: completed)'
} catch {
    $uploadResult = "Error: $($_.Exception.Message)"
    Write-PublishSummary -VersionName $version.VersionName -VersionCode $version.VersionCode `
        -AabPath $aabResolved -UploadResult $uploadResult -Track 'alpha'
    throw
} finally {
    Pop-Location
}

Write-PublishSummary -VersionName $version.VersionName -VersionCode $version.VersionCode `
    -AabPath $aabResolved -UploadResult $uploadResult -Track 'alpha'
