# Comprueba prerequisitos para publicar en Google Play Closed Testing (sin publicar ni compilar).
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'play_release_common.ps1')

Write-Host "==> Comprobando prerequisitos de publicación Play (Prueba cerrada - Alpha)" -ForegroundColor Cyan
Write-Host ""

$result = Test-PlayReleasePrerequisites
Write-PlayReleaseCheckReport -Result $result

Write-Host ""
if ($result.Ok) {
    Write-Host "Todo listo para publicar con .\scripts\publish_play_closed.ps1" -ForegroundColor Green
    exit 0
}

Write-Host "Faltan prerequisitos. Revisa docs/google_play_auto_publish.md" -ForegroundColor Red
exit 1
