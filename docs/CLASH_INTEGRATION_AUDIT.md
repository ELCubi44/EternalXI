# Eternal XI — Auditoría de integración Eternal Clash (frontend Flutter)

> **Alcance:** análisis del estado real de `eternalxi_front/lib/` a junio de 2026.  
> **Versión app auditada:** `1.3.3+11` (`eternalxi_front/pubspec.yaml`).  
> **Sin cambios de código:** este documento es solo diagnóstico.

---

## 1. Resumen ejecutivo

Eternal XI es una app Flutter monolítica organizada por **capas transversales** (`app/`, `core/`, `data/`, `shared/`) y **features por dominio** (`auth`, `leagues`, `rewards`, `profile`, `legal`, `home`). El producto Fantasy actual vive principalmente en `features/leagues/` (85 archivos Dart) y `features/rewards/` (32 archivos), **no** bajo un namespace `fantasy/`.

La navegación global usa **GoRouter** (`lib/app/router.dart`). El estado global usa **Provider** con `ChangeNotifier` (`lib/main.dart`). Tras el login, el destino efectivo es **`/leagues`** (`MyLeaguesScreen`), no `/home`.

Integrar Eternal Clash como segundo modo es viable sin tocar Fantasy **si** se añade un módulo `features/clash/` aislado, se introduce un selector de modo en el flujo post-login y se evita acoplar modelos o imports entre modos.

---

## 2. Estructura real de `lib/`

**Total:** ~250 archivos `.dart`.

```
lib/
├── app/                    (13 archivos)
│   ├── app.dart            → MaterialApp.router, temas, FCM init
│   ├── router.dart         → GoRouter (rutas globales)
│   ├── routes.dart         → constantes de paths
│   ├── icons/xi_icons.dart
│   ├── localization/       → AppLocalizations, league_l10n, rewards_l10n
│   └── theme/              → app_colors, xi_theme_extension
│
├── core/                   (14 archivos)
│   ├── constants/          → api_constants, legal_constants
│   ├── localization/       → app_locale_resolver
│   ├── network/            → api_client, auth_interceptor, token_refresh_interceptor
│   ├── notifications/      → push_notification_handler
│   ├── storage/            → secure_storage_service, theme_preferences_storage
│   ├── theme/
│   └── utils/              → validators, league_asset_urls, league_money_format, …
│
├── data/                   (56 archivos)
│   ├── models/             → 53 modelos (mayoría league/fantasy + user + catalog)
│   └── services/           → auth, user, user_progress, leagues (4 servicios)
│
├── features/               (141 archivos)
│   ├── auth/               (9)   → login, registro, splash, AuthController
│   ├── home/               (1)   → HomeScreen (no usada en router activo)
│   ├── leagues/            (85)  → núcleo Fantasy
│   ├── rewards/            (32)  → recompensas ligadas a liga
│   ├── profile/            (12)  → perfil, progreso cuenta, preferencias
│   └── legal/              (2)   → documentos legales, edad mínima
│
└── shared/                 (24 archivos)
    └── widgets/            → botones, campos, iconos, xi_bottom_nav, …
```

### 2.1 Fantasy (producto actual) — mapeo conceptual

| Concepto producto | Ubicación real hoy |
|---|---|
| Listado de ligas / hub principal | `features/leagues/screens/my_leagues_screen.dart` |
| Shell de liga (tabs) | `features/leagues/shell/league_shell_screen.dart` |
| Tabs Fantasy | `features/leagues/tabs/league_tab_*.dart` |
| Plantilla / alineación | `features/leagues/squad/`, `league_tab_squad.dart` |
| Mercado, clasificación, chat, ajustes | tabs correspondientes |
| Navegación interna (perfil jugador, historial…) | `features/leagues/navigation/league_inner_navigation.dart` |
| API Fantasy | `data/services/leagues_api_service.dart` |
| Modelos Fantasy | `data/models/league_*.dart`, `catalog_*.dart` |
| Recompensas (fichas, sobres, cartas) | `features/rewards/` |

**Nota:** no existe carpeta `features/fantasy/`. Renombrar `leagues` → `fantasy` sería un refactor masivo (~85 archivos + imports en todo el proyecto) **sin beneficio inmediato** para la integración.

---

## 3. Sistema de navegación

### 3.1 GoRouter global

Definido en `lib/app/router.dart`, paths en `lib/app/routes.dart`.

| Ruta | Pantalla | Notas |
|---|---|---|
| `/` | `SplashScreen` | `initialLocation` |
| `/login` | `LoginScreen` | |
| `/verify-email/*`, `/register`, `/password-reset/*` | flujo auth | |
| `/home` | redirect → `/leagues` | `HomeScreen` no se usa |
| `/leagues` | `MyLeaguesScreen` | **hub post-login** |
| `/leagues/create`, `/leagues/join` | crear / unirse | |
| `/leagues/:leagueId` | `LeagueShellScreen` | query opcional `idUsuario` |
| `/profile/*` | editar perfil, cambio email/nickname, borrado | |
| `/profile/tokens-shop` | `RewardsHubScreen` | query opcional `idLiga` |

**Características relevantes:**
- **No hay** `redirect` global de autenticación en el router (solo el redirect de `/home`).
- **No hay** `ShellRoute` ni sub-routers por modo.
- **No hay** guard que impida acceder a `/leagues` sin sesión; el splash decide manualmente.

### 3.2 Navegación interna Fantasy (fuera de GoRouter)

`LeagueInnerNavigation` (`features/leagues/navigation/league_inner_navigation.dart`) usa `Navigator.push` + `MaterialPageRoute` para:
- perfil de jugador (`LeaguePlayerProfileScreen`)
- plantilla participante
- historial de alineaciones / detalle jornada
- catálogo de equipo (`CatalogTeamPlayersScreen`)

Esto crea **dos capas de navegación**: GoRouter (app) + Navigator clásico (dentro de liga).

### 3.3 Bottom navigation

- `MyLeaguesScreen`: secciones internas (ligas / logros) con estado local `_sectionIndex`.
- `LeagueShellScreen`: tabs de liga con `XiBottomNav` (`shared/widgets/xi_bottom_nav.dart`) y `LeagueShellTabs`.

### 3.4 Push notifications

`PushNotificationHandler` (`core/notifications/push_notification_handler.dart`) navega exclusivamente a `AppRoutes.leagueDetail(idLiga)` leyendo `data['idLiga']` del payload FCM.

---

## 4. Sistema de estado

### 4.1 Provider global (`lib/main.dart`)

| Provider | Tipo | Alcance |
|---|---|---|
| `ApiClient` | `Provider` | singleton HTTP |
| `SecureStorageService` | `Provider` | tokens, usuario, prefs |
| `AuthApiService`, `UserApiService`, `UserProgressApiService`, `LeaguesApiService`, `RewardsApiService` | `Provider` | servicios |
| `AuthController` | `ChangeNotifierProvider` | sesión, login, registro |
| `ProfileController` | `ChangeNotifierProvider` | perfil |
| `AccountProgressController` | `ChangeNotifierProvider` | XP / nivel cuenta |
| `UserPreferencesController` | `ChangeNotifierProxyProvider` | tema, idioma |
| `LeaguesController` | `ChangeNotifierProvider` | listado mis ligas |

**No se usa:** Riverpod, Bloc, GetIt, MobX.

### 4.2 Estado local / scoped

- `RewardsController`: instanciado por pantalla/hoja (`ChangeNotifierProvider` local en sheets y pantallas de rewards).
- `LeagueNotificationsController`, `LeagueNightMarketController`, `LeagueOffersController`: controllers de feature con scope de pantalla o panel.
- Estado de tabs en `LeagueShellScreen` (`_tabIndex`) y `MyLeaguesScreen` (`_sectionIndex`).

### 4.3 Implicación para Clash

Clash necesitará **sus propios** `ChangeNotifier` registrados de forma lazy o bajo sub-árbol del modo Clash, **no** mezclados en controllers Fantasy existentes.

---

## 5. Flujo de arranque, login y home

```
main()
  → Firebase.initializeApp
  → SecureStorageService + ThemePreferencesStorage
  → ApiClient(baseUrl, interceptors JWT)
  → MultiProvider(...)
  → EternalXiApp (MaterialApp.router)

SplashScreen (/)
  → AuthController.restoreSession()
  → context.go(/leagues)  si hay sesión
  → context.go(/login)    si no

LoginScreen (/login)
  → AuthController.login()
  → context.go(/leagues)  si OK

MyLeaguesScreen (/leagues)   ← destino real post-auth
  → loadMyLeagues + loadProgress
  → age confirmation dialog (legal)
  → secciones: ligas | logros (AccountProgressController)

LeagueShellScreen (/leagues/:id)
  → carga LeagueDetail vía LeaguesApiService
  → tabs: home, squad, market, standings, chat, settings
```

**Archivos clave del flujo:**
- `lib/main.dart`
- `lib/app/app.dart`
- `lib/app/router.dart`
- `lib/features/auth/screens/splash_screen.dart` (líneas 42–46: decisión de ruta)
- `lib/features/auth/screens/login_screen.dart` (línea 99: `context.go(AppRoutes.leagues)`)
- `lib/features/leagues/screens/my_leagues_screen.dart`

**Observación:** `features/home/screens/home_screen.dart` existe pero el router redirige `/home` → `/leagues`. Es código huérfano respecto al flujo activo.

---

## 6. Modelos de usuario y jugador

### 6.1 Usuario (compartible)

`lib/data/models/user_model.dart` — `UserModel`:
- `id`, `correo`, `nickname`, `nivel`, `foto`, `requiereConfirmacionEdad`
- Usado por `AuthController`, perfil, cabeceras UI.

Modelos relacionados:
- `auth_response_model.dart` — tokens + user en login/refresh
- `user_progress_response.dart` — XP, nivel, logros cuenta
- `user_resources_response.dart` — `fichas` (moneda recompensas Fantasy)
- `user_preferences_response.dart`, `update_user_preferences_request.dart`

### 6.2 Jugador base (catálogo — candidato a puente compartido)

`lib/data/models/catalog_team_player.dart` — `CatalogTeamPlayer`:
- Identificador canónico del jugador real: **`idJugador`**
- Datos de presentación: `nombre`, `pila`, `posicion`, `valoracion`, `fotoJugador`, `idEquipo`, …
- Endpoint documentado en código: `GET /catalog/teams/{idEquipo}/players` / `squad`
- **Contaminación Fantasy:** incluye `idLigaJugador`, `idUsuarioDueno` (contexto liga)

Otros modelos catálogo:
- `catalog_team_summary.dart`, `catalog_team_squad.dart`, `catalog_team_coach.dart`

### 6.3 Jugador Fantasy (aislado — no reutilizar para Clash)

`lib/data/models/league_squad_player.dart` — `LeagueSquadPlayer`:
- `idLigaJugador` + `idJugador` + campos de mercado, cansancio, puntos fantasy, ofertas, protección, etc.

`lib/data/models/league_player_detail.dart` — `LeaguePlayerDetail`:
- Detalle en contexto de liga con estadísticas por jornada.

**Regla derivada:** Clash debe vincular cartas/unidades al **`idJugador`** del catálogo, nunca extender `LeagueSquadPlayer` ni `LeaguePlayerDetail`.

---

## 7. Cliente API y almacenamiento seguro

### 7.1 ApiClient

`lib/core/network/api_client.dart`:
- **Dio** con `baseUrl`: `https://api.eternalxi.com/api/v1` (`core/constants/api_constants.dart`)
- Interceptores: `AuthInterceptor`, `TokenRefreshInterceptor`
- Header `Accept-Language` dinámico
- `extractErrorMessage()` centralizado

Servicios actuales (todos reciben `ApiClient`):
| Servicio | Archivo | Dominio |
|---|---|---|
| `AuthApiService` | `data/services/auth_api_service.dart` | `/auth/*` |
| `UserApiService` | `data/services/user_api_service.dart` | `/users/*`, push token |
| `UserProgressApiService` | `data/services/user_progress_api_service.dart` | progreso cuenta |
| `LeaguesApiService` | `data/services/leagues_api_service.dart` | `/leagues/*`, `/catalog/*` |
| `RewardsApiService` | `features/rewards/data/services/rewards_api_service.dart` | recompensas liga |

`LeaguesApiService` es **monolítico** (liga + catálogo + mercado + chat + partidos). Clash debería tener **`ClashApiService` propio** en `features/clash/data/services/`.

### 7.2 SecureStorageService

`lib/core/storage/secure_storage_service.dart` — `FlutterSecureStorage`:
- Sesión: `accessToken`, `refreshToken`, `tokenType`, `userId`, `nickname`, `correo`, `nivel`, `foto`
- Preferencias: `themeMode`, `languageCode`
- Caché: `progressCache_{userId}`

Métodos: `saveSession`, `updateTokens`, `saveUser`, `clearAuthSession`, `clearSession`.

**Clash futuro:** preferencia `lastGameMode` / `preferredGameMode` debería vivir aquí o en `ThemePreferencesStorage` (`core/storage/theme_preferences_storage.dart`), **sin** mezclar estado Clash en claves Fantasy.

### 7.3 Assets de jugadores

`lib/core/utils/league_asset_urls.dart` — resolución URLs fotos jugador/equipo desde backend. Reutilizable como utilidad de presentación si Clash muestra los mismos jugadores reales.

---

## 8. Dependencias (`pubspec.yaml`)

| Paquete | Versión | Uso actual |
|---|---|---|
| `flutter` / `flutter_localizations` | SDK | UI, i18n |
| `dio` | ^5.9.0 | HTTP |
| `go_router` | ^16.2.4 | navegación |
| `provider` | ^6.1.5 | estado |
| `flutter_secure_storage` | ^9.2.4 | tokens |
| `shared_preferences` | ^2.5.3 | tema (ThemePreferencesStorage) |
| `firebase_core`, `firebase_messaging` | ^4.7 / ^16.2 | push |
| `image_picker`, `image_cropper` | | foto perfil |
| `share_plus` | ^12.0.2 | compartir |
| `timezone` | ^0.11.0 | fechas liga |
| `flutter_animate` | ^4.5.2 | animaciones rewards |
| `cupertino_icons` | ^1.0.8 | iconos |

**No hay** paquetes de animación de batallas, SQLite local, flame, etc. Clash podría necesitar dependencias nuevas en fases posteriores (evaluar en PR dedicado, no en fase 0).

---

## 9. Partes compartibles de forma segura

| Capa | Qué | Condición |
|---|---|---|
| `app/` | `EternalXiApp`, temas base, localización infra | Clash puede tener tema propio extendiendo tokens, no reemplazando Fantasy |
| `core/network/` | `ApiClient`, interceptores | Mismo JWT para ambos modos |
| `core/storage/` | `SecureStorageService` | Solo claves nuevas para prefs Clash |
| `features/auth/` | Login, registro, splash, `AuthController` | Sin cambios de lógica; solo insertar paso post-login |
| `features/profile/` | Perfil cuenta, preferencias | Compartido a nivel usuario |
| `features/legal/` | Términos, edad | Compartido |
| `data/models/user_model.dart` | Usuario | Solo lectura desde Clash |
| Catálogo (lectura) | `idJugador`, nombre, foto vía DTO puente | **No** importar pantallas Fantasy |
| `shared/widgets/` | `AppPrimaryButton`, `AppTextField`, loaders genéricos | Evitar widgets con iconografía/nombres league-specific |
| Firebase / FCM | Infra | Extender routing, no reemplazar |

---

## 10. Partes que deben mantenerse completamente aisladas

| Área | Archivos / módulos | Motivo |
|---|---|---|
| Fantasy core | `features/leagues/**` | 85 archivos, lógica de negocio completa |
| Recompensas Fantasy | `features/rewards/**` | Acoplado a `idLiga`, `LeaguesApiService` |
| Modelos liga | `data/models/league_*.dart` | Semántica mercado/alineación/jornadas |
| `LeaguesApiService` | `data/services/leagues_api_service.dart` | API Fantasy monolítica |
| Controllers Fantasy | `LeaguesController`, controllers en `features/leagues/controller/` | Estado de ligas |
| Rutas Fantasy | `/leagues/*` en `router.dart` | Contrato estable |
| Navegación interna | `LeagueInnerNavigation` | Stack Navigator liga |
| Push league-only | `PushNotificationHandler._navigateFromMessage` | Hardcoded a liga |

**Prohibición explícita de producto:** ningún `import` cruzado `features/leagues` ↔ `features/clash` (ni `features/rewards` ↔ `features/clash` salvo capa de recompensas cruzadas acordada).

---

## 11. Riesgos concretos al integrar un segundo modo

| # | Riesgo | Evidencia en código | Severidad |
|---|---|---|---|
| R1 | **Splash/login saltan directo a `/leagues`** — no hay hook para selector de modo | `splash_screen.dart:46`, `login_screen.dart:99` | Alta |
| R2 | **Router sin guard de auth** — deep links a `/leagues` sin sesión | `router.dart` sin `redirect` global | Media |
| R3 | **`LeaguesController` siempre en árbol raíz** — memoria/estado Fantasy activo aunque el usuario esté en Clash | `main.dart:120-124` | Media |
| R4 | **Push solo entiende `idLiga`** — notificaciones Clash romperían o ignorarían destino | `push_notification_handler.dart:37-44` | Alta (cuando exista Clash backend) |
| R5 | **`RewardsController` importa `LeaguesApiService`** — patrón de acoplamiento a evitar en Clash | `rewards_controller.dart:18-23` | Referencia |
| R6 | **`CatalogTeamPlayer` mezcla id liga** — tentación de reutilizar modelo tal cual en Clash | `catalog_team_player.dart` | Media |
| R7 | **Doble navegación (GoRouter + Navigator)** — Clash necesitará convención clara propia | `league_inner_navigation.dart` | Media |
| R8 | **Refactor `leagues` → `fantasy`** — alto coste, cero valor si se hace antes de Clash | estructura actual | Alta si se intenta |
| R9 | **`HomeScreen` huérfana** — confusión sobre entry point real | `router.dart:62-64` vs `home_screen.dart` | Baja |
| R10 | **Localización monolítica** — `league_l10n.dart` / `rewards_l10n.dart` mezclados con app; Clash necesitará `clash_l10n` separado | `app/localization/` | Media |
| R11 | **Un solo `MaterialApp.router`** — cambios de tema/ruta global afectan ambos modos | `app/app.dart:437-448` | Media |
| R12 | **Backend compartido `/api/v1`** — versionado y namespacing de endpoints Clash pendiente (fuera de este audit, pero bloqueante) | `api_constants.dart` | Alta |

---

## 12. Conclusión de auditoría

El frontend está **preparado para compartir infraestructura** (auth, HTTP, storage, usuario, catálogo de jugadores reales) pero **no está preparado estructuralmente** para dos modos: el flujo post-auth es unívoco hacia Fantasy y no existe separación de namespaces en features.

La integración segura pasa por:
1. Añadir `features/clash/` sin mover `features/leagues/`.
2. Insertar selector de modo **después** de auth y **antes** de `/leagues`.
3. Mantener rutas Fantasy intactas.
4. Crear capa explícita de recompensas cruzadas (no importar `features/rewards` desde Clash).

Ver propuesta detallada en `docs/CLASH_INTEGRATION_ARCHITECTURE.md`.
