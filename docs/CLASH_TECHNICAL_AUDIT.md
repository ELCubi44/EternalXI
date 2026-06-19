# Auditoría técnica Clash

> **Fase 52** — auditoría de arquitectura y deuda técnica (sin cambios de lógica).  
> **Base:** commit `5e583ef` (Fase 51 — Guía local).  
> **Fecha de referencia:** junio 2026.

---

## Estado actual

| Métrica | Valor |
|---|---|
| Tests Clash | **745** (`flutter test test/features/clash/`) |
| Analyze Clash | **0 errores**; 17 avisos (1 info `use_build_context_synchronously`, 14 info en tests, 2 warnings `unused_element` en `clash_mini_pitch.dart`) |
| Archivos `lib/features/clash/**` | ~346 Dart |
| Archivos `test/features/clash/**` | 47 Dart |
| Assets locales `assets/data/clash/**` | 20 JSON |
| `main.dart` | ~472 líneas; ~40 providers/repos Clash registrados manualmente |
| Enfoque | **Local-first**: contenido en JSON, progreso en SharedPreferences, sin API Clash |

### Módulos implementados

| Módulo | Rol principal |
|---|---|
| `presentation/` | Shell, tabs, navegación interna |
| `home/` | Hub Inicio |
| `story/` | Historia, mapa, niveles story/match |
| `events/` | Eventos de personaje (story + match) |
| `match/` | Motor de partido 7v7, UI de duelos, objetivos |
| `rivals/` | Rivales locales para partidos |
| `cards/` | Catálogo, colección, evolución, XP |
| `team/` | Equipo, alineación 7v7 |
| `gacha/` + `summon/` | Invocación, pity, tickets, historial |
| `shop/` | Tienda local |
| `inventory/` | Materiales, libros, tickets |
| `missions/` | Misiones diarias y semanales |
| `achievements/` | Logros |
| `gifts/` | Regalos |
| `news/` | Noticias locales |
| `help/` | Guía / ayuda (Fase 51) |
| `shared/` | Widgets reutilizables de engagement |

---

## Arquitectura actual

### Estructura por features

Cada feature sigue un patrón habitual:

```
feature/
  domain/          # modelos, enums, reglas puras
  data/            # datasources JSON, storage SP, repositories
  presentation/    # screens, widgets, controllers
```

**Excepciones notables:**

- `match/domain/` concentra el motor (`clash_duel_engine.dart`, ~820 líneas).
- `cards/data/repositories/clash_player_collection_repository.dart` (~950 líneas) agrega cartas, materiales, evolución y XP.
- `shop/data/clash_shop_grant_service.dart` actúa como grant central de ítems de inventario.

### Assets locales

| Asset | Consumidor |
|---|---|
| `cards.json`, `exp_materials.json`, `technique_books.json`, `evolution_materials.json` | Cartas / inventario |
| `story/sagas.json`, `story/chapter_01.json` | Historia |
| `character_events.json` | Eventos |
| `rivals.json` | Rivales |
| `gacha_banners.json`, `gacha_tickets.json` | Gacha |
| `shop_products.json` | Tienda |
| `daily_missions.json`, `weekly_missions.json` | Misiones |
| `achievements.json`, `gifts.json`, `news.json` | Engagement |
| `help_topics.json` | Guía |
| `match_items.json` | Partido (ítems de campo) |

No hay capa de validación JSON unificada: cada datasource parsea con `jsonDecode` y modelos `fromJson` propios.

### Providers y rutas

- **DI:** `MultiProvider` en `lib/main.dart` — creación explícita de ~15 backends SharedPreferences, ~20 repositorios y varios `ChangeNotifierProvider`.
- **Rutas:** `lib/app/router.dart` — shell Clash con rutas anidadas (`story`, `events`, `match`, `help`, `cards`, etc.).
- **Tabs:** `ClashNavigationController` (índices 0–3: Inicio, Equipo, Invocar, Tienda).

### Persistencia (SharedPreferences)

**15 backends** independientes con claves propias:

- Progreso historia, colección, materiales (×3), tickets, alineaciones.
- Gacha: daily, history, pity, ticket inventory.
- Engagement: daily/weekly missions, achievements, gifts, news read, character events.

No existe esquema de versión ni migración centralizada.

### Dependencias internas (simplificado)

```
ClashStoryRepository (wallet coins/gems + grant historia)
    ↑ usado por: shop, gacha, missions, achievements, gifts, events

ClashShopGrantService (ítems inventario)
    ↑ usado por: shop, missions, achievements, gifts, events
    ✗ NO usado por: story (adapters directos), gacha (grantGachaCard)

ClashPlayerCollectionRepository (cartas + materiales + XP)
    ↑ usado por: story, events, gacha, shop grant, lineups

ClashMissionProgressEventHub + event sinks
    ↑ conecta match/story/shop → misiones/logros
```

---

## Puntos fuertes

1. **Aislamiento respecto a Fantasy** — `features/clash/**` sin imports a `features/leagues/**` ni lógica Fantasy; rewards de liga vía `RewardsApiService` separado.
2. **Cobertura de tests** — 745 tests por dominio (match engine, gacha pity, story, events, team 7v7, help, etc.).
3. **Assets locales claros** — contenido editable sin backend; documentación en `docs/CLASH_*.md`.
4. **Módulos por feature** — límites razonables salvo repositorios grandes.
5. **Motor de partido separado** — `clash_duel_engine.dart` desacoplado de UI; testeable.
6. **Widgets shared de engagement** — `ClashClaimButton`, `ClashRewardPreviewRow`, chips de progreso (Fase 40).
7. **Tooling smoke/screenshots** — scripts `clash-mobile-smoke.ps1`, `clash-review-screenshots.ps1`.

---

## Deuda técnica detectada

### Prioridad alta

| # | Hallazgo | Impacto |
|---|---|---|
| A1 | **Wallet única en `ClashStoryRepository`** usada por shop, gacha, missions, events, etc. | Al conectar backend, cualquier desincronización de coins/gems afecta todo el modo. |
| A2 | **Story no usa `ClashShopGrantService`** — grant de ítems vía adapters directos a collection/ticket | **Parcialmente resuelto (Fase 53):** ítems/cartas de historia usan `ClashLocalRewardGranter`; coins/gems siguen en progress. |
| A3 | **`ClashPlayerCollectionRepository` monolítico** (~950 líneas) | Dificulta 11v11 (más slots), evolución y tests; alto acoplamiento. |
| A4 | **15 backends SharedPreferences sin versión/migración** | Riesgo alto al sincronizar con servidor o cambiar esquema de progreso. |
| A5 | **Duplicación story/events en grant + UI** — previews y pantallas post-recompensa casi gemelas | Cada nuevo evento/personaje duplica mantenimiento (Fases 49–50). |
| A6 | **`main.dart` como composition root gigante** (~40 registros Clash) | Errores de wiring, difícil test de integración y arranque lento de lectura. |
| A7 | **IDs de contenido locales sin contrato estable** — cardId, levelId, eventId en JSON | Backend necesitará mapeo explícito; riesgo de rotura al renombrar assets. |

### Prioridad media

| # | Hallazgo | Impacto |
|---|---|---|
| M1 | **Cuatro copias de `_grantReward()`** en repos engagement (daily, weekly, achievements, gifts) | **Parcialmente resuelto (Fase 53):** delegación a `ClashLocalRewardGranter`; repos conservan marcado claimed/idempotencia. |
| M2 | **Cuatro copias de `_rewardParts()`** en cards de misiones/logros/regalos | Misma cadena de preview strings duplicada. |
| M3 | **Tres familias de preview UI** — `ClashRewardPreviewRow` (strings), `ClashStoryRewardPreview` / `ClashEventRewardPreview` (tipados), `clashMatchObjectiveRewardPreview` (función) | Inconsistencia visual y de l10n entre módulos. |
| M4 | **`ClashStoryLevelStatusChip` reutilizado fuera de story** (help, events) | Nombre y ubicación confunden; debería vivir en `shared/`. |
| M5 | **Pantallas match duplicadas** — `ClashMatchScreen` vs `ClashEventMatchScreen` con lógica paralela | Más superficie al añadir mecánicas de partido. |
| M6 | **`clash_test_support.dart` muy grande** (~1267 líneas) | Setup de tests repetido; frágil ante nuevos repos. |
| M7 | **Archivos UI >300 líneas** — `clash_match_duel_panel.dart` (737), `clash_mini_pitch.dart` (523), `clash_lineup_card_picker_sheet.dart` (384) | Refactors UI costosos; riesgo de regresiones visuales. |
| M8 | **`toProductGrants()` divergente** — daily solo 2 tipos; weekly/achievement completos | Misiones diarias no pueden otorgar evolution/ticket sin extender modelo. |
| M9 | **Carpeta `summon/`** con un solo screen — solapa con `gacha/` | Nomenclatura inconsistente (tab “Invocar” vs módulo `gacha`). |

### Prioridad baja

| # | Hallazgo | Impacto |
|---|---|---|
| B1 | **8 warnings analyze** corregibles (imports no usados — 7 resueltos en Fase 52) + 2 `unused_element` en `clash_mini_pitch.dart` | Ruido en CI; sin impacto funcional. |
| B2 | **14 info `no_leading_underscores_for_local_identifiers`** en tests | Estilo; no bloquea. |
| B3 | **1 info `use_build_context_synchronously`** en `clash_event_match_prepare_screen.dart` | Revisar en refactor UI; no crítico ahora. |
| B4 | **Contenido help en español fijo** en JSON | i18n del contenido pendiente para EN. |
| B5 | **Documentación duplicada** en `docs/` (rutas con `\` y `/` en algunos entornos) | Cosmética de repo. |

---

## Riesgos antes de backend

| Riesgo | Detalle | Mitigación recomendada |
|---|---|---|
| Sincronización local/remoto | Progreso en 15 SP keys vs estado servidor | Definir `ClashSyncState` + versión de esquema; operaciones idempotentes |
| Migración SharedPreferences | Sin `schemaVersion` global | Introducir migrador por backend o unificado |
| IDs estables | `cardId`, `levelId`, `eventId` solo en JSON | Publicar catálogo de IDs; contratos OpenAPI |
| Idempotencia de rewards | Grants locales sin `transactionId` | Clave de deduplicación por `source+rewardId+timestamp`; **sync server-side pendiente (post-Fase 53)** |
| Conflictos de progreso | First clear, pity, misiones pueden solaparse | Server wins / merge policy documentada |
| Auth/session | Clash asume usuario autenticado pero no valida en repos | Capa de sync post-login; no grant offline infinito |
| Wallet | Coins/gems solo locales | Endpoint de balance + reconciliación |
| Gacha pity/history | Estado local manipulable | Validación servidor en pull de banner |

---

## Riesgos antes de 11v11

| Riesgo | Detalle |
|---|---|
| Formación actual | Solo `ClashLineup7v7` con 7 posiciones oficiales; sin modelo 11 |
| `ClashLineupsRepository` | Persistencia y validación acoplada a 7 slots |
| Motor de partido | `clash_duel_engine.dart` asume plantilla 7v7 y zonas de campo actuales |
| UI alineación | `clash_lineup_7v7_screen.dart`, picker sheet — no escalan a 11 sin rediseño |
| Balance/IA | Rivales en `rivals.json` con plantillas 7; IA en `clash_rival_ai` atada a slots actuales |
| PT/resistencia | Sistema por jugador en partido; más jugadores = más carga UI (`clash_match_duel_panel` ya grande) |
| Objetivos de partido | Objetivos en story/events referencian formación 7v7 |
| Tests | Suite 7v7 extensa; duplicar para 11v7 multiplicará tests |

**Recomendación:** fase de diseño técnico 11v11 (modelo de formación genérico, enum de modo `sevenVsSeven | elevenVsEleven`) **antes** de implementar UI.

---

## Refactors recomendados

Lista priorizada y acotada (refactors seguros en fases futuras):

1. **`ClashLocalRewardGranter`** — **implementado (Fase 53)** en `shared/rewards/`; gifts, achievements, missions, events, shop y story (ítems) migrados; wallet de historia sigue en `copyWith` del progress.
2. **`ClashTypedRewardPreview`** en `shared/` — unificar `ClashStoryRewardPreview` + `ClashEventRewardPreview` + mapper a líneas legibles.
3. **`ClashRewardResultScreen`** genérica — sustituir `ClashStoryRewardScreen` y `ClashEventRewardScreen`.
4. **`ClashEngagementGrantMixin`** — extraer `_grantReward` común de missions/achievements/gifts.
5. **`ClashRewardPartsFormatter`** — unificar `_rewardParts()` de las cuatro cards de engagement.
6. **Mover `ClashStoryLevelStatusChip` → `shared/presentation/widgets/clash_status_chip.dart`** — renombrar y reexportar.
7. **`ClashDependencyModule`** — extraer registro de providers Clash de `main.dart` a `lib/features/clash/di/clash_providers.dart`.
8. **Dividir `ClashPlayerCollectionRepository`** — sub-repos: `CollectionCards`, `CollectionMaterials`, `CollectionXp` (interfaces internas).
9. **`clash_test_support.dart`** — dividir por dominio (`clash_match_test_support.dart`, `clash_engagement_test_support.dart`, etc.).
10. **Validación JSON** — helper común `parseClashJsonList<T>` con mensajes de error uniformes (opcional, bajo riesgo).

---

## Qué NO tocar ahora

- `features/leagues/**`, `features/rewards/**` (Fantasy).
- Backend / API Clash (inexistente).
- Reglas de partido (`clash_duel_engine.dart`, PT, duelos).
- Economía (precios, pity, tasas de gacha).
- Rutas públicas ya publicadas (`/clash/**`).
- Persistencia sin plan de migración.
- Refactors grandes en un solo PR.

---

## Plan recomendado próximas fases

| Fase | Objetivo | Tipo |
|---|---|---|
| **53** | Consolidar grant local (`ClashLocalRewardGranter` + story alineada) | **Implementada** |
| **54** | Widgets compartidos: preview tipado + status chip + pantalla post-reward | UI shared |
| **55** | Extraer `clash_providers.dart` de `main.dart` | Infra DI |
| **56** | Contratos de IDs y esquema de sync (doc + interfaces, sin API) | Pre-backend |
| **57** | Segundo evento/personaje en JSON (validar escalabilidad de events) | Contenido |
| **58** | Mejorar smoke/screenshots (flujos help, events, gacha) | Tooling |
| **59** | Diseño técnico 11v11 (modelo formación, impacto motor/UI) | Doc + spike |
| **60** | Migración SP v1 (`schemaVersion` + migrador vacío) | Pre-backend |

Orden flexible según prioridad de producto; **53–56** deberían preceder a cualquier API Clash.

---

## Referencias

- `docs/CLASH_IMPLEMENTATION_ROADMAP.md` — fases 1–52.
- `docs/CLASH_PRODUCT_DESIGN.md` — visión de producto.
- `docs/CLASH_INTEGRATION_ARCHITECTURE.md` — integración con Eternal XI.
- `docs/CLASH_CARD_SYSTEM.md`, `CLASH_MATCH_SYSTEM.md`, `CLASH_STORY_AND_EVENTS.md` — dominios.
- `docs/CLASH_MOBILE_SMOKE_TEST.md` — smoke manual/automático.

---

*Auditoría generada en Fase 52. No modifica comportamiento de la app.*
