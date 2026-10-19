# Reconstruye el borrador de arte y comprueba la exportación; no instala una APK.
[CmdletBinding()]
param(
    [string]$BlenderPath = "$env:LOCALAPPDATA\EternalClashDev\blender\blender-4.5.3-windows-x64\blender.exe",
    [string]$GodotPath = "$env:LOCALAPPDATA\EternalClashDev\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe",
    [switch]$Film
)
$ErrorActionPreference = 'Stop'
$artRepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $BlenderPath)) { throw 'Indica -BlenderPath con Blender 4.5.' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Indica -GodotPath con Godot 4.7.2.' }
# El entorno de escritorio puede virtualizar LocalAppData. El cargador SxS de
# Blender necesita su ruta física para localizar la biblioteca blender.crt.
if (-not ('ClashArt.NativePath' -as [type])) {
    Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
namespace ClashArt {
  public static class NativePath {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint GetFinalPathNameByHandle(SafeFileHandle file, StringBuilder path, uint capacity, uint flags);
  }
}
'@
}
$artHandle = [IO.File]::Open($BlenderPath, 'Open', 'Read', 'ReadWrite')
try {
    $artBuffer = [Text.StringBuilder]::new(4096)
    $artPathLength = [ClashArt.NativePath]::GetFinalPathNameByHandle($artHandle.SafeFileHandle, $artBuffer, 4096, 0)
    if ($artPathLength -eq 0 -or $artPathLength -ge 4096) { throw 'No se pudo resolver la ruta física de Blender.' }
    $artResolvedBlender = $artBuffer.ToString()
    if ($artResolvedBlender.StartsWith('\\?\')) { $artResolvedBlender = $artResolvedBlender.Substring(4) }
} finally { $artHandle.Dispose() }
$artArguments = @('--background', '--factory-startup', '--python-exit-code', '1', '--python', (Join-Path $PSScriptRoot 'art\build_thiago_model.py'))
if ($Film) { $artArguments += @('--', '--film') }
& $artResolvedBlender @artArguments
if ($LASTEXITCODE -ne 0) { throw 'Falló la reconstrucción del modelo.' }
& $artResolvedBlender --background (Join-Path $artRepoRoot 'art_source\thiago\thiago.blend') --python-exit-code 1 --python (Join-Path $PSScriptRoot 'art\validate_thiago_model.py')
if ($LASTEXITCODE -ne 0) { throw 'Falló la validación de malla, pesos o materiales.' }
& $GodotPath --headless --path (Join-Path $artRepoRoot 'eternalclash_godot') --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Falló la importación Godot.' }
& $GodotPath --headless --path (Join-Path $artRepoRoot 'eternalclash_godot') --script tests/test_thiago_import.gd
if ($LASTEXITCODE -ne 0) { throw 'Falló la prueba del esqueleto en Godot.' }
