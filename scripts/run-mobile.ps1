# Ejecuta la app Flutter en el móvil conectado (ZTE habitual)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.local\deploy.env'

function Read-DeployEnv {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "No existe $Path"
    }
    $vars = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $vars[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim()
    }
    return $vars
}

$config = Read-DeployEnv -Path $envFile
$flutterDir = Join-Path $repoRoot $config['FLUTTER_PROJECT_DIR']
$deviceId = $config['FLUTTER_DEVICE_ID']

Write-Host "==> flutter run -d $deviceId"
Push-Location $flutterDir
try {
    flutter run -d $deviceId
} finally {
    Pop-Location
}
