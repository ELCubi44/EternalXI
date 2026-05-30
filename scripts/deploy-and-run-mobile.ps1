# Despliega el JAR al servidor y lanza Flutter en el móvil
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot 'deploy-server.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host '==> Lanzando app en el móvil...' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'run-mobile.ps1')
