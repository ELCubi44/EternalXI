# Revisión visual básica de capturas Clash generadas por clash-mobile-smoke.ps1 (Fase 45).
param(
    [string]$SessionDir = '',
    [switch]$Latest,
    [string]$OutputFile = ''
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$clashBase = Join-Path $repoRoot 'debug_screenshots\clash'
$minBytes = 10KB
$minDimension = 100
$maxDimension = 10000

$script:OkCount = 0
$script:WarnCount = 0
$script:ErrorCount = 0
$script:Issues = [System.Collections.Generic.List[string]]::new()
$script:Rows = [System.Collections.Generic.List[object]]::new()
$script:ImageAnalysisAvailable = $false

function Write-Issue {
    param(
        [string]$Message,
        [ValidateSet('warning', 'error')]
        [string]$Level = 'warning'
    )

    $script:Issues.Add("[$Level] $Message")
    if ($Level -eq 'error') {
        $script:ErrorCount++
    } else {
        $script:WarnCount++
    }
}

function Resolve-SessionDir {
    param(
        [string]$Explicit,
        [bool]$UseLatest
    )

    if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
        $path = $Explicit
        if (-not (Test-Path $path)) {
            throw "No existe la carpeta de sesión: $path"
        }
        return (Resolve-Path $path).Path
    }

    if (-not (Test-Path $clashBase)) {
        throw 'No hay sesiones de screenshots. Ejecuta scripts/clash-mobile-smoke.ps1 primero.'
    }

    $sessions = Get-ChildItem -Path $clashBase -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending

    if ($sessions.Count -eq 0) {
        throw 'No hay sesiones de screenshots. Ejecuta scripts/clash-mobile-smoke.ps1 primero.'
    }

    if ($UseLatest -or [string]::IsNullOrWhiteSpace($Explicit)) {
        return $sessions[0].FullName
    }

    return $sessions[0].FullName
}

function Initialize-ImageAnalysis {
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $script:ImageAnalysisAvailable = $true
    } catch {
        $script:ImageAnalysisAvailable = $false
        Write-Issue -Message 'System.Drawing no disponible; se omiten checks de imagen casi negra/blanca.' -Level warning
    }
}

function Get-PngDimensions {
    param([string]$Path)

    if (-not $script:ImageAnalysisAvailable) {
        return $null
    }

    $image = $null
    try {
        $image = [System.Drawing.Image]::FromFile($Path)
        return [PSCustomObject]@{
            Width  = $image.Width
            Height = $image.Height
        }
    } finally {
        if ($null -ne $image) {
            $image.Dispose()
        }
    }
}

function Test-UniformScreen {
    param(
        [string]$Path,
        [string]$Kind
    )

    if (-not $script:ImageAnalysisAvailable) {
        return $null
    }

    $bitmap = $null
    try {
        $bitmap = New-Object System.Drawing.Bitmap($Path)
        $width = $bitmap.Width
        $height = $bitmap.Height
        if ($width -le 0 -or $height -le 0) {
            return $null
        }

        $stepX = [Math]::Max(1, [int]($width / 80))
        $stepY = [Math]::Max(1, [int]($height / 80))
        $sumR = 0L
        $sumG = 0L
        $sumB = 0L
        $count = 0

        for ($y = 0; $y -lt $height; $y += $stepY) {
            for ($x = 0; $x -lt $width; $x += $stepX) {
                $pixel = $bitmap.GetPixel($x, $y)
                $sumR += $pixel.R
                $sumG += $pixel.G
                $sumB += $pixel.B
                $count++
            }
        }

        if ($count -eq 0) {
            return $null
        }

        $avgR = $sumR / $count
        $avgG = $sumG / $count
        $avgB = $sumB / $count
        $avg = ($avgR + $avgG + $avgB) / 3.0

        if ($Kind -eq 'black' -and $avg -le 18) {
            return 'casi negra'
        }
        if ($Kind -eq 'white' -and $avg -ge 238) {
            return 'casi blanca'
        }

        return $null
    } catch {
        return $null
    } finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

function Review-Png {
    param(
        [System.IO.FileInfo]$File
    )

    $name = $File.Name
    $bytes = $File.Length
    $notes = [System.Collections.Generic.List[string]]::new()
    $status = 'OK'

    if ($bytes -le $minBytes) {
        $status = 'ERROR'
        $notes.Add("tamaño <= 10 KB ($bytes bytes)")
        Write-Issue -Message "$name : archivo muy pequeño ($bytes bytes)" -Level error
    }

    $dims = Get-PngDimensions -Path $File.FullName
    $resolution = 'N/D'
    if ($null -eq $dims) {
        if (-not $script:ImageAnalysisAvailable) {
            $notes.Add('resolución no leída (sin System.Drawing)')
        } else {
            $status = 'ERROR'
            $notes.Add('no se pudo leer resolución')
            Write-Issue -Message "$name : no se pudo leer resolución" -Level error
        }
    } else {
        $resolution = "$($dims.Width)x$($dims.Height)"
        if ($dims.Width -le 0 -or $dims.Height -le 0) {
            $status = 'ERROR'
            $notes.Add('resolución 0')
            Write-Issue -Message "$name : resolución inválida ($resolution)" -Level error
        } elseif ($dims.Width -lt $minDimension -or $dims.Height -lt $minDimension) {
            $status = 'WARNING'
            $notes.Add('resolución muy baja')
            Write-Issue -Message "$name : resolución sospechosamente baja ($resolution)" -Level warning
        } elseif ($dims.Width -gt $maxDimension -or $dims.Height -gt $maxDimension) {
            $status = 'WARNING'
            $notes.Add('resolución inusualmente alta')
            Write-Issue -Message "$name : resolución inusual ($resolution)" -Level warning
        }

        $black = Test-UniformScreen -Path $File.FullName -Kind 'black'
        if ($black) {
            if ($status -eq 'OK') { $status = 'WARNING' }
            $notes.Add($black)
            Write-Issue -Message "$name : pantalla $black" -Level warning
        }

        $white = Test-UniformScreen -Path $File.FullName -Kind 'white'
        if ($white) {
            if ($status -eq 'OK') { $status = 'WARNING' }
            $notes.Add($white)
            Write-Issue -Message "$name : pantalla $white" -Level warning
        }
    }

    if ($status -eq 'OK') {
        $script:OkCount++
    }

  $script:Rows.Add([PSCustomObject]@{
        File       = $name
        Resolution = $resolution
        SizeBytes  = $bytes
        SizeLabel  = '{0:N0} bytes' -f $bytes
        Status     = $status
        Notes      = if ($notes.Count -eq 0) { '-' } else { ($notes -join '; ') }
    })
}

function Build-Report {
    param(
        [string]$Dir,
        [string]$OutPath,
        [System.IO.FileInfo[]]$PngFiles
    )

    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $lines = [System.Collections.Generic.List[string]]::new()

    $lines.Add('# Clash visual review')
    $lines.Add('')
    $lines.Add("**Fecha:** $now")
    $lines.Add("**Carpeta:** ``$Dir``")
    $lines.Add("**Total capturas PNG:** $($PngFiles.Count)")
    $lines.Add('')
    $lines.Add('## Resumen')
    $lines.Add('')
    $lines.Add("| Métrica | Valor |")
    $lines.Add('|---------|-------|')
    $lines.Add("| OK | $($script:OkCount) |")
    $lines.Add("| Warnings | $($script:WarnCount) |")
    $lines.Add("| Errores | $($script:ErrorCount) |")
    $lines.Add('')
    $lines.Add('## Tabla de capturas')
    $lines.Add('')
    $lines.Add('| Archivo | Resolución | Tamaño | Estado | Notas |')
    $lines.Add('|---------|------------|--------|--------|-------|')

    foreach ($row in $script:Rows) {
        $notes = $row.Notes -replace '\|', '/'
        $lines.Add("| $($row.File) | $($row.Resolution) | $($row.SizeLabel) | $($row.Status) | $notes |")
    }

    $lines.Add('')
    $lines.Add('## Previews')
    $lines.Add('')

    foreach ($png in ($PngFiles | Sort-Object Name)) {
        $lines.Add("### $($png.Name)")
        $lines.Add('')
        $lines.Add("![]($($png.Name))")
        $lines.Add('')
    }

    $lines.Add('## Checklist manual')
    $lines.Add('')
    @(
        'Inicio',
        'Historia',
        'Eventos',
        'Equipo',
        'Alineación',
        'Invocar',
        'Historial',
        'Tienda',
        'Inventario',
        'Misiones',
        'Logros',
        'Noticias',
        'Regalos'
    ) | ForEach-Object { $lines.Add("- [ ] $_") }

    $lines.Add('')
    $lines.Add('## Posibles problemas detectados')
    $lines.Add('')

    if ($script:Issues.Count -eq 0) {
        $lines.Add('- Ninguno detectado por los checks básicos.')
    } else {
        foreach ($issue in $script:Issues) {
            $lines.Add("- $issue")
        }
    }

    $lines.Add('')
    $lines.Add('## Limitaciones')
    $lines.Add('')
    $lines.Add('- Revisión local básica; no sustituye QA manual.')
    $lines.Add('- No hace OCR ni comparación pixel-perfect.')
    $lines.Add('- La detección negra/blanca muestrea píxeles y puede dar falsos positivos.')
    $lines.Add('- ``debug_screenshots/`` no se sube al repositorio.')
    $lines.Add('')

    [System.IO.File]::WriteAllText($OutPath, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
}

# --- Main ---

Write-Host '==> Clash screenshot review' -ForegroundColor Cyan

$useLatest = $Latest -or [string]::IsNullOrWhiteSpace($SessionDir)
$resolvedSession = Resolve-SessionDir -Explicit $SessionDir -UseLatest:$useLatest
Write-Host "sesión: $resolvedSession"

$pngFiles = Get-ChildItem -Path $resolvedSession -Filter '*.png' -File | Sort-Object Name
if ($pngFiles.Count -eq 0) {
    Write-Issue -Message 'No hay archivos PNG en la sesión.' -Level error
    Write-Host 'ERROR: No hay capturas PNG en la carpeta.' -ForegroundColor Red
    exit 1
}

Initialize-ImageAnalysis

foreach ($png in $pngFiles) {
    Review-Png -File $png
}

$reportPath = if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    Join-Path $resolvedSession 'visual_review.md'
} else {
    $OutputFile
}

$reportParent = Split-Path -Parent $reportPath
if (-not [string]::IsNullOrWhiteSpace($reportParent) -and -not (Test-Path $reportParent)) {
    New-Item -ItemType Directory -Force -Path $reportParent | Out-Null
}

Build-Report -Dir $resolvedSession -OutPath $reportPath -PngFiles $pngFiles

Write-Host ''
Write-Host "==> Reporte: $reportPath" -ForegroundColor Green
Write-Host "Capturas: $($pngFiles.Count) | OK: $($script:OkCount) | Warnings: $($script:WarnCount) | Errores: $($script:ErrorCount)"

if ($script:ErrorCount -gt 0) {
    exit 1
}

exit 0
