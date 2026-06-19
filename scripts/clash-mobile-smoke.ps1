# Smoke test visual Clash en móvil: capturas ADB + UI dump + reporte local (Fase 44).
# No modifica la app ni datos del dispositivo.
param(
    [switch]$SkipRunMobile,
    [switch]$OnlyScreenshots,
    [string]$OutputDir = '',
    [int]$DelaySeconds = 12
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$defaultBase = Join-Path $repoRoot 'debug_screenshots\clash'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $sessionDir = Join-Path $defaultBase $timestamp
} else {
    $sessionDir = $OutputDir
}

$script:AdbPath = $null
$script:AdbSerial = $null
$script:SessionDir = $sessionDir
$script:CapturedFiles = [System.Collections.Generic.List[string]]::new()
$script:Warnings = [System.Collections.Generic.List[string]]::new()
$script:LaunchCommand = 'N/A (SkipRunMobile)'

function Write-WarnMsg {
    param([string]$Message)
    Write-Warning $Message
    $script:Warnings.Add($Message)
}

function Resolve-AdbPath {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if ($adb) {
        return $adb.Source
    }

    $candidates = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $candidates) {
        $exe = Join-Path $root 'platform-tools\adb.exe'
        if (Test-Path $exe) {
            return $exe
        }
    }

    throw @"
No se encontró adb en PATH ni en Android SDK (platform-tools).
Instala Android platform-tools o añade adb al PATH.
Rutas comprobadas: ANDROID_HOME, ANDROID_SDK_ROOT, %LOCALAPPDATA%\Android\Sdk
"@
}

function Get-AdbDevice {
    param([string]$AdbExe)

    $raw = & $AdbExe devices 2>&1 | Out-String
    $lines = $raw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $devices = @()
    foreach ($line in $lines) {
        if ($line -match '^List of devices attached') { continue }
        if ($line -match '^(?<id>\S+)\s+(?<state>\S+)') {
            $devices += [PSCustomObject]@{
                Id    = $Matches['id']
                State = $Matches['state']
            }
        }
    }

    if ($devices.Count -eq 0) {
        throw @"
No hay dispositivos ADB conectados.
Conecta el móvil por USB, activa depuración USB y acepta la autorización RSA.
Comando: adb devices
"@
    }

    $ready = $devices | Where-Object { $_.State -eq 'device' }
    if ($ready.Count -eq 0) {
        $states = ($devices | ForEach-Object { "$($_.Id)=$($_.State)" }) -join ', '
        throw "Hay dispositivos ADB pero ninguno en estado 'device'. Estados: $states"
    }

    return $ready[0].Id
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

    $all = @('-s', $script:AdbSerial) + $Args
    $null = & $script:AdbPath @all 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "adb falló (exit $LASTEXITCODE): adb $($all -join ' ')"
    }
}

function Get-DeviceSize {
    $out = (& $script:AdbPath -s $script:AdbSerial shell wm size 2>&1 | Out-String).Trim()
    if ($out -match '(\d+)x(\d+)') {
        return [PSCustomObject]@{
            Width  = [int]$Matches[1]
            Height = [int]$Matches[2]
        }
    }
    Write-WarnMsg "No se pudo leer wm size ($out). Usando 1080x2400 por defecto."
    return [PSCustomObject]@{ Width = 1080; Height = 2400 }
}

function Take-Screenshot {
    param([string]$Name)

    $safe = ($Name -replace '[^\w\-]', '_')
    $local = Join-Path $script:SessionDir "$safe.png"

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $script:AdbPath
        $psi.Arguments = "-s $($script:AdbSerial) exec-out screencap -p"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $process = [System.Diagnostics.Process]::Start($psi)
        $memoryStream = New-Object System.IO.MemoryStream
        $process.StandardOutput.BaseStream.CopyTo($memoryStream)
        $process.WaitForExit()

        if ($process.ExitCode -ne 0) {
            $err = $process.StandardError.ReadToEnd()
            throw "exec-out screencap exit $($process.ExitCode): $err"
        }

        $bytes = $memoryStream.ToArray()
        if ($bytes.Length -lt 100) {
            throw "PNG demasiado pequeño ($($bytes.Length) bytes)"
        }

        [System.IO.File]::WriteAllBytes($local, $bytes)
        $script:CapturedFiles.Add($local)
        Write-Host "  [screenshot] $safe.png ($($bytes.Length) bytes)" -ForegroundColor Green
    } catch {
        Write-WarnMsg "Screenshot '$Name' falló: $($_.Exception.Message)"
    }
}

function Dump-Ui {
    param([string]$Name)

    if ($OnlyScreenshots) {
        return
    }

    $safe = ($Name -replace '[^\w\-]', '_')
    $remote = '/sdcard/clash_smoke_window.xml'
    $local = Join-Path $script:SessionDir "$safe.xml"

    try {
        $null = & $script:AdbPath -s $script:AdbSerial shell uiautomator dump $remote 2>&1
        $null = & $script:AdbPath -s $script:AdbSerial pull $remote $local 2>&1
        if (-not (Test-Path $local)) {
            throw 'pull no generó archivo local'
        }
        $null = & $script:AdbPath -s $script:AdbSerial shell rm $remote 2>&1
        $script:CapturedFiles.Add($local)
        Write-Host "  [ui dump]   $safe.xml" -ForegroundColor DarkGreen
    } catch {
        Write-WarnMsg "UI dump '$Name' falló: $($_.Exception.Message)"
    }
}

function Tap {
    param(
        [int]$X,
        [int]$Y
    )

    try {
        Invoke-Adb shell input tap $X $Y
        Start-Sleep -Milliseconds 700
    } catch {
        Write-WarnMsg "Tap ($X,$Y) falló: $($_.Exception.Message)"
    }
}

function Tap-Relative {
    param(
        [double]$XRatio,
        [double]$YRatio,
        [object]$Size
    )

    $x = [int]($Size.Width * $XRatio)
    $y = [int]($Size.Height * $YRatio)
    Tap -X $x -Y $y
}

function SwipeUp {
    param([object]$Size)

    $x = [int]($Size.Width * 0.5)
    $y1 = [int]($Size.Height * 0.78)
    $y2 = [int]($Size.Height * 0.28)
    try {
        Invoke-Adb shell input swipe $x $y1 $x $y2 350
        Start-Sleep -Milliseconds 800
    } catch {
        Write-WarnMsg "SwipeUp falló: $($_.Exception.Message)"
    }
}

function Back {
    try {
        Invoke-Adb shell input keyevent 4
        Start-Sleep -Milliseconds 700
    } catch {
        Write-WarnMsg "Back falló: $($_.Exception.Message)"
    }
}

function Read-DeployEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "No existe $Path (necesario para lanzar Flutter)."
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

function Start-FlutterMobile {
    $envFile = Join-Path $repoRoot '.local\deploy.env'
    $config = Read-DeployEnv -Path $envFile
    $flutterDir = Join-Path $repoRoot $config['FLUTTER_PROJECT_DIR']
    $deviceId = $config['FLUTTER_DEVICE_ID']

    if (-not (Test-Path $flutterDir)) {
        throw "No existe FLUTTER_PROJECT_DIR: $flutterDir"
    }

    $script:LaunchCommand = "flutter run -d $deviceId (en segundo plano)"
    Write-Host "==> Lanzando app: $script:LaunchCommand" -ForegroundColor Cyan

    $procArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $PSScriptRoot 'run-mobile.ps1')
    )
    Start-Process -FilePath 'powershell.exe' -ArgumentList $procArgs -WorkingDirectory $repoRoot -WindowStyle Minimized | Out-Null
}

function Capture-Step {
    param(
        [string]$Name,
        [scriptblock]$Before = $null
    )

    if ($null -ne $Before) {
        & $Before
    }
    Take-Screenshot -Name $Name
    Dump-Ui -Name $Name
}

function Write-Report {
    param(
        [string]$DeviceId,
        [string]$CommandUsed
    )

    $reportPath = Join-Path $script:SessionDir 'report.md'
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $files = $script:CapturedFiles | ForEach-Object { "- ``$_``" }
    $warns = if ($script:Warnings.Count -eq 0) {
        '- (ninguna)'
    } else {
        ($script:Warnings | ForEach-Object { "- $_" }) -join "`n"
    }

    $onlyShotNote = if ($OnlyScreenshots) { 'Sí (sin UI dump)' } else { 'No' }

    @"
# Clash mobile smoke — $now

## Sesión

| Campo | Valor |
|-------|-------|
| Fecha/hora | $now |
| Dispositivo ADB | ``$DeviceId`` |
| Carpeta | ``$($script:SessionDir)`` |
| Lanzamiento app | $CommandUsed |
| SkipRunMobile | $SkipRunMobile |
| OnlyScreenshots | $onlyShotNote |
| Delay inicial (s) | $DelaySeconds |

## Advertencia

Estas capturas **no se suben al repositorio** (``debug_screenshots/`` está en ``.gitignore``).

Si no estabas en Clash o no había sesión iniciada, algunas capturas pueden mostrar login, selector de modo u otras pantallas intermedias.

La navegación usa **coordenadas aproximadas**; no sustituye QA manual.

## Archivos generados

$($files -join "`n")

## Avisos durante la ejecución

$warns

## Checklist manual de revisión visual

- [ ] Inicio
- [ ] Historia
- [ ] Eventos
- [ ] Equipo
- [ ] Alineación
- [ ] Invocar
- [ ] Historial
- [ ] Tienda
- [ ] Inventario
- [ ] Misiones
- [ ] Logros
- [ ] Noticias
- [ ] Regalos

## Cómo compartir

Comprime la carpeta de sesión y compártela por el canal acordado (chat, ticket, etc.).
No hagas commit de ``debug_screenshots/``.
"@ | Set-Content -Path $reportPath -Encoding UTF8

    $script:CapturedFiles.Add($reportPath)
    Write-Host "==> Reporte: $reportPath" -ForegroundColor Cyan
}

# --- Main ---

Write-Host '==> Clash mobile smoke (ADB)' -ForegroundColor Cyan

$script:AdbPath = Resolve-AdbPath
Write-Host "adb: $script:AdbPath"

$script:AdbSerial = Get-AdbDevice -AdbExe $script:AdbPath
Write-Host "dispositivo: $script:AdbSerial"

New-Item -ItemType Directory -Force -Path $script:SessionDir | Out-Null
Write-Host "salida: $script:SessionDir"

if (-not $SkipRunMobile) {
    Start-FlutterMobile
    Write-Host "Esperando $DelaySeconds s para que la app arranque..."
    Start-Sleep -Seconds $DelaySeconds
} else {
    Write-Host 'SkipRunMobile: no se lanza flutter (app debe estar ya abierta).' -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

$size = Get-DeviceSize
Write-Host "resolución: $($size.Width)x$($size.Height)"

Capture-Step -Name '01_initial'

# Selector de modo / home global (zona central-inferior o tarjeta Clash)
Capture-Step -Name '02_mode_or_home' -Before {
    Tap-Relative -XRatio 0.50 -YRatio 0.62 -Size $size
}

# Entrar Clash (tarjeta o botón aproximado en hub)
Capture-Step -Name '03_clash_home' -Before {
    Tap-Relative -XRatio 0.50 -YRatio 0.45 -Size $size
    Start-Sleep -Milliseconds 900
}

# Equipo
Capture-Step -Name '04_clash_team' -Before {
    Tap-Relative -XRatio 0.20 -YRatio 0.92 -Size $size
}

# Invocar / gacha
Capture-Step -Name '05_clash_summon' -Before {
    Tap-Relative -XRatio 0.40 -YRatio 0.92 -Size $size
}

# Tienda
Capture-Step -Name '06_clash_shop' -Before {
    Tap-Relative -XRatio 0.60 -YRatio 0.92 -Size $size
}

# Inventario (si hay slot en nav o menú; scroll + tap superior)
Capture-Step -Name '07_clash_inventory_if_reachable' -Before {
    SwipeUp -Size $size
    Tap-Relative -XRatio 0.80 -YRatio 0.92 -Size $size
}

Capture-Step -Name '08_back_home' -Before {
    Back
    Back
}

Write-Report -DeviceId $script:AdbSerial -CommandUsed $script:LaunchCommand

Write-Host ''
Write-Host '==> Smoke test finalizado.' -ForegroundColor Green
Write-Host "Revisa: $script:SessionDir"
