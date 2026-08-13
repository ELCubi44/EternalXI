# Configurar el Mac Mini para las dos apps iOS

Hace falta **un Mac** (este Mini) para firmar, archivar y subir **Eternal XI** y **Eternal Fantasy** a App Store Connect. Android se sigue publicando desde Windows.

Estado Android (agosto 2026): ambas apps ya están en Google Play por separado. En Apple hay que dejar **las dos** en TestFlight igual de separadas. Prompt listo para pegar en Cursor: `docs/CURSOR_MACMINI_CONTEXT.md`.

## 1. Cuentas

- Apple ID con **Apple Developer Program** (99 USD/año) activo.
- El proyecto iOS ya tiene `DEVELOPMENT_TEAM = 5ZM8MBAC3X` en Xcode. Confirma en [developer.apple.com](https://developer.apple.com/account) que ese Team ID es el tuyo.
- GitHub: misma cuenta `ELCubi44` (SSH o GitHub CLI).

## 2. Software a instalar (en este orden)

1. **Xcode** desde App Store (última estable) — ábrelo una vez y acepta la licencia.
2. Herramientas de línea:
   ```bash
   xcode-select --install
   sudo xcodebuild -license accept
   ```
3. **CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```
4. **Flutter** (misma major que en el PC, ahora SDK `^3.11`):
   - https://docs.flutter.dev/get-started/install/macos/desktop
   - Añade `flutter/bin` al `PATH` en `~/.zshrc`.
   ```bash
   flutter doctor
   ```
   Debe salir Xcode y CocoaPods en verde. El plugin de Android puede quedar sin emulador; no es necesario en el Mini si solo compilas iOS.

5. **Git** (viene con Xcode) y clave SSH para GitHub, o `brew install gh` y `gh auth login`.

## 3. Clonar los dos repos

```bash
mkdir -p ~/Proyectos
cd ~/Proyectos
git clone git@github.com:ELCubi44/EternalXI.git
git clone git@github.com:ELCubi44/EternalFantasy.git
```

Mantén ambos en `main` actualizado (`git pull origin main`) antes de cada archive.

## 4. Identificadores (App Store Connect + Xcode)

Crea / confirma **dos apps** en [App Store Connect](https://appstoreconnect.apple.com):

| App | Bundle ID | SKU sugerido | Repo |
|-----|-----------|--------------|------|
| Eternal XI | `es.eternalxi.app` | `eternalxi` | EternalXI |
| Eternal Fantasy | `es.eternalfantasy.app` | `eternalfantasy` | EternalFantasy |

En [developer.apple.com ? Identifiers](https://developer.apple.com/account/resources/identifiers/list) registra ambos Bundle IDs (App + Push Notifications si usas FCM).

Luego en cada proyecto:

```bash
cd ~/Proyectos/EternalXI/eternalxi_front
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

En Xcode: Signing & Capabilities ? Team = el de `5ZM8MBAC3X`, Bundle Identifier = el de esa app. Repite con `EternalFantasy` (`es.eternalfantasy.app`).

## 5. Firebase iOS

- **Eternal Fantasy:** `GoogleService-Info.plist` con bundle `es.eternalfantasy.app` (repo Fantasy).
- **Eternal XI:** `GoogleService-Info.plist` con `es.eternalxi.app` (repo EternalXI).

## 6. Orden recomendado TestFlight

1. **Eternal Fantasy** primero (si la app no existe en App Store Connect, créala; no reutilices el Bundle de XI).
2. **Eternal XI** después: reutiliza la ficha `es.eternalxi.app` y sube el build de historia/Clash del repo EternalXI.

### Versiones entre plataformas

Cada juego tiene su propia versión. Android e iOS de **la misma** app deben llevar el mismo `version:` de `pubspec.yaml` (ej. Fantasy `1.0.1+2`, XI `1.3.9+17`). No hace falta que Fantasy y XI compartan número.

Tras cambios en Windows/Play: en el Mini di *«Comprueba cambios en GitHub y alinea iOS con Android»* — el agente hace pull, lee el `pubspec` de cada repo y sube TestFlight con esa versión.

Detalle: `docs/CURSOR_MACMINI_CONTEXT.md` (sección MODO SYNC).

## 7. Compilar y subir a TestFlight

Con el `.xcworkspace` abierto: Product ? Archive ? Distribute App ? App Store Connect.

O por terminal:

```bash
flutter build ipa --release
```

El `.ipa` queda en `build/ios/ipa/`.

## 8. Qué no hace falta duplicar

- El **backend** es uno solo (VPS / `api.eternalxi.com`). Las dos apps apuntan a la misma API.
- El **keystore de Android** y Fastlane de Play se quedan en el PC Windows.
