# Mensaje para Cursor en el Mac Mini

Copia **todo el bloque entre las líneas** en un chat nuevo de Cursor en el Mac Mini.

---

```
# Misión Mac Mini — Eternal Fantasy + Eternal XI en TestFlight (agosto 2026)

Eres el agente en el Mac Mini. Trabaja en español. No pidas al usuario pasos manuales si puedes ejecutarlos tú (terminal, Xcode, git, flutter, navegador App Store Connect).

## Contexto (ya hecho en Windows / Play)

En el PC Windows ya quedaron **dos apps separadas** en Google Play y en GitHub:

| App | Repo GitHub | Package Android / Bundle iOS | Play Console (Windows, hecho) |
|-----|-------------|------------------------------|-------------------------------|
| **Eternal Fantasy** | https://github.com/ELCubi44/EternalFantasy | `es.eternalfantasy.app` | Prueba cerrada (ficha + políticas + AAB) |
| **Eternal XI** | https://github.com/ELCubi44/EternalXI | `es.eternalxi.app` | Prueba cerrada; AAB **1.3.9+17** enviado a revisión |

**Tu trabajo:** hacer **lo mismo en Apple** — dos apps distintas en App Store Connect / TestFlight, cada una desde su repo, sin mezclar bundles.

Backend compartido (mismas cuentas en ambas apps):
- Preferido: `https://api.eternalxi.com/api/v1`
- Alternativa LAN/VPS: `http://217.154.184.202:8080/api/v1`

PC Windows = Android + deploy API.  
**Este Mac = iOS + TestFlight.** No redeployes el VPS salvo emergencia.

---

## Regla de oro (Apple)

**No se puede cambiar el Bundle ID de una app ya creada.**  
`es.eternalxi.app` ? `es.eternalfantasy.app` ? son **dos apps** en App Store Connect.

- **Eternal Fantasy** ? repo `EternalFantasy` ? bundle `es.eternalfantasy.app` (crear app nueva si no existe).
- **Eternal XI** ? repo `EternalXI` ? bundle `es.eternalxi.app` (reutilizar la ficha/app que ya exista; subir build Clash/historia).

Nunca compiles Fantasy desde EternalXI ni XI desde EternalFantasy.

---

## FASE 0 — Pull fresco de ambos repos

```bash
mkdir -p ~/Proyectos && cd ~/Proyectos
[ -d EternalFantasy ] || git clone git@github.com:ELCubi44/EternalFantasy.git
[ -d EternalXI ] || git clone git@github.com:ELCubi44/EternalXI.git

cd ~/Proyectos/EternalFantasy && git fetch origin && git checkout main && git pull origin main
cd ~/Proyectos/EternalXI && git fetch origin && git checkout main && git pull origin main
```

Versiones esperadas en `eternalxi_front/pubspec.yaml` (ajusta iOS al mismo build/name al archivar):
- Fantasy: `1.0.1+2` (o superior si el repo ya subió)
- Eternal XI: `1.3.9+17` (o superior)

---

## FASE 1 — Herramientas (hazlo PRIMERO)

```bash
xcode-select -p
xcodebuild -version
sudo xcodebuild -license accept   # si hace falta
git --version
pod --version || sudo gem install cocoapods
flutter --version
flutter doctor -v
ssh -T git@github.com   # Hi ELCubi44!
```

Checklist:
- [ ] Xcode + licencia
- [ ] CocoaPods
- [ ] Flutter ^3.11, doctor OK en Xcode/CocoaPods
- [ ] SSH GitHub
- [ ] Ambos repos en `~/Proyectos` actualizados

Guía larga: `docs/MAC_MINI_SETUP.md`. Team ID Xcode: **`5ZM8MBAC3X`**.

---

## FASE 2 — App Store Connect: inventariar y crear lo que falte

1. Abre https://appstoreconnect.apple.com ? My Apps.
2. Anota qué existe (nombre + Bundle ID).
3. En https://developer.apple.com/account/resources/identifiers/list confirma App IDs:
   - `es.eternalfantasy.app` (Sign in with Apple + Push si aplica)
   - `es.eternalxi.app` (igual)

### Si falta Eternal Fantasy
- New App ? Name: **Eternal Fantasy**
- Bundle ID: `es.eternalfantasy.app`
- SKU: `eternalfantasy`
- Plataforma iOS

### Eternal XI
- Si ya existe con `es.eternalxi.app`: **conservarla** y subir ahí el build del repo EternalXI (historia/Clash).
- No la borres ni intentes “convertirla” en Fantasy.

Informe al usuario qué apps viste antes de seguir.

---

## FASE 3 — Eternal Fantasy ? TestFlight (PRIORIDAD 1)

Ruta: `~/Proyectos/EternalFantasy/eternalxi_front`

```bash
cd ~/Proyectos/EternalFantasy/eternalxi_front
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

En Xcode (Signing & Capabilities):
- Team: `5ZM8MBAC3X`
- Bundle Identifier: `es.eternalfantasy.app`
- Display Name: Eternal Fantasy
- Automatic signing
- Sign in with Apple ON
- `GoogleService-Info.plist` con bundle Fantasy (ya en repo)

Smoke test (simulador o iPhone):
- Login email / Google / Apple
- Tras login ? **Mis ligas** (NO Clash, NO selector de modo)

Subida:
```bash
cd ~/Proyectos/EternalFantasy/eternalxi_front
flutter build ipa --release
# Luego Upload con Xcode Organizer o:
# xcrun altool / notarytool / Transporter según tu setup
```

O: Product ? Archive ? Distribute App ? App Store Connect ? Upload.

TestFlight Fantasy:
1. Esperar procesamiento del build.
2. What to Test: “Eternal Fantasy — ligas fantasy, sin modo historia.”
3. Invitar testers (mismos que uséis en Play / grupo interno).
4. Completar ficha mínima si App Store Connect lo pide (privacidad, categoría, capturas si bloquea).

---

## FASE 4 — Eternal XI ? TestFlight (PRIORIDAD 2)

Ruta: `~/Proyectos/EternalXI/eternalxi_front`

```bash
cd ~/Proyectos/EternalXI/eternalxi_front
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

En Xcode:
- Team: `5ZM8MBAC3X`
- Bundle Identifier: `es.eternalxi.app`
- Display Name: Eternal XI
- Provisioning: perfil App Store / Automatic
- `GoogleService-Info.plist` con `es.eternalxi.app`

Smoke test:
- Login OK
- Entra a **modo historia / Clash** (esta app YA NO es la de ligas)

Subida igual: `flutter build ipa --release` o Archive ? TestFlight a la app **Eternal XI** (`es.eternalxi.app`).

What to Test: “Eternal XI — modo historia / Clash. Actualización 1.3.9 (o la versión del pubspec).”

Si los testers tenían builds viejos monolíticos en XI, avísales de instalar Fantasy aparte para ligas.

---

## Qué incluye cada app (referencia)

### Eternal Fantasy (`EternalFantasy`)
Incluye: auth, perfil, amigos, ligas, mercado, jornadas, recompensas liga, legal.  
No incluye: Clash, cartas, historia, selector de modo.  
Tras login: `/leagues`.

### Eternal XI (`EternalXI`)
Incluye: auth + modo historia / Clash.  
No debe venderse como “solo Fantasy”; es la app de historia.

---

## Qué NO hacer

- Mezclar repos / bundles.
- Subir Fantasy al App ID de XI o al revés.
- Borrar la app `es.eternalxi.app` en Apple (mismo riesgo de package que en Play: con installs no se reutiliza igual).
- Commitear secretos (.p12, passwords, `.env`, `.local/`).
- Deploy del backend desde el Mini (lo hace Windows).

---

## Reglas de trabajo

1. Responde en español.
2. Ejecuta tú; informa resultados.
3. Tras cambios de código: `git commit` + `git push origin main` en el repo tocado.
4. Al acabar cada fase, resume con checklist.

---

## Empieza ahora

1. FASE 1 (herramientas) + FASE 0 (pull).
2. Inventario App Store Connect (dime qué apps/bundles hay).
3. FASE 3: Fantasy en TestFlight.
4. FASE 4: Eternal XI en TestFlight.
5. Resume final: builds (version+build), enlaces TestFlight, testers, pendientes de ficha Apple.

Docs en repo: `docs/MAC_MINI_SETUP.md`, `docs/SPLIT_APPS.md`, `docs/CURSOR_MACMINI_CONTEXT.md`.
```
