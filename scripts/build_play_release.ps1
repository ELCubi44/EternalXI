# Genera un Android App Bundle (.aab) firmado para Google Play Console.
# Requiere firma release real (key.properties + keystore). Sin fallback a debug.
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'play_release_common.ps1')

$paths = Get-PlayReleasePaths

Write-Host "==> Validando firma release" -ForegroundColor Cyan
$prereq = Test-PlayReleasePrerequisites
$keyChecks = $prereq.Checks | Where-Object { $_.Name -in @('key.properties', 'keystore release') }
foreach ($check in $keyChecks) {
    $icon = if ($check.Ok) { '[OK]' } else { '[FALTA]' }
    $color = if ($check.Ok) { 'Green' } else { 'Red' }
    Write-Host "$icon $($check.Name): $($check.Detail)" -ForegroundColor $color
}

$failedKeyChecks = @($keyChecks | Where-Object { -not $_.Ok })
if ($failedKeyChecks.Count -gt 0) {
    throw "Firma release incompleta. Configura key.properties y el keystore antes de compilar."
}

Write-Host "==> flutter clean" -ForegroundColor Cyan
Push-Location $paths.FlutterDir
try {
    flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "==> flutter pub get" -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "==> flutter build appbundle --release" -ForegroundColor Cyan
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if (-not (Test-Path $paths.AabPath)) {
        throw "No se encontró el AAB en $($paths.AabPath)"
    }

    Write-Host ""
    Write-Host "Build completada. AAB generado:" -ForegroundColor Green
    Write-Host (Resolve-Path $paths.AabPath).Path -ForegroundColor Green
} finally {
    Pop-Location
}
