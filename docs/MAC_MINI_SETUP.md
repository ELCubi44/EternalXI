# Configurar el Mac Mini para las dos apps iOS

Hace falta **un Mac** (este Mini) para firmar, archivar y subir **Eternal XI** y **Eternal Fantasy** a App Store Connect. Android se sigue publicando desde Windows.

## 1. Cuentas

- Apple ID con **Apple Developer Program** (99 USD/año) activo.
- El proyecto iOS ya tiene `DEVELOPMENT_TEAM = 5ZM8MBAC3X` en Xcode. Confirma en [developer.apple.com](https://developer.apple.com/account) que ese Team ID es el tuyo.
- GitHub: misma cuenta `ELCubi44` (SSH o GitHub CLI).

## 2. Software a instalar (en este orden)

1. **Xcode** desde App Store (última estable) ? ábrelo una vez y acepta la licencia.
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

## 4. Identificadores (App Store Connect + Xcode)

Crea **dos apps** en [App Store Connect](https://appstoreconnect.apple.com):

| App | Bundle ID | SKU sugerido |
|-----|-----------|--------------|
| Eternal XI | `es.eternalxi.app` | `eternalxi` |
| Eternal Fantasy | `es.eternalfantasy.app` | `eternalfantasy` |

En [developer.apple.com ? Identifiers](https://developer.apple.com/account/resources/identifiers/list) registra ambos Bundle IDs (App + Push Notifications si usas FCM).

Luego en cada proyecto:

```bash
cd ~/Proyectos/EternalXI/eternalxi_front
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

En Xcode: Signing & Capabilities ? Team = el de `5ZM8MBAC3X`, Bundle Identifier = el de esa app. Repite con `EternalFantasy` (`es.eternalfantasy.app`).

**Mismo logo** de momento: `eternalxi_front/assets/app/logo.png` en ambos.

## 5. Firebase iOS

- Eternal XI: ya tiene `GoogleService-Info.plist` con `es.eternalxi.app`.
- Eternal Fantasy: crea la app iOS `es.eternalfantasy.app` en Firebase y sustituye `ios/Runner/GoogleService-Info.plist`.

## 6. Compilar y subir a TestFlight

Con el `.xcworkspace` abierto: Product ? Archive ? Distribute App ? App Store Connect.

O por terminal:

```bash
flutter build ipa --release
```

El `.ipa` queda en `build/ios/ipa/`.

## 7. Qué no hace falta duplicar

- El **backend** es uno solo (VPS). Las dos apps apuntan a la misma API.
- El **keystore de Android** y Fastlane de Play se quedan en el PC Windows.
