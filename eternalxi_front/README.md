# Eternal XI

App Flutter del **modo historia** (Clash). El fantasy vive en el repositorio aparte [EternalFantasy](https://github.com/ELCubi44/EternalFantasy).

| | |
|---|---|
| Nombre en tienda | Eternal XI |
| Android `applicationId` | `es.eternalxi.app` |
| iOS bundle | `es.eternalxi.app` |
| API | `http://217.154.184.202:8080/api/v1` (mismo backend que Eternal Fantasy) |

## Requisitos

- Flutter SDK
- Backend Spring (este repo incluye `eternalxi_api_back/` para desplegar la API compartida)

## Ejecutar

```powershell
cd eternalxi_front
flutter pub get
flutter run
```

Tras login se entra directo al hub de historia. El perfil se abre desde la cabecera del hub Clash.

La pantalla de carga usa el mismo arte que Eternal Fantasy (`assets/app/splash_loading.png`).

## iOS / Mac

Bundle ID: `es.eternalxi.app`  
Team de Xcode: `5ZM8MBAC3X`

En App Store Connect esta es la app **Eternal XI**. En Firebase ya está registrada como `es.eternalxi.app`.
