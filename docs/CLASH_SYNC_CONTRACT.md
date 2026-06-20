# Contrato de sync Clash (Fase 65)

Contrato **frontend-only** para una futura sincronización backend de Clash. En esta fase no hay llamadas HTTP, endpoints reales ni migración de datos locales al servidor.

> **Fases 65–68** cubren contrato local, validación, fake client y coordinator — **sin HTTP Flutter**.  
> **Fase 70** implementa backend MVP. Ver [`CLASH_BACKEND_SAVE_CONTRACT.md`](./CLASH_BACKEND_SAVE_CONTRACT.md).
>
> **Fase 69** documenta el contrato backend de guardado online por usuario: [`CLASH_BACKEND_SAVE_CONTRACT.md`](./CLASH_BACKEND_SAVE_CONTRACT.md).

## Objetivo

- Definir DTOs serializables (`ClashSyncSnapshot`) que representen el estado local Clash listo para enviar/recibir en sync futura.
- Separar la **versión del contrato API** de la **versión del schema local** (`SharedPreferences`).
- Documentar endpoints, idempotencia y resolución de conflictos **solo como diseño**; la implementación server-side queda pendiente.

Código: `lib/features/clash/sync/`.

## contractVersion vs schemaVersion

| Concepto | Dónde vive | Valor actual | Propósito |
|----------|------------|--------------|-----------|
| **Sync contract version** | `ClashSyncContractVersion.current` | `1` | Evolución del payload JSON del contrato API (`GET/PUT /api/v1/clash/sync`). El backend puede rechazar contratos desconocidos. |
| **Local schema version** | `clash_schema_version` / `ClashStorageSchema.currentVersion` | `1` | Migraciones de `SharedPreferences`. Indica qué transformaciones locales ya se aplicaron. |

Son independientes: una app puede estar en schema local `1` y enviar snapshots con `contractVersion: 1`. Una futura Fase podría subir `contractVersion` sin tocar el schema SP, o viceversa.

## Snapshot principal

`ClashSyncSnapshot` incluye:

| Campo | Descripción |
|-------|-------------|
| `contractVersion` | Versión del contrato sync (default `1`) |
| `generatedAt` | ISO-8601 UTC de generación del snapshot |
| `schemaVersion` | Copia de la versión local SP al generar |
| `lastMigratedAt` | Opcional; última migración local |
| `deviceInfo` | Opcional; `deviceId`, `platform` |
| `wallet` | Monedas y gemas |
| `collection` | IDs de cartas y contadores agregados |
| `inventories` | EXP, libros, evolución, tickets |
| `lineups` | Resumen de alineaciones 7v7 |
| `storyProgress` | Niveles completados, flags de desbloqueo |
| `characterEventsProgress` | Stages completados y repeticiones |
| `missionsProgress` | Claves daily/weekly activas |
| `achievementsProgress` | Logros reclamados |
| `giftsProgress` | Regalos reclamados |
| `gachaState` | Pity, daily por banner, conteo de historial |
| `rewardHistorySummary` | **Solo resumen** (counts), no entradas completas |

Builder: `ClashSyncSnapshotBuilder` — lectura de storages inyectables, sin red ni mutación.

## Validación local del snapshot (Fase 66)

`ClashSyncSnapshotValidator` valida un `ClashSyncSnapshot` **antes** de una futura sync, sin reparar datos ni usar red.

Resultado: `ClashSyncValidationResult` (`isValid`, `errors`, `warnings`, `checkedAt`, `hasErrors`, `hasWarnings`).

Cada issue: `ClashSyncValidationIssue` (`code`, `message`, `path`, `severity`: error | warning).

### Checks actuales

| Área | Errores (estructura) | Con catálogo inyectado |
|------|----------------------|-------------------------|
| Contrato | `contractVersion == 1`, `schemaVersion >= 1` | — |
| Wallet | `coins`, `gems` >= 0 | — |
| Inventarios | cantidades >= 0, IDs no vacíos | IDs en catálogos de materiales/tickets |
| Colección | `duplicateCopies` >= 0, `uniqueCount` coherente, IDs no vacíos | `knownCardIds` |
| Lineups | contadores >= 0, `activeLineupId` no vacío | `lineupSlotsByLineupId` + cartas conocidas/propias |
| Historia | IDs de nivel/recompensa no vacíos | — |
| Eventos | stage IDs no vacíos, `clearCounts` >= 0 | `knownEventStageIdsByEvent` |
| Misiones | progreso >= 0, IDs no vacíos | `knownMissionIds` |
| Logros / regalos | IDs no vacíos | `knownAchievementIds`, `knownGiftIds` |
| Gacha | pity/history >= 0, `bannerId` no vacío | `knownBannerIds` |
| Reward history | counts >= 0, partial/failure <= entryCount | — |

Catálogos opcionales (`ClashSyncSnapshotValidatorCatalogs`): `knownCardIds`, `knownEventIds`, `knownEventStageIdsByEvent`, `knownMissionIds`, `knownAchievementIds`, `knownGiftIds`, `knownBannerIds`, `knownRewardItemIds`, `knownExpMaterialIds`, `knownTechniqueBookIds`, `knownEvolutionMaterialIds`, `knownTicketIds`, `lineupSlotsByLineupId`.

Sin catálogos: no falla por IDs desconocidos; emite **warnings** cuando hay datos que no pudieron verificarse.

Código: `lib/features/clash/sync/data/clash_sync_snapshot_validator.dart`.

## Cliente fake de sync (Fase 67)

Interfaz `ClashSyncClient` (`pushSnapshot`, `pullSnapshot`) sin HTTP. Implementación de prueba: `FakeClashSyncClient` — almacena snapshot remoto **en memoria**.

| Operación | Comportamiento fake |
|-----------|---------------------|
| `pullSnapshot` | `notFound` si no hay snapshot remoto; `success` + `serverRevision` si existe |
| `pushSnapshot` | Valida con `ClashSyncSnapshotValidator`; `validationFailed` si inválido (no pisa remoto) |
| | `rejected` si `contractVersion` no soportada |
| | `conflict` si `expectedServerRevision` ≠ revisión remota actual |
| | `success` e incrementa `serverRevision` (1, 2, …) |
| | `unavailable` si el fake está deshabilitado (`available = false`) |

Resultados tipados: `ClashSyncPushResult`, `ClashSyncPullResult`, `ClashSyncConflict`, `ClashSyncStatus`.

**No** registrado en providers de la app, **no** sync automática, **no** red ni persistencia SP del snapshot remoto.

Código: `lib/features/clash/sync/data/clash_sync_client.dart`, `fake_clash_sync_client.dart`.

## Cliente HTTP de sync (Fase 71)

`HttpClashSyncClient` implementa [ClashSyncClient] contra `/api/v1/clash/save` vía `ClashSaveApiClient` (Dio + JWT del `ApiClient` existente).

| Operación sync | HTTP |
|----------------|------|
| `pullSnapshot()` | GET save — 404 → `notFound` |
| `pushSnapshot` sin `expectedServerRevision` | POST create |
| `pushSnapshot` con `expectedServerRevision` | PUT update — 409 → `conflict` |

Errores tipados: `ClashSaveApiException`, `ClashSaveConflictException`, `ClashSaveNotFoundException`.

**No** sync automática al arrancar. Pull remoto **no** se aplica automáticamente (Fase 72–73: diagnóstico manual).

### Aplicación manual remota (Fase 73)

Tras un pull exitoso, el usuario puede **Aplicar partida online a este dispositivo** con confirmación explícita.

Flujo `ClashSyncSnapshotApplier.applyRemoteSnapshot()`:

1. Validar snapshot remoto (`ClashSyncSnapshotValidator`).
2. Crear backup local (`clash_last_local_backup_v1`) con snapshot actual.
3. Escribir secciones aplicables en storages locales.

| Sección | Aplicación Fase 73 |
|---------|-------------------|
| wallet, story, inventarios, misiones, logros, regalos, eventos, gacha pity/daily | Sí |
| collection | Solo `ownedCardIds` (progreso por carta parcial: conserva local o default) |
| lineups | **Omitida** (contrato v1 solo resumen) |
| gacha history / reward history | Solo limpia local si remoto indica `entryCount == 0`; si remoto tiene entradas, **omite** (no restaura entradas) |

Sin merge, sin restauración automática si falla la escritura (backup disponible para recuperación manual futura).

Código: `clash_sync_snapshot_applier.dart`, `clash_debug_sync_controller.dart`.

## Diagnóstico manual de sync (Fase 72–79)

`ClashDebugSyncController` + sección **Sincronización online** en `/clash/debug`.

| Acción | Comportamiento |
|--------|----------------|
| Preparar partida online | `bootstrapOnlineSave()` — GET remoto; si existe guarda pending + metadata; si notFound valida local y POST create; **no** aplica remoto |
| Validar snapshot local | `validateLocalSnapshotOnly()` |
| Descargar partida online | `pullRemoteSnapshot()` — guarda en memoria, **no aplica a SP** |
| Subir partida local actual | `executePushLocal()` — valida local; POST si no hay remoto; PUT con `expectedServerRevision` si hay revisión conocida; 409 → conflicto sin reintento |
| Aplicar partida online | Confirmación → `ClashSyncSnapshotApplier` — backup + escritura local |

### Indicador informativo (Fase 78)

`ClashSyncStatusBadge` en Clash Home lee `clash_sync_metadata_v1` vía `ClashSyncMetadataStorage.load()`.

Estados: sin preparar online, sincronizado, pendiente local, conflicto, error, backup disponible.

- **Solo lectura** de metadata local.
- Tap → `/clash/debug`.
- **Sin** HTTP, sync, push, pull, apply ni bootstrap automático.

### Auto-check remoto opcional (Fase 79)

Ajuste `clash_sync_auto_check_enabled_v1` (default **false**), toggle en diagnóstico.

| Comportamiento | Detalle |
|----------------|---------|
| Flag off | `ClashSyncAutoCheckService.runIfEnabled()` → `null`, sin HTTP |
| Flag on + abrir Clash Home | GET/pull remoto, throttling 5 min desde `lastPullAt` |
| Success | Metadata: `knownServerRevision`, `hasPendingRemoteSnapshot=true`, `lastPullAt` |
| notFound | Metadata actualizada, **no** POST create |
| 401/conflict/unavailable | Metadata/error persistido |

**Prohibido en auto-check:** apply, push, create, bootstrap.

### Aviso partida online pendiente (Fase 80)

Cuando `hasPendingRemoteSnapshot == true` y existe `knownServerRevision`, Clash Home muestra un aviso informativo compacto (`ClashPendingSyncNotice`).

| Comportamiento | Detalle |
|----------------|---------|
| Mostrar | `hasPendingRemoteSnapshot` y `knownServerRevision != dismissedRevision` |
| Ocultar temporalmente | Cerrar aviso → guarda `clash_sync_pending_notice_dismissed_revision_v1` |
| Reaparecer | Si `knownServerRevision` cambia respecto a la revision ocultada |
| Revisar | Navega a `/clash/debug` |

**Prohibido en el aviso:** HTTP, apply, push, merge, modificar metadata al ocultar.

Código: `clash_pending_sync_notice.dart`, `ClashSyncSettingsStorage.dismissPendingRevision`.

### Claims idempotentes backend (Fase 81)

`POST /api/v1/clash/claims` — registro idempotente por `(usuario autenticado, claimId)`.

| Comportamiento | Detalle |
|----------------|---------|
| Nuevo claim | HTTP 201, `status=ACCEPTED`, `alreadyProcessed=false` |
| Repetido | HTTP 200, `alreadyProcessed=true`, respuesta desde `response_json` |
| Auth | `userId` solo desde JWT, nunca desde body |
| Economía | **No** concede rewards ni modifica `clash_save` en esta fase |

Tabla: `clash_claim`. Código: `ClashClaimController`, `ClashClaimService`.

Código: `ClashSyncAutoCheckService`, integración en `ClashHomeScreen`.

Estado visible en diagnóstico (memoria + metadata persistida en `clash_sync_metadata_v1`):

- `knownServerRevision` (server revision conocida)
- snapshot remoto pendiente (flag en metadata; snapshot completo solo en memoria de sesión)
- backup local disponible (`ClashSyncLocalBackupStore` + flag metadata)
- último resultado por operación: validate / pull / apply / restore / push
- último sync correcto, estado persistido y último error

Al abrir debug tras reiniciar la app se **carga metadata local** (sin HTTP). La revision y el último estado persistido se muestran aunque la sesión actual no haya ejecutado operaciones.

Subida manual: confirmación explícita si ya existe partida remota. Bootstrap **no** se ejecuta al abrir debug (solo botón). **No** sube automáticamente tras apply/restore. **No** sync automática al abrir debug.

Código: `clash_save_api_client.dart`, `http_clash_sync_client.dart`, `clash_providers.dart`, `clash_sync_snapshot_applier.dart`, `clash_sync_metadata_storage.dart`, `clash_debug_sync_controller.dart`.

## Coordinador local de sync (Fase 68)

`ClashSyncCoordinator` orquesta el flujo build → validate → push/pull usando:

- `ClashSyncSnapshotBuilder`
- `ClashSyncSnapshotValidator`
- `ClashSyncClient`

| Método | Flujo |
|--------|-------|
| `validateLocalSnapshotOnly()` | build → validate; **no** llama al client |
| `pushLocalSnapshot({expectedServerRevision})` | build → validate → si inválido **no** llama al client → si válido `client.pushSnapshot` |
| `pullRemoteSnapshot()` | `client.pullSnapshot` → valida snapshot remoto si existe → **no aplica** datos locales |

Resultado: `ClashSyncOperationResult` (`operation`: validate/push/pull, `status`, `snapshot`, `validationResult`, `serverRevision`, `conflict`, timestamps inyectables).

**Importante:** el coordinador **no aplica** snapshots remotos sobre SharedPreferences ni storages locales. Solo reporta estados tipados para pruebas y futura integración.

**No** registrado en providers reales, **no** sync automática al arrancar, **no** UI.

Código: `lib/features/clash/sync/data/clash_sync_coordinator.dart`.

## Ejemplo JSON

```json
{
  "contractVersion": 1,
  "generatedAt": "2026-06-20T12:00:00.000Z",
  "schemaVersion": 1,
  "lastMigratedAt": "2026-06-11T10:00:00.000Z",
  "deviceInfo": {
    "deviceId": "device-abc",
    "platform": "android"
  },
  "wallet": { "coins": 1500, "gems": 12 },
  "collection": {
    "ownedCardIds": ["card-a", "card-b"],
    "uniqueCount": 2,
    "totalCopies": 3,
    "duplicateCopies": 1
  },
  "inventories": {
    "expMaterials": { "basic-training-manual": 9 },
    "techniqueBooks": {},
    "evolutionMaterials": {},
    "tickets": { "starter-single-ticket": 5 }
  },
  "lineups": {
    "lineupCount": 1,
    "activeLineupId": "lineup-1",
    "completeLineupCount": 0
  },
  "storyProgress": {
    "completedLevelIds": ["prologue-lvl-01"],
    "clashTeamUnlocked": true
  },
  "characterEventsProgress": {
    "completedStageIds": ["event-mika-stage-01"],
    "clearCounts": { "event-mika-stage-01": 2 }
  },
  "missionsProgress": {
    "dailyLocalDate": "2026-06-20",
    "weeklyWeekKey": "2026-W25"
  },
  "achievementsProgress": {
    "claimedAchievementIds": ["ach-first-match"]
  },
  "giftsProgress": {
    "claimedGiftIds": ["gift-welcome"]
  },
  "gachaState": {
    "historyEntryCount": 1,
    "pityByBanner": [
      {
        "bannerId": "starter-banner-001",
        "pullsSinceLastPity": 12,
        "totalPulls": 40
      }
    ],
    "dailyLastUsedByBanner": { "starter-banner-001": "2026-06-20" }
  },
  "rewardHistorySummary": {
    "entryCount": 1,
    "latestEntryAt": "2026-06-11T10:00:00.000Z",
    "partialCount": 1,
    "failureCount": 0
  }
}
```

## Endpoints futuros (documentados, no implementados)

| Método | Ruta | Uso previsto |
|--------|------|--------------|
| `GET` | `/api/v1/clash/sync` | Obtener snapshot autoritativo del servidor + `serverRevision` |
| `PUT` | `/api/v1/clash/sync` | Enviar snapshot local; servidor valida, fusiona o rechaza |
| `POST` | `/api/v1/clash/rewards/claim` | Claim idempotente de recompensa (shop, firstClear, repeat, etc.) |

Ninguno de estos endpoints está conectado en Fase 65.

## Idempotencia futura

Campos previstos en claims y sync (backend):

- **`claimId`**: UUID o clave derivada (`source` + `rewardId` + contexto) para deduplicar grants.
- **`deviceId`**: Identificador estable del dispositivo (`ClashSyncDeviceInfo.deviceId`).
- **`serverRevision`**: Contador monótono del estado Clash en servidor; el cliente envía la revisión que conoce en `PUT`.

El cliente local ya registra historial de rewards; el resumen en snapshot prepara auditoría sin exponer todas las entradas.

## Conflictos futuros (estrategia propuesta)

| Dominio | Estrategia |
|---------|------------|
| Economía (wallet, tickets, materiales consumibles) | **Server wins** — evita duplicación de moneda/items |
| Colección / historial / progreso no económico | **Merge** cuando sea seguro (unión de IDs completados, max de contadores idempotentes) |
| Gacha pity / daily | **Server wins** con validación de pulls registrados |
| Claims pendientes | Reintentar con mismo `claimId`; servidor responde resultado cacheado |

Resolución real, borrado remoto/local y sync automática **no están implementados**.

## Campos pendientes / no incluidos en Fase 65

- Detalle completo de `rewardHistory` (solo summary).
- Slots completos de lineups (solo resumen).
- Progreso por carta (EXP, nivel, evolución) — ampliable en `contractVersion` 2.
- Noticias leídas (`clash_news_read_v1`).
- Energía / cooldowns de partido si se externalizan al servidor.
- `serverRevision`, `claimId` en payload — reservados para backend.
- Login Clash separado, sync en background, migración bulk local→servidor.

## Tests

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_sync_snapshot_test.dart
flutter test test/features/clash/sync/clash_sync_snapshot_validator_test.dart
flutter test test/features/clash/sync/fake_clash_sync_client_test.dart
flutter test test/features/clash/sync/clash_sync_coordinator_test.dart
flutter test test/features/clash/sync/clash_backend_save_contract_test.dart
flutter test test/features/clash/sync/clash_save_api_client_test.dart
flutter test test/features/clash/sync/http_clash_sync_client_test.dart
```

Ver también: [`CLASH_BACKEND_SAVE_CONTRACT.md`](./CLASH_BACKEND_SAVE_CONTRACT.md), [`CLASH_LOCAL_STORAGE.md`](./CLASH_LOCAL_STORAGE.md), [`CLASH_QA.md`](./CLASH_QA.md).
