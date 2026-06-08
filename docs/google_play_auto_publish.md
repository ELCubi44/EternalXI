# Publicación automática en Google Play Closed Testing (Eternal XI)

Flujo automatizado para publicar actualizaciones privadas en **Closed Testing** usando Fastlane. **Nunca publica en Production.**

| Dato | Valor |
|------|-------|
| App Flutter | `eternalxi_front/` |
| Package name | `es.eternalxi.app` |
| Track API | `alpha` (Prueba cerrada - Alpha) |
| AAB | `eternalxi_front/build/app/outputs/bundle/release/app-release.aab` |
| Credenciales locales | `%USERPROFILE%\.local\eternalxi\google-play-service-account.json` |
| Firma release | `eternalxi_front/android/key.properties` + keystore externo |

---

## Qué hace el script automáticamente

`scripts/publish_play_closed.ps1`:

1. Valida `key.properties`, keystore, JSON de service account y Fastlane.
2. Incrementa `pubspec.yaml`: patch +1 y versionCode +1 (`1.0.0+4` → `1.0.1+5`).
3. Ejecuta `flutter clean`, `flutter pub get`, `flutter build appbundle --release`.
4. Verifica que existe el `.aab` firmado.
5. Ejecuta Fastlane lane `closed_testing` → sube solo al track **alpha** (Prueba cerrada - Alpha).
6. Muestra resumen con versionName, versionCode, ruta del AAB y resultado.

**Seguridad contra otros tracks:** el `Fastfile` solo permite el track `alpha`. Cualquier otro track (`production`, `beta`, `internal`, etc.) aborta con error.

**Release status actual:** `draft` en el track `alpha` (app en borrador en Play Console).

| Situación de la app | `release_status` en Fastfile | Efecto |
|---------------------|------------------------------|--------|
| **App en borrador** (primera subida) | `draft` | Sube el AAB como borrador; debes revisar y publicar manualmente en consola |
| **App ya publicada / fuera de borrador** | `completed` | Rollout automático a testers de Prueba cerrada - Alpha |

> Mientras Play Console muestre la app como borrador, Google rechaza `completed` con: *Only releases with status draft may be created on draft app.* Cambia a `completed` en `Fastfile` cuando la ficha ya no esté en borrador.

No afecta a Production, Open Testing (`beta`) ni Internal Testing.

---

## Configuración única en Google Play Console

Haz esto **una sola vez** antes de la primera publicación automática:

### 1. Crear la app y el track Prueba cerrada - Alpha

1. [Google Play Console](https://play.google.com/console) → crea la app `es.eternalxi.app` si no existe.
2. **Testing** → **Prueba cerrada** → usa el track **Alpha**.
3. Añade lista de testers (emails o enlace de opt-in).

> En consola el canal se llama «Prueba cerrada - Alpha», pero en la API/Fastlane el identificador es **`alpha`**. Si renombraste el track en consola, ajusta `CLOSED_TESTING_TRACK` en `eternalxi_front/android/fastlane/Fastfile` con el nombre exacto de la API.

### 2. Ficha de tienda y requisitos de política (manual)

La API **no puede completar** todo lo que Play exige la primera vez. Suele requerir acción manual en consola:

- Descripción corta / larga, icono, capturas.
- Clasificación de contenido (cuestionario).
- Política de privacidad (URL).
- Declaración de permisos / datos (Data safety).
- Países de distribución.
- Aceptar acuerdos del desarrollador.

Si falta algo, Fastlane/Google devolverá error al subir. Complétalo en Play Console y vuelve a ejecutar el script.

### 3. Vincular cuenta de servicio (API)

1. Play Console → **Setup** → **API access**.
2. Vincula un proyecto de Google Cloud (o créalo).
3. **Create new service account** → abre Google Cloud Console.
4. Crea service account con rol mínimo para Play (p. ej. acceso a Play Console via invitación).
5. En Play Console → **Users and permissions** → invita la service account con permiso **Release to testing tracks** (y **View app information**). **No des permiso de Production** si quieres máxima seguridad.
6. En Google Cloud → service account → **Keys** → **Add key** → **JSON** → descarga el archivo.

### 4. Keystore de upload (firma Android)

Si no tienes keystore:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.local\eternalxi"
keytool -genkey -v -keystore "$env:USERPROFILE\.local\eternalxi\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Configura firma:

```powershell
Copy-Item eternalxi_front\android\key.properties.example eternalxi_front\android\key.properties
notepad eternalxi_front\android\key.properties
```

Ejemplo:

```properties
storePassword=TU_storePassword
keyPassword=TU_keyPassword
keyAlias=upload
storeFile=C:/Users/TU_USUARIO/.local/eternalxi/upload-keystore.jks
```

### 5. Instalar Fastlane (Windows)

Opción A — gem global (requiere [RubyInstaller](https://rubyinstaller.org/)):

```powershell
gem install fastlane
```

Opción B — Bundler en el proyecto Android:

```powershell
cd eternalxi_front\android
gem install bundler
bundle install
```

El script detecta `fastlane` en PATH o `bundle exec fastlane` si existe `Gemfile`.

---

## Dónde guardar credenciales (nunca en Git)

| Archivo | Ubicación recomendada |
|---------|------------------------|
| Service account JSON | `%USERPROFILE%\.local\eternalxi\google-play-service-account.json` |
| Keystore | `%USERPROFILE%\.local\eternalxi\upload-keystore.jks` |
| key.properties | `eternalxi_front/android/key.properties` (gitignored) |

Alternativa: variable de entorno apuntando al JSON:

```powershell
$env:GOOGLE_PLAY_JSON_KEY = "C:\ruta\a\tu\service-account.json"
```

Todo lo anterior está en `.gitignore`.

---

## Comandos

### Comprobar prerequisitos (sin publicar)

```powershell
cd "C:\Users\migue\OneDrive\Proyectos\Eternal XI"
.\scripts\check_play_release_ready.ps1
```

Comprueba: firma, `key.properties`, keystore, JSON, Fastlane, versión en `pubspec.yaml`, y AAB si ya existe.

### Publicar nueva actualización en Prueba cerrada - Alpha

```powershell
cd "C:\Users\migue\OneDrive\Proyectos\Eternal XI"
.\scripts\publish_play_closed.ps1
```

### Solo compilar AAB (sin subir)

```powershell
.\scripts\build_play_release.ps1
```

---

## Si Google Play rechaza la subida

| Síntoma | Acción |
|---------|--------|
| Ficha de tienda incompleta | Completa Store listing, icono y capturas en consola |
| Permisos API insuficientes | Revisa invitación de la service account en Users and permissions |
| Contenido / políticas | Completa Content rating, Data safety, Privacy policy |
| Sin testers | Añade emails o enlace en Closed testing |
| Revisión pendiente | Primera app o cambios sensibles pueden requerir revisión manual en consola |
| `versionCode` duplicado | El script ya incrementa el código; si falló tras subir, no vuelvas a ejecutar sin revisar `pubspec.yaml` |
| Track `alpha` no encontrado | Verifica el nombre del track en API/Consola (Renombrar pista) y actualiza `CLOSED_TESTING_TRACK` en el Fastfile |
| Firma incorrecta | El keystore debe ser el mismo registrado en Play (upload key) |

---

## Archivos del flujo

| Archivo | Rol |
|---------|-----|
| `scripts/publish_play_closed.ps1` | Script principal de publicación |
| `scripts/check_play_release_ready.ps1` | Diagnóstico sin publicar |
| `scripts/play_release_common.ps1` | Validaciones y bump de versión |
| `scripts/build_play_release.ps1` | Solo build AAB firmado |
| `eternalxi_front/android/fastlane/Fastfile` | Lane `closed_testing` |
| `eternalxi_front/android/fastlane/Appfile` | Package name y JSON |
| `eternalxi_front/android/app/build.gradle.kts` | Firma release obligatoria (sin debug) |

---

## Publicación manual previa

Si prefieres subir el `.aab` a mano la primera vez, consulta también `docs/google_play_private_release.md`.
