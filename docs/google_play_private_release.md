# Build privada para Google Play Console (Eternal XI)

> **Publicación automática:** si ya tienes Fastlane y la service account configurados, usa `docs/google_play_auto_publish.md` y `.\scripts\publish_play_closed.ps1`.

Guía para generar un **Android App Bundle (.aab)** firmado en release y subirlo manualmente a Google Play Console (Prueba cerrada - Alpha; API track: `alpha`).

- **App Flutter:** `eternalxi_front/`
- **Package name:** `es.eternalxi.app`
- **Backend producción:** `https://api.eternalxi.com/api/v1` (configurado en `lib/core/constants/api_constants.dart`)
- **No se sube automáticamente a Play** hasta configurar la Google Play Developer API.

---

## 1. Crear el keystore (solo la primera vez)

Si aún no tienes un keystore de **upload key** para Play Console:

```powershell
keytool -genkey -v -keystore C:\Users\TU_USUARIO\.local\eternalxi\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Recomendaciones:

- Guarda el `.jks` **fuera del repositorio** (por ejemplo en `C:\Users\TU_USUARIO\.local\eternalxi\`).
- Anota `storePassword`, `keyPassword` y `keyAlias` en un gestor de contraseñas.
- Haz copia de seguridad del keystore; si lo pierdes, no podrás actualizar la app en Play con la misma firma.

---

## 2. Configurar `android/key.properties`

1. Copia la plantilla:

   ```powershell
   Copy-Item eternalxi_front\android\key.properties.example eternalxi_front\android\key.properties
   ```

2. Edita `eternalxi_front/android/key.properties` con tus valores reales:

   ```properties
   storePassword=TU_storePassword
   keyPassword=TU_keyPassword
   keyAlias=upload
   storeFile=C:/Users/TU_USUARIO/.local/eternalxi/upload-keystore.jks
   ```

   - `storeFile` puede ser ruta absoluta o relativa a `eternalxi_front/android/`.
   - Este archivo está en `.gitignore`: **no lo subas a Git**.

3. Gradle leerá `key.properties` al compilar release (`eternalxi_front/android/app/build.gradle.kts`).

---

## 3. Subir `versionCode` (y opcionalmente `versionName`)

Edita `eternalxi_front/pubspec.yaml`:

```yaml
version: 1.0.0+4
#        ^^^^^ ^^
#        |     └── versionCode (entero; debe incrementarse en cada subida a Play)
#        └── versionName (visible para el usuario)
```

Ejemplo para la siguiente release:

```yaml
version: 1.0.1+5
```

También puedes pasar valores en el build (sin editar el archivo):

```powershell
flutter build appbundle --release --build-name=1.0.1 --build-number=5
```

---

## 4. Generar el .aab con el script

Desde la raíz del repositorio:

```powershell
.\scripts\build_play_release.ps1
```

El script ejecuta:

1. `flutter clean`
2. `flutter pub get`
3. `flutter build appbundle --release`

Al terminar muestra la ruta del bundle:

```
eternalxi_front\build\app\outputs\bundle\release\app-release.aab
```

---

## 5. Qué archivo subir a Play Console

Sube **solo** este archivo:

| Archivo | Ruta |
|---------|------|
| Android App Bundle | `eternalxi_front/build/app/outputs/bundle/release/app-release.aab` |

No subas APKs si vas a usar App Bundle (recomendado por Google).

---

## 6. Crear una release en Prueba cerrada - Alpha

1. Entra en [Google Play Console](https://play.google.com/console).
2. Selecciona la app **Eternal XI** (`es.eternalxi.app`).
3. Menú **Testing** → **Prueba cerrada** → track **Alpha**.
4. Pulsa **Create new release** / **Crear nueva versión**.
5. En **App bundles**, sube `app-release.aab`.
6. Completa **Release notes** (notas de la versión).
7. Revisa y pulsa **Review release** → **Start rollout to Closed testing**.

> El flujo automático (`publish_play_closed.ps1`) usa el track API **`alpha`**, que corresponde a este canal.

**App en borrador:** si es la primera vez y Play Console aún no ha publicado la ficha, Fastlane debe usar `release_status: "draft"`. La release queda como borrador en Alpha; complétala y envíala desde la consola. Cuando la app ya no esté en borrador, el Fastfile puede usar `completed` para rollout automático.

Invita testers por lista de correos o enlace de opt-in según el tipo de lista que configures.

---

## 7. Comprobaciones antes de subir

- [ ] `key.properties` existe y apunta al keystore correcto.
- [ ] `versionCode` en `pubspec.yaml` es mayor que el de la última versión en Play.
- [ ] El `.aab` se generó sin errores.
- [ ] Has probado la app en un dispositivo real o emulador con build release si es posible.

---

## 8. Automatización futura (opcional)

Cuando quieras subir desde CI/CD:

- Configura la [Google Play Developer API](https://developers.google.com/android-publisher).
- Usa una cuenta de servicio con permisos en Play Console.
- Herramientas habituales: `fastlane supply`, GitHub Action `r0adkll/upload-google-play`, etc.

Hasta entonces, el flujo manual con `build_play_release.ps1` + subida en la consola es suficiente.
