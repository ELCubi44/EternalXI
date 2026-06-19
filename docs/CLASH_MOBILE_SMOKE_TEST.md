# Clash — smoke test visual en móvil (ADB)

Herramienta de **debug local** (Fase 44) para capturar pantallas y volcados UI de Clash en un dispositivo Android conectado. No modifica la app ni sustituye QA manual.

## Requisitos

- Móvil Android con **depuración USB** activada.
- Cable USB y autorización RSA aceptada en el dispositivo.
- **adb** disponible:
  - en `PATH`, o
  - en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`, o
  - vía `ANDROID_HOME` / `ANDROID_SDK_ROOT`.
- Para lanzar la app automáticamente: `.local/deploy.env` con `FLUTTER_PROJECT_DIR` y `FLUTTER_DEVICE_ID` (igual que `scripts/run-mobile.ps1`).
- **Sesión iniciada** en el móvil si quieres capturar Clash en lugar de login o selector de modo.

## Uso

Desde la raíz del repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/clash-mobile-smoke.ps1
```

Solo capturas (app ya abierta, sin `flutter run`):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/clash-mobile-smoke.ps1 -SkipRunMobile
```

Parámetros útiles:

| Parámetro | Descripción |
|-----------|-------------|
| `-SkipRunMobile` | No ejecuta `run-mobile.ps1`; asume la app en primer plano. |
| `-OnlyScreenshots` | Omite `uiautomator dump` (solo PNG). |
| `-OutputDir <ruta>` | Carpeta de salida personalizada. |
| `-DelaySeconds <n>` | Segundos de espera tras lanzar la app (default: 12). |

Ejemplo con carpeta custom:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/clash-mobile-smoke.ps1 -SkipRunMobile -OutputDir "C:\temp\clash_smoke_manual"
```

## Salida

Cada ejecución crea:

```
debug_screenshots/clash/YYYYMMDD_HHMMSS/
  01_initial.png
  01_initial.xml
  02_mode_or_home.png
  ...
  08_back_home.png
  report.md
```

`debug_screenshots/` está en **`.gitignore`** — no subir capturas al repo.

## Paso 2 — Revisión visual básica

Tras capturar, genera un informe automático sobre las PNG:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/clash-review-screenshots.ps1 -Latest
```

O revisando una sesión concreta:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/clash-review-screenshots.ps1 -SessionDir "debug_screenshots/clash/20260619_102703"
```

Salida: `visual_review.md` en la carpeta de sesión (tabla de capturas, previews embebidos, checklist manual, problemas detectados).

Parámetros:

| Parámetro | Descripción |
|-----------|-------------|
| `-Latest` | Usa la carpeta más reciente en `debug_screenshots/clash/` (default si no se pasa `-SessionDir`). |
| `-SessionDir <ruta>` | Carpeta de sesión específica. |
| `-OutputFile <ruta>` | Ruta custom del informe (default: `<sesión>/visual_review.md`). |

Esto sigue siendo **revisión básica** (tamaño, resolución, pantallas casi negras/blancas). No es QA automático ni OCR.

## Qué hace el script

1. Comprueba `adb` y al menos un dispositivo en estado `device`.
2. Opcionalmente lanza la app (`run-mobile.ps1` en ventana minimizada).
3. Captura screenshots con `adb shell screencap` + `adb pull`.
4. Extrae UI dump con `uiautomator dump` (salvo `-OnlyScreenshots`).
5. Intenta taps/swipes/back con **coordenadas aproximadas** (según resolución del dispositivo).
6. Si un paso falla, registra warning y continúa.
7. Genera `report.md` con checklist manual de revisión.

## Limitaciones

- Coordenadas aproximadas: la navegación puede no coincidir con tu layout o estado de sesión.
- No hace login automático ni usa credenciales.
- No borra datos de la app.
- No hace OCR ni assertions visuales automáticas.
- No sustituye pruebas E2E (Appium, CI, etc.).

## Compartir para revisión

1. Abre la carpeta de la sesión en `debug_screenshots/clash/`.
2. Revisa `report.md` y las PNG.
3. Comprime la carpeta y compártela por el canal acordado.
4. No hagas commit de las capturas.

## Relación con otros scripts

| Script | Uso |
|--------|-----|
| `scripts/run-mobile.ps1` | Flutter en primer plano (desarrollo). |
| `scripts/clash-mobile-smoke.ps1` | Capturas ADB + reporte para revisión visual. |
| `scripts/clash-review-screenshots.ps1` | Revisión básica de PNG + `visual_review.md`. |
| `scripts/deploy-and-run-mobile.ps1` | Deploy backend + run móvil. |
