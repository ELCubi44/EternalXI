# Dos apps: Eternal XI y Eternal Fantasy

Desde agosto 2026 el cliente único se partió en dos aplicaciones y dos repositorios.

| App | Repo GitHub | Package / Bundle | Qué es |
|-----|-------------|------------------|--------|
| **Eternal XI** | `ELCubi44/EternalXI` | `es.eternalxi.app` | Modo historia (Clash). Listing existente en Play. |
| **Eternal Fantasy** | `ELCubi44/EternalFantasy` | `es.eternalfantasy.app` | Ligas fantasy. App **nueva** en Play y App Store. |

Ambas usan el **mismo backend** (`eternalxi_api_back`) y el **mismo logo** de momento.

## Google Play

1. **Eternal XI** (`es.eternalxi.app`): sigue siendo la ficha actual. Sube el AAB del repo EternalXI.
2. **Eternal Fantasy** (`es.eternalfantasy.app`): hay que **crear una app nueva** en Play Console (la API no puede crear fichas). Luego vincular la misma cuenta de servicio y usar `scripts/publish_play_closed.ps1` de ese repo.

## Firebase

Registrar Android+iOS `es.eternalfantasy.app` en el proyecto `myapplication-e71bb962` y sustituir `google-services.json` / `GoogleService-Info.plist` generados por FlutterFire.

## Apple (Mac Mini)

Ver `docs/MAC_MINI_SETUP.md`.
