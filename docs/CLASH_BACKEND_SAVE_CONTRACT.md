# Contrato backend — guardado online Clash (Fase 69 / MVP Fase 70)

Contrato para persistir la partida Clash en el servidor Eternal XI, vinculada al usuario autenticado.

> **Fase 69:** contrato documentado + DTOs frontend.  
> **Fase 70:** MVP backend Spring Boot implementado (`GET/POST/PUT /api/v1/clash/save`).  
> **Fase 71:** cliente HTTP Flutter (`ClashSaveApiClient`, `HttpClashSyncClient`) — **sin sync automática**.

Relacionado con el trabajo frontend/local de las Fases 65–68: [`CLASH_SYNC_CONTRACT.md`](./CLASH_SYNC_CONTRACT.md).

---

## Implementación backend (Fase 70)

| Componente | Ruta |
|------------|------|
| Migración SQL | `eternalxi_api_back/src/main/resources/db/migration/V20260613170000__clash_save.sql` |
| Modelo | `model/ClashSave.java` |
| Repository JDBC | `repository/ClashSaveRepository.java` |
| Service | `services/ClashSaveService.java` |
| Controller | `controller/clash/ClashSaveController.java` |
| DTOs | `dto/clash/ClashSave*.java` |
| Tests | `services/ClashSaveServiceTest.java` |

Auth: `AuthenticatedUser.requireUserId()` — **no** se acepta `userId` en el body.

Boot: `SchemaMigrationService` crea `clash_save` si falta (dev/prod sin Flyway).

## Cliente Flutter HTTP (Fase 71)

| Componente | Ruta |
|------------|------|
| API client | `lib/features/clash/sync/data/clash_save_api_client.dart` |
| Sync adapter | `lib/features/clash/sync/data/http_clash_sync_client.dart` |
| Excepciones | `lib/features/clash/sync/domain/clash_save_api_exception.dart` |

- Usa `ApiClient` / Dio existente (JWT automático).
- **No** envía `userId` en body.
- **No** registrado en providers; **no** sync automática al abrir app.

---

## Principio: partida por usuario autenticado

- Cada usuario de Eternal XI tiene **como máximo una** partida Clash online (`clash_save.user_id` UNIQUE).
- El backend identifica al usuario mediante el **auth actual** (JWT/sesión del API existente).
- **No** se envía `userId` desde Flutter como autoridad: el servidor resuelve `user_id` desde el token.
- Flutter puede incluir `deviceId` dentro del snapshot (`ClashSyncDeviceInfo`) solo como metadata, no como clave de guardado.

---

## Versionado

| Campo | Origen | Propósito |
|-------|--------|-----------|
| `contractVersion` | Cliente + servidor | Formato del JSON de `save_data` (`ClashSyncContractVersion.current = 1`) |
| `schemaVersion` | Cliente (copia SP local) | Información de migraciones locales al generar el snapshot |
| `serverRevision` | **Solo servidor** | Contador monótono por guardado; optimistic concurrency en `PUT` |

El cliente conoce `local schemaVersion` y `sync contractVersion`. El servidor es la fuente de verdad de `serverRevision`.

---

## Modelo MVP recomendado

Tabla sugerida: **`clash_save`**

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | BIGINT PK | Identificador interno |
| `user_id` | BIGINT UNIQUE NOT NULL | Columna real: `id_usuario` |
| `contract_version` | INT NOT NULL | p. ej. `1` |
| `schema_version` | INT NOT NULL | último schema reportado por cliente |
| `server_revision` | INT NOT NULL | >= 1, incrementa en cada `PUT` aceptado |
| `save_data_json` | JSON/TEXT NOT NULL | snapshot `ClashSyncSnapshot` serializado |
| `created_at` | TIMESTAMP | Primera creación |
| `updated_at` | TIMESTAMP | Última actualización exitosa |
| `last_sync_at` | TIMESTAMP NULL | Último sync completado (opcional) |

**Restricciones**

- `user_id` UNIQUE — una partida Clash por usuario.
- `server_revision >= 1`.
- `save_data_json` NOT NULL.

### Por qué JSON versionado en MVP

- Entrega más rápida alineada con `ClashSyncSnapshot` ya definido en Flutter.
- Clash evoluciona con frecuencia; el blob JSON absorbe cambios sin migraciones SQL por campo.
- Permite normalizar a tablas relacionales en una fase posterior cuando el dominio se estabilice.

---

## Endpoints (implementados Fase 70)

Base: `/api/v1/clash/save` — requiere JWT (usuario autenticado).

### `GET /api/v1/clash/save`

Devuelve la partida online del usuario autenticado.

| Respuesta | Descripción |
|-----------|-------------|
| `200` + `ClashSaveResponse` | Partida existente |
| `404` | Sin partida (decisión backend: no auto-crear en GET) |

Alternativa documentada: `404` vs crear vacía en GET — **recomendación MVP:** `404` en GET; creación explícita vía `POST`.

### `POST /api/v1/clash/save`

Crea la partida inicial si no existe para el usuario.

| Respuesta | Descripción |
|-----------|-------------|
| `201` + `ClashSaveResponse` | Creada (`serverRevision = 1`) |
| `409` | Ya existe partida (`CLASH_SAVE_ALREADY_EXISTS`) |

Body: snapshot inicial (`ClashSaveUpdateRequest` sin `expectedServerRevision` o con `expectedServerRevision = 0` según convención backend).

### `PUT /api/v1/clash/save`

Actualiza el snapshot completo.

| Requisito | Descripción |
|-----------|-------------|
| `expectedServerRevision` | Debe coincidir con revisión actual del servidor |
| `saveData` | Snapshot completo validado server-side |
| `contractVersion` | Debe ser soportada |

| Respuesta | Descripción |
|-----------|-------------|
| `200` + `ClashSaveResponse` | Aceptado; `serverRevision` incrementado |
| `409` + `ClashSaveConflictResponse` | Conflicto de revisión |
| `400` | Validación fallida (economía, contrato, etc.) |
| `422` | `contractVersion` no soportada |

### `POST /api/v1/clash/claims` (futuro)

Claim server-side idempotente. Body: `ClashSaveClaimRequest`.

| Respuesta | Descripción |
|-----------|-------------|
| `200` | Grant aplicado o ya procesado (mismo `claimId`) |
| `409` | Conflicto de revisión si se exige `expectedServerRevision` |
| `400` | Claim inválido o no permitido |

### Opcionales futuros

- `GET /api/v1/clash/save/status` — metadata ligera (`serverRevision`, `updatedAt`) sin payload completo.
- `POST /api/v1/clash/save/merge-preview` — diff/merge propuesto sin persistir.

---

## DTOs (ejemplos JSON)

### `ClashSaveResponse`

```json
{
  "serverRevision": 3,
  "contractVersion": 1,
  "schemaVersion": 1,
  "saveData": {
    "contractVersion": 1,
    "generatedAt": "2026-06-20T12:00:00.000Z",
    "schemaVersion": 1,
    "wallet": { "coins": 1500, "gems": 12 },
    "collection": { "ownedCardIds": ["card-a"], "uniqueCount": 1, "totalCopies": 1, "duplicateCopies": 0 }
  },
  "updatedAt": "2026-06-20T14:30:00.000Z"
}
```

DTO frontend: `ClashSaveResponse` en `lib/features/clash/sync/domain/clash_save_contract.dart`.

### `ClashSaveUpdateRequest`

```json
{
  "expectedServerRevision": 2,
  "contractVersion": 1,
  "schemaVersion": 1,
  "clientGeneratedAt": "2026-06-20T14:29:55.000Z",
  "saveData": { "...": "ClashSyncSnapshot completo" }
}
```

### `ClashSaveConflictResponse` (HTTP 409)

```json
{
  "serverRevision": 3,
  "serverSaveData": { "...": "snapshot autoritativo del servidor" },
  "clientRejectedReason": "expectedServerRevision 2 != current 3"
}
```

### `ClashSaveClaimRequest` (futuro)

```json
{
  "claimId": "gift:gift-welcome",
  "claimType": "gift",
  "sourceId": "gift-welcome",
  "stageId": null,
  "expectedServerRevision": 3
}
```

---

## Estrategia de autoridad

### Servidor (autoridad final)

- Monedas / gemas
- Gacha (pulls, pity, tickets consumidos)
- Claims únicos (regalos, logros, firstClear, shop)
- Recompensas de eventos, historia, misiones
- `serverRevision`

### Cliente (caché / offline temporal)

- `SharedPreferences` local (Fase 56+)
- Visualización y UX offline-first
- Cola de progreso pendiente de sync (fase futura)

### Regla crítica

Cuando exista backend real, **los claims sensibles deben validarse en servidor**. Un snapshot local manipulado **no** debe poder otorgar gemas ni items premium sin validación server-side.

Flujo recomendado MVP+:

1. Gameplay local offline permitido con límites documentados.
2. Sync de snapshot vía `PUT` con validación server-side de economía.
3. Claims de alto valor vía `POST /api/v1/clash/claims` con `claimId` idempotente.

---

## Conflictos (estrategia inicial)

| Condición | Comportamiento |
|-----------|----------------|
| `expectedServerRevision` == revisión actual | Aceptar `PUT`, `serverRevision + 1` |
| `expectedServerRevision` != revisión actual | `409 Conflict` + `ClashSaveConflictResponse` |
| Cliente Flutter | **No** pisa remoto automáticamente (Fase 68: coordinator no aplica remoto) |

### Reglas futuras de merge

| Dominio | Estrategia |
|---------|------------|
| Economía sensible | **Server wins** |
| Historial / reward log | Merge append-only |
| Colección / progreso completado | Unión controlada con validación server |

---

## Idempotencia de claims

El backend registra `claimId` procesados (tabla `clash_processed_claim` sugerida en fase posterior).

### Formato sugerido de `claimId`

| Tipo | Formato |
|------|---------|
| Regalo | `gift:{giftId}` |
| Logro | `achievement:{achievementId}` |
| Misión diaria | `mission:daily:{missionId}:{date}` |
| Misión semanal | `mission:weekly:{missionId}:{weekKey}` |
| First clear evento | `event:{eventId}:{stageId}:firstClear` |
| Repeat evento | `event:{eventId}:{stageId}:repeat:{clientAttemptId}` |
| Tienda | `shop:{productId}:{clientAttemptId}` |

Reintento con el mismo `claimId` → respuesta idempotente (mismo grant, sin duplicar economía).

---

## Estrategia local / offline / caché

```
┌─────────────┐     build/validate      ┌──────────────────┐
│ SharedPrefs │ ◄────────────────────── │ ClashSyncCoordinator │
│  (local)    │                         └────────┬─────────┘
└─────────────┘                                  │
       ▲                                         │ PUT/GET (futuro)
       │ apply (fase futura)                      ▼
       │                                  ┌──────────────────┐
       └──────────────────────────────────│  clash_save API  │
                                          │  (por user_id)   │
                                          └──────────────────┘
```

- **Hoy (Fases 65–68):** solo local + fake client en memoria.
- **Fase 69+ backend:** HTTP client implementará `ClashSyncClient` contra `/api/v1/clash/save`.
- **Offline:** cliente sigue jugando con SP; al reconectar, `pushLocalSnapshot(expectedRevision)` o resolución manual tras `409`.

---

## Pendiente / fuera de alcance

- Sync automática al abrir app
- `POST /api/v1/clash/claims` server-side
- Aplicación de snapshot remoto sobre SharedPreferences
- Normalización en tablas relacionales
- Validación economía/gacha server-side completa

---

## Tests frontend de contrato

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_backend_save_contract_test.dart
```

Backend (service MVP):

```bash
cd eternalxi_api_back
mvn test -Dtest=ClashSaveServiceTest
```

Serialización de DTOs en `clash_save_contract.dart` — sin HTTP.

Ver también: [`CLASH_QA.md`](./CLASH_QA.md), [`CLASH_SYNC_CONTRACT.md`](./CLASH_SYNC_CONTRACT.md).
