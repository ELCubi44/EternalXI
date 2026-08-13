# Mensaje para Cursor en el Mac Mini

Copia **todo el bloque entre las líneas** en un chat nuevo de Cursor en el Mac Mini.

Cuando solo quieras actualizar (después del setup inicial), basta decirle:
**«Comprueba cambios en GitHub y alinea iOS con Android (versión más reciente de cada app).»**

---

```
# Misión Mac Mini — Eternal Fantasy + Eternal XI en TestFlight

Eres el agente en el Mac Mini. Trabaja en español. No pidas al usuario pasos manuales si puedes ejecutarlos tú (terminal, Xcode, git, flutter, navegador App Store Connect).

## Contexto

En Windows ya hay **dos apps** en Google Play y en GitHub. Aquí haces **lo mismo en Apple** (App Store Connect / TestFlight), cada una desde su repo.

| App | Repo | Bundle ID | Qué es |
|-----|------|-----------|--------|
| **Eternal Fantasy** | https://github.com/ELCubi44/EternalFantasy | `es.eternalfantasy.app` | Ligas fantasy |
| **Eternal XI** | https://github.com/ELCubi44/EternalXI | `es.eternalxi.app` | Historia / Clash |

Backend compartido:
- Preferido: `https://api.eternalxi.com/api/v1`
- Alternativa: `http://217.154.184.202:8080/api/v1`

PC Windows = Android + deploy API.  
**Este Mac = iOS + TestFlight.** No redeployes el VPS salvo emergencia.

Team Xcode: **`5ZM8MBAC3X`**.

---

## Política de versiones (OBLIGATORIA)

Objetivo: **misma versión entre Android e iOS dentro de cada juego**. Los dos juegos pueden (y suelen) tener versiones distintas entre sí.

| Juego | Android y iOS deben coincidir | Independiente del otro juego |
|-------|-------------------------------|------------------------------|
| Eternal Fantasy | Sí ? mismo `name` y `number` en `pubspec.yaml` | Sí |
| Eternal XI | Sí ? mismo `name` y `number` en `pubspec.yaml` | Sí |

Ejemplo válido:
- Fantasy: Android `1.0.1+2` e iOS `1.0.1+2`
- XI: Android `1.3.9+17` e iOS `1.3.9+17`

Ejemplo inválido:
- Fantasy Android `1.0.2+3` e iOS Fantasy todavía en `1.0.1+2`
- Subir iOS de XI a `1.0.1+2` solo porque Fantasy está en esa versión

### Cómo leer la versión canónica

Fuente de verdad por app: `eternalxi_front/pubspec.yaml` en el `main` más reciente de GitHub:

```yaml
version: X.Y.Z+N   # X.Y.Z = CFBundleShortVersionString / versionName
                   # N     = CFBundleVersion / versionCode
```

Flutter usa ese valor para Android e iOS. Tras `git pull`, **no inventes números**: usa exactamente el `version:` del repo de esa app.

Si iOS en App Store Connect / TestFlight tiene un build number igual o mayor al del repo y Apple rechaza el upload, entonces:
1. Avisa al usuario.
2. Solo si él lo confirma, sube el `+N` en **ese** repo (mismo `X.Y.Z`, `N` = último TestFlight + 1), commit + push, y vuelve a archivar.
3. Nunca alinees Fantasy con XI ni al revés.

---

## Frase gatillo — actualización rutinaria

Si el usuario dice algo como:
- «Comprueba cambios en GitHub»
- «Actualiza a la versión de Android»
- «Sincroniza iOS con lo último»
- «Actualiza TestFlight»

Ejecuta **MODO SYNC** (abajo) en **ambas apps**, de forma independiente. No hace falta repetir el setup completo si ya está hecho.

### MODO SYNC (checklist)

Para **cada** repo (`EternalFantasy` y `EternalXI`), por separado:

1. **Pull**
   ```bash
   cd ~/Proyectos/<REPO> && git fetch origin && git checkout main && git pull origin main
   ```
2. **Leer versión canónica**
   ```bash
   grep '^version:' eternalxi_front/pubspec.yaml
   ```
3. **Comparar con lo local / último archive**
   - Si no hay commits nuevos y la versión iOS en TestFlight ya es esa ? reporta «al día» y no subas.
   - Si hay código nuevo o la versión de GitHub es más nueva que la última iOS subida ? continúa.
4. **Preparar iOS**
   ```bash
   cd eternalxi_front
   flutter pub get
   cd ios && pod install && cd ..
   ```
5. **Confirmar signing** (Team `5ZM8MBAC3X`, bundle correcto de esa app).
6. **Build + upload** a la app correcta en App Store Connect:
   ```bash
   flutter build ipa --release
   ```
   (o Archive ? Distribute). Verifica en el IPA / Organizer que Marketing Version y Build = `X.Y.Z` y `N` del pubspec.
7. **TestFlight**
   - Esperar procesamiento.
   - What to Test: incluir nombre de app + `X.Y.Z (N)` + resumen breve del pull (`git log -5 --oneline`).
8. **Informe al usuario** (tabla):

| App | Repo HEAD | version pubspec | Último TestFlight | Acción |
|-----|-----------|-----------------|-------------------|--------|
| Fantasy | … | … | … | subido / al día / bloqueado |
| XI | … | … | … | … |

Orden habitual: primero Fantasy, luego XI (o solo la que el usuario nombre).

---

## Regla de oro (Apple)

**No se puede cambiar el Bundle ID de una app ya creada.**  
`es.eternalxi.app` ? `es.eternalfantasy.app` ? son **dos apps**.

- Fantasy ? solo repo `EternalFantasy` ? `es.eternalfantasy.app`
- XI ? solo repo `EternalXI` ? `es.eternalxi.app`

Nunca mezcles repos, bundles ni versiones entre juegos.

---

## Setup inicial (solo la primera vez o si el Mini está limpio)

### FASE 0 — Clonar / pull

```bash
mkdir -p ~/Proyectos && cd ~/Proyectos
[ -d EternalFantasy ] || git clone git@github.com:ELCubi44/EternalFantasy.git
[ -d EternalXI ] || git clone git@github.com:ELCubi44/EternalXI.git

cd ~/Proyectos/EternalFantasy && git fetch origin && git checkout main && git pull origin main
cd ~/Proyectos/EternalXI && git fetch origin && git checkout main && git pull origin main
```

### FASE 1 — Herramientas

```bash
xcode-select -p
xcodebuild -version
sudo xcodebuild -license accept   # si hace falta
git --version
pod --version || sudo gem install cocoapods
flutter --version
flutter doctor -v
ssh -T git@github.com
```

Checklist: Xcode, CocoaPods, Flutter ^3.11, SSH GitHub, ambos repos en `~/Proyectos`.

### FASE 2 — App Store Connect

1. https://appstoreconnect.apple.com ? My Apps: anota nombre + Bundle ID.
2. Identifiers: confirma `es.eternalfantasy.app` y `es.eternalxi.app` (Sign in with Apple + Push si aplica).
3. Si falta Fantasy: New App ? Eternal Fantasy / `es.eternalfantasy.app` / SKU `eternalfantasy`.
4. Si existe XI con `es.eternalxi.app`: **conservarla** (no borrar, no convertir en Fantasy).

### FASE 3 — Primera subida Fantasy

```bash
cd ~/Proyectos/EternalFantasy/eternalxi_front
flutter pub get && cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Xcode: Team `5ZM8MBAC3X`, bundle `es.eternalfantasy.app`, Display Name Eternal Fantasy, Sign in with Apple ON.

Smoke: login ? **Mis ligas** (sin Clash / sin selector de modo).

```bash
flutter build ipa --release
```

TestFlight What to Test: «Eternal Fantasy — ligas, sin historia. Versión = pubspec.»

### FASE 4 — Primera subida Eternal XI

Igual en `~/Proyectos/EternalXI/eternalxi_front`, bundle `es.eternalxi.app`, Display Name Eternal XI.

Smoke: login ? **historia / Clash**.

What to Test: «Eternal XI — historia/Clash. Versión = pubspec.»

---

## Qué incluye cada app

### Eternal Fantasy
Auth, perfil, amigos, ligas, mercado, jornadas, recompensas liga, legal. Tras login: `/leagues`. Sin Clash/historia.

### Eternal XI
Auth + modo historia / Clash. No es la app de ligas.

---

## Qué NO hacer

- Mezclar repos / bundles / versiones entre Fantasy y XI.
- Forzar la misma versión en ambos juegos.
- Dejar iOS desfasado respecto al `pubspec` de Android de **esa** app.
- Borrar `es.eternalxi.app` en Apple.
- Commitear secretos (.p12, passwords, `.env`, `.local/`).
- Deploy del backend desde el Mini.

---

## Reglas de trabajo

1. Español.
2. Ejecuta tú; informa resultados.
3. Tras cambios de código en el Mini: `git commit` + `git push origin main` en el repo tocado.
4. Tras cada SYNC o fase: checklist + tabla de versiones.

---

## Empieza ahora

Si es la primera vez en este Mac: FASE 0 ? 1 ? 2 ? 3 ? 4.  
Si el usuario pide actualizar: **MODO SYNC** en las apps indicadas (por defecto ambas).

Docs: `docs/MAC_MINI_SETUP.md`, `docs/SPLIT_APPS.md`, `docs/CURSOR_MACMINI_CONTEXT.md`.
```
