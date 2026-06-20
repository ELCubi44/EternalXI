# QA automatizada Clash

Comandos para validar Clash en local sin dispositivo ni backend remoto.

## Smoke test (rápido)

Valida los flujos locales principales: home, historia, eventos, regalos, tienda, inventario, historial de recompensas y diagnóstico.

```bash
cd eternalxi_front
flutter test test/features/clash/smoke/clash_local_smoke_test.dart
```

**Cuándo usarlo:** antes de commit/push de cambios Clash, tras refactors de navegación o providers, o como comprobación rápida de regresión UI local.

## Responsive / anti-overflow (Fase 63)

Valida que pantallas clave renderizan sin overflows de layout en viewports móviles pequeños y medianos.

```bash
cd eternalxi_front
flutter test test/features/clash/responsive/clash_responsive_test.dart
```

**Viewports:** 360×640 (small), 390×844 (medium), 430×932 (tall).

**Pantallas:** home, story (mapa + reward), events (lista, detalle Mika, preparación stage), gifts, misiones daily/weekly, achievements, shop (+ diálogo compra), inventory, reward history (vacío/con entrada), debug, help.

**Cuándo usarlo:** tras cambios de layout en pantallas Clash, antes de cerrar una fase con muchas pantallas densas, o cuando sospeches roturas en móviles estrechos. Complementa el smoke: el smoke valida flujos; el responsive valida constraints y overflows.

## Compatibilidad storage (Fase 64)

Valida que payloads SharedPreferences antiguos siguen cargando en los backends actuales (colección, inventarios, misiones, gacha, story, reward history, etc.).

```bash
cd eternalxi_front
flutter test test/features/clash/storage/clash_local_storage_compatibility_test.dart
```

**Cuándo usarlo:** tras cambios en parsing/storage Clash, al añadir campos a snapshots persistidos, o antes de migraciones de schema. Complementa smoke (flujos) y responsive (layout).

## Sync contract (Fase 65)

Valida DTOs de sync frontend (`ClashSyncSnapshot`), serialización JSON y builder desde storages mock — sin red.

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_sync_snapshot_test.dart
```

**Cuándo usarlo:** tras cambiar DTOs sync, el builder o campos del contrato documentado en [`CLASH_SYNC_CONTRACT.md`](./CLASH_SYNC_CONTRACT.md).

## Sync snapshot validator (Fase 66)

Valida inconsistencias estructurales e IDs contra catálogos opcionales (`ClashSyncSnapshotValidator`).

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_sync_snapshot_validator_test.dart
```

**Cuándo usarlo:** tras añadir checks al validador, cambiar reglas de coherencia del snapshot o antes de conectar sync backend.

## Fake sync client (Fase 67)

Simula push/pull de snapshot y `serverRevision` en memoria, sin red.

```bash
cd eternalxi_front
flutter test test/features/clash/sync/fake_clash_sync_client_test.dart
```

**Cuándo usarlo:** al probar flujos sync locales, conflictos de revisión o integración builder → validator → fake client antes del backend real.

## Sync coordinator (Fase 68)

Orquesta build → validate → push/pull sin aplicar datos remotos ni red.

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_sync_coordinator_test.dart
```

**Cuándo usarlo:** al cambiar el flujo de operaciones sync o antes de integrar aplicación de snapshots remotos (fase futura).

## Backend save contract (Fase 69)

DTOs de guardado online documentados (`ClashSaveResponse`, `ClashSaveUpdateRequest`, etc.) — serialización frontend, **sin HTTP ni backend real**.

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_backend_save_contract_test.dart
```

**Nota:** backend MVP disponible (`GET/POST/PUT /api/v1/clash/save`). Cliente HTTP Flutter creado (Fase 71) — **sin sync automática** ni tests E2E contra servidor real. Ver [`CLASH_BACKEND_SAVE_CONTRACT.md`](./CLASH_BACKEND_SAVE_CONTRACT.md).

## Prueba manual sync online (Fase 72–79)

En dispositivo con usuario logueado:

1. Abrir **Clash → Ayuda → Diagnóstico local**.
2. Sección **Sincronización online** — revisar revision conocida, remoto pendiente, backup local y **estado persistido**.
3. Pulsar **Preparar partida online** — debe encontrar save remoto o crear uno desde local.
4. Probar **Validar snapshot local**, **Descargar partida online**, **Subir partida local actual**.
5. Si ya existe partida remota, confirmar diálogo antes de subir.
6. Tras descarga exitosa: **Aplicar partida online a este dispositivo** → confirmar diálogo.
7. **Verificar persistencia:** cerrar y reabrir la app → en diagnóstico debe mostrarse la `serverRevision` conocida y el último estado desde `clash_sync_metadata_v1` (sin llamadas HTTP automáticas).
8. Volver a **Clash Home** — el badge debe reflejar metadata (sin llamar backend al abrir Home con flag off).
9. En diagnóstico, activar **Comprobar partida online al abrir Clash** → reabrir Home → debe hacer GET (pull) sin apply ni push. Desactivar toggle para volver al comportamiento seguro.
10. Con `hasPendingRemoteSnapshot` en metadata, Home muestra aviso **Partida online disponible**. Pulsar **Revisar** → diagnóstico. Cerrar (X) oculta el aviso sin borrar metadata; si la revision remota cambia, el aviso reaparece.

El pull **no** modifica el almacenamiento local hasta confirmar aplicar. La subida **no** ocurre automáticamente tras apply/restore. Se crea backup en `clash_last_local_backup_v1`. Auto-check **no** aplica remoto ni crea save. El aviso **no** hace HTTP ni apply.

**Verificar que el badge/auto-check/aviso no llama push:** con flag off, abrir Home sin red; con flag on, pull solo GET; aviso solo lee metadata local.

**Tests Fase 79:** settings default, toggle, auto-check service, Home off/on, throttling.

**Tests Fase 80:** pending notice visibility, dismiss revision, Review navigation, Home no HTTP, smallPhone overflow.

**Tests Fase 81 (backend claims):**

```bash
cd eternalxi_api_back
mvn test -Dtest=ClashClaimServiceTest,ClashSaveServiceTest
```

**Tests Fase 82 (Flutter claim client):**

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_claim_contract_test.dart
flutter test test/features/clash/sync/clash_claim_api_client_test.dart
```

Manual (con token JWT):

1. `POST /api/v1/clash/claims` con body válido → `201`, `alreadyProcessed=false`.
2. Repetir mismo `claimId` → `200`, `alreadyProcessed=true`, mismo `message`.
3. Otro usuario con mismo `claimId` → `201` independiente.
4. Body sin `claimId` → `400`.
5. Verificar que `clash_save` no cambia tras claims.

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_sync_settings_storage_test.dart
flutter test test/features/clash/sync/clash_sync_auto_check_service_test.dart
flutter test test/features/clash/sync/clash_sync_status_badge_test.dart
flutter test test/features/clash/sync/clash_pending_sync_notice_test.dart
flutter test test/features/clash/debug/clash_debug_sync_controller_test.dart
```

## Flutter save API client (Fase 71)

```bash
cd eternalxi_front
flutter test test/features/clash/sync/clash_save_api_client_test.dart
flutter test test/features/clash/sync/http_clash_sync_client_test.dart
```

**Cuándo usarlo:** tras cambiar parseo HTTP, rutas o adaptador `HttpClashSyncClient`.

## Suite completa Clash

```bash
cd eternalxi_front
flutter test test/features/clash/
```

**Cuándo usarla:** antes de cerrar una fase del roadmap, tras cambios en economía local, storage, migraciones o pantallas con mucha cobertura de tests.

### Resumen: smoke vs responsive vs compatibility vs suite completa

| Comando | Duración | Qué detecta |
|---------|----------|-------------|
| Smoke | ~10 s | Flujos locales principales renderizan y no lanzan errores Flutter |
| Responsive | ~10 s | Overflows RenderFlex, constraints rotos en viewports móviles |
| Compatibility | ~5 s | Payloads SharedPreferences legacy cargan sin romper parsing |
| Sync contract | ~5 s | DTOs sync serializan/deserializan; builder local sin HTTP |
| Sync validator | ~5 s | Snapshot sync válido/inválido; catálogos opcionales |
| Fake sync client | ~5 s | Push/pull simulado, revisiones y conflictos sin HTTP |
| Sync coordinator | ~5 s | Orquestación build/validate/push/pull sin aplicar remoto |
| Backend save contract | ~5 s | DTOs JSON guardado online; sin HTTP |
| Save API client | ~5 s | GET/POST/PUT parseo y errores tipados (mock Dio) |
| HTTP sync client | ~5 s | Adaptador HttpClashSyncClient push/pull |
| Suite `test/features/clash/` | ~minutos | Regresiones unitarias/UI de todo el módulo Clash |

## Analyze (Clash)

```bash
cd eternalxi_front
flutter analyze lib/features/clash test/features/clash
```

## Notas

- Los smoke tests usan backends in-memory y `SharedPreferences` mock; no dependen del estado del dispositivo.
- No sustituyen pruebas manuales en móvil ni tests E2E contra backend.
- **No** hay tests backend reales de Clash save (Fase 69 = contrato documentado + DTOs frontend).
- Fantasy, leagues y rewards globales tienen sus propias suites; no se ejecutan con estos comandos.
