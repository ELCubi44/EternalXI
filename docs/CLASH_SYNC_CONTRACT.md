# Contrato de sync Clash (Fase 65)

Contrato **frontend-only** para una futura sincronización backend de Clash. En esta fase no hay llamadas HTTP, endpoints reales ni migración de datos locales al servidor.

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
```

Ver también: [`CLASH_LOCAL_STORAGE.md`](./CLASH_LOCAL_STORAGE.md), [`CLASH_QA.md`](./CLASH_QA.md).
