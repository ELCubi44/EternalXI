# Exporta los datos del original. Los retratos ya versionados permiten jugar sin red.
[CmdletBinding()]
param([switch]$RefreshPortraits)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$target = Join-Path $repoRoot 'eternalclash_godot'
$source = Join-Path $repoRoot 'eternalxi_front'
$catalog = Get-Content (Join-Path $source 'assets/data/clash/cards.json') -Raw | ConvertFrom-Json
$cards = @($catalog.cards | Where-Object { $_.team -in @('Eternal XI', 'Bastion Adler') -and $_.rarity -eq 'n' })
if ($cards.Count -ne 38) { throw 'El catálogo cambió. Revisa el subconjunto antes de exportarlo.' }
@{ schemaVersion = 1; source = 'EternalXI/assets/data/clash/cards.json'; cards = $cards } |
    ConvertTo-Json -Depth 15 | Set-Content (Join-Path $target 'data/cards.json') -Encoding utf8
Add-Type -AssemblyName System.Drawing
foreach ($card in $cards) {
    $portraitPath = Join-Path $target "art/portraits/$($card.playerId).png"
    if ((Test-Path -LiteralPath $portraitPath) -and -not $RefreshPortraits) { continue }
    $downloadPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    try {
        Invoke-WebRequest "https://api.eternalxi.com/api/v1/assets/players/$($card.playerId)" -OutFile $downloadPath -TimeoutSec 30
        $image = [Drawing.Image]::FromFile($downloadPath)
        $bitmap = New-Object Drawing.Bitmap 360,480
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $scale = [Math]::Min(360.0 / $image.Width, 480.0 / $image.Height)
            $width = [int]($image.Width * $scale)
            $height = [int]($image.Height * $scale)
            $graphics.DrawImage($image, [int]((360 - $width) / 2), 480 - $height, $width, $height)
            $bitmap.Save($portraitPath, [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose(); $image.Dispose() }
    } finally { Remove-Item -LiteralPath $downloadPath -ErrorAction SilentlyContinue }
}
Write-Host '38 cartas exportadas. Los IDs originales se conservan.'
