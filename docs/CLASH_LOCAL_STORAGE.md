# Almacenamiento local Clash (Fase 56)

Persistencia **local-first** de Clash en `SharedPreferences`. Sin sync remoto en esta fase.

## Schema version global

| Clave | Tipo | Descripción |
|-------|------|-------------|
| `clash_schema_version` | `int` | Versión global del esquema local Clash |
| `clash_last_migrated_at` | `String` (ISO-8601 UTC) | Última migración ejecutada |
| `clash_last_local_backup_v1` | `String` (JSON) | Último backup local antes de aplicar snapshot remoto (Fase 73) |
| `clash_sync_metadata_v1` | `String` (JSON) | Metadatos locales de sync online (Fase 76) |
| `clash_sync_auto_check_enabled_v1` | `bool` | Auto-check remoto al abrir Clash, **off** por defecto (Fase 79) |
| `clash_sync_pending_notice_dismissed_revision_v1` | `int?` | Revisión del aviso de partida online pendiente ocultada (Fase 80) |
| `clash_online_claims_enabled_v1` | `bool` | Registro experimental de claims online, **off** por defecto (Fase 83) |

### Online claims settings (`clash_online_claims_enabled_v1`)

Boolean experimental. Cuando es `true`, `ClashOnlineClaimRegistrar` puede registrar claims vía `POST /api/v1/clash/claims`. **No** concede recompensas locales ni modifica progreso. **No** está integrado en flujos reales todavía.

Código: `clash_sync_settings_storage.dart`, `clash_online_claim_registrar.dart`.

### Aviso pending notice (`clash_sync_pending_notice_dismissed_revision_v1`)

Entero opcional. Guarda la `knownServerRevision` para la cual el usuario cerró el aviso de partida online pendiente. **No** modifica `clash_sync_metadata_v1` ni borra `hasPendingRemoteSnapshot`.

Código: `clash_sync_settings_storage.dart` (`loadDismissedPendingRevision`, `dismissPendingRevision`, `clearDismissedPendingRevision`).

### Auto-check settings (`clash_sync_auto_check_enabled_v1`)

Boolean simple. Cuando es `true`, al entrar en Clash Home el cliente puede hacer GET remoto (pull) con throttling de 5 minutos. **No** aplica snapshot, **no** sube local, **no** crea save.

Código: `clash_sync_settings.dart`, `clash_sync_settings_storage.dart`, `clash_sync_auto_check_service.dart`.

### Formato metadata sync (`clash_sync_metadata_v1`)

JSON pequeño con revision conocida, timestamps de última operación, estado/error y flags (`hasPendingRemoteSnapshot`, `hasLocalBackup`). **No** incluye snapshots completos, `userId` ni tokens.

Campos: `knownServerRevision`, `lastSuccessfulSyncAt`, `lastPullAt`, `lastPushAt`, `lastApplyAt`, `lastRestoreAt`, `lastOperation`, `lastStatus`, `lastErrorCode`, `lastMessage`, `lastConflictServerRevision`, `hasPendingRemoteSnapshot`, `hasLocalBackup`.

Código: `clash_sync_metadata.dart`, `clash_sync_metadata_storage.dart`.

### Formato backup (`clash_last_local_backup_v1`)

JSON con:

| Campo | Descripción |
|-------|-------------|
| `generatedAt` | ISO-8601 UTC |
| `source` | `beforeRemoteApply` |
| `serverRevision` | Revisión remota conocida (opcional) |
| `snapshot` | `ClashSyncSnapshot` completo del estado local previo |

Solo se conserva el **último** backup (no historial). No forma parte de `dataKeys`.

Código: `clash_sync_local_backup.dart`, `ClashSyncLocalBackupStore`.

- **Versión actual de la app:** `1` (`ClashStorageSchema.currentVersion`)
- **Instalaciones sin clave:** se consideran versión `0` (legacy)
- **Migración 0→1:** solo registra metadata; **no transforma** datos existentes

Código: `lib/features/clash/shared/migrations/`.

## Keys de datos actuales

Definidas en `ClashSharedPreferencesKeys`:

| Dominio | Clave |
|---------|-------|
| Alineaciones 7v7 | `clash_lineups_7v7_v1` |
| Colección (legacy) | `clash_player_collection_v1` |
| Colección | `clash_player_collection_v2` |
| Inventario EXP | `clash_exp_material_inventory_v1` |
| Libros técnicos | `clash_technique_book_inventory_v1` |
| Materiales evolución | `clash_evolution_material_inventory_v1` |
| Tickets gacha | `clash_gacha_ticket_inventory_v1` |
| Misiones diarias | `clash_daily_missions_v1` |
| Misiones semanales | `clash_weekly_missions_v1` |
| Logros | `clash_achievements_v1` |
| Noticias leídas | `clash_news_read_v1` |
| Regalos | `clash_gifts_v1` |
| Eventos personaje | `clash_character_events_v1` |
| Historial gacha | `clash_gacha_history_v1` |
| Historial recompensas | `clash_reward_history_v1` |
| Pity gacha | `clash_gacha_pity_v1` |
| Descuento diario gacha | `clash_gacha_daily_v1` |
| Progreso historia/wallet | `clash_story_progress_v1` |

**No cambiar** estos strings sin migración y tests.

Algunos backends críticos ya referencian `ClashSharedPreferencesKeys` (story, collection, gifts). El resto conserva su constante local hasta una fase de centralización mayor.

## Migraciones

`ClashLocalMigrationRunner` (`SharedPreferences`):

1. Lee `clash_schema_version` (default `0`)
2. Si versión > app → `futureVersionDetected`, no modifica
3. Si versión >= actual → `skipped`
4. Ejecuta migraciones pendientes en orden (`0_to_1`, …)
5. Devuelve `ClashMigrationResult` (`fromVersion`, `toVersion`, `ranMigrations`, …)

Integración: `prepareClashProviders()` ejecuta el runner **antes** de crear backends.

### Añadir una migración futura (ej. 1→2)

1. Incrementar `ClashStorageSchema.currentVersion`
2. Implementar `migrate1To2` en `ClashLocalMigrations`
3. Añadir `case 1:` en `ClashLocalMigrationRunner.run()`
4. Tests obligatorios:
   - datos v1 intactos o transformados según spec
   - idempotencia (no re-ejecutar si ya en versión)
   - no borrar claves sin backup/migración explícita

## Reglas

- **No borrar** datos de usuario sin migración documentada y backup
- **Idempotencia:** migrar solo si `storedVersion < targetVersion`
- **Tests obligatorios** por migración
- Mantener compatibilidad **old → new** (lectura legacy si aplica, p. ej. collection v1→v2)
- Backend futuro: esta versión global complementará (no sustituye) sync remoto e idempotencia server-side

## Tests

```bash
cd eternalxi_front
flutter test test/features/clash/migrations/clash_local_migration_runner_test.dart
flutter test test/features/clash/storage/clash_local_storage_compatibility_test.dart
flutter test test/features/clash/debug/clash_debug_screen_test.dart
```

## Compatibilidad de datos antiguos (Fase 64)

Suite que monta `SharedPreferences` mock con payloads legacy mínimos y verifica que los backends actuales los cargan sin pérdida ni excepciones.

**Storages cubiertos:** schema/migración 0→1, colección v1/v2, inventarios (EXP, técnica, evolución, tickets), lineups, gifts, misiones daily/weekly, achievements, character events, gacha history/pity/daily, story progress/wallet, reward history.

```bash
cd eternalxi_front
flutter test test/features/clash/storage/clash_local_storage_compatibility_test.dart
```

**Cuándo usarla:** tras cambiar parsing de storage, añadir campos nuevos a snapshots, o antes de una migración 1→2. Complementa `migrations/` (metadata de schema) con compatibilidad de payloads reales.

## Panel de diagnóstico local (Fase 61)

Pantalla interna de solo lectura en `/clash/debug` (`ClashDebugScreen`).

- Resume schema version, última migración, colección, inventarios, eventos, gacha y claims sin modificar datos.
- Acceso discreto desde ayuda Clash (`clashDebugOpen`).
- No expone reset, borrado ni edición de inventario.

Código: `lib/features/clash/debug/`.

## Smoke test local (Fase 62)

Suite rápida de regresión para flujos Clash principales (home, historia, eventos, regalos, tienda, inventario, historial, debug).

```bash
cd eternalxi_front
flutter test test/features/clash/smoke/clash_local_smoke_test.dart
```

Ver también: [`CLASH_QA.md`](./CLASH_QA.md).

## Relación con otros documentos

- Contratos de contenido JSON: [`CLASH_CONTENT_CONTRACTS.md`](./CLASH_CONTENT_CONTRACTS.md)
- **Contrato sync frontend (Fase 65):** [`CLASH_SYNC_CONTRACT.md`](./CLASH_SYNC_CONTRACT.md) — DTOs `ClashSyncSnapshot`, builder local, endpoints futuros documentados. No modifica claves SP ni persistencia.
- Auditoría técnica: [`CLASH_TECHNICAL_AUDIT.md`](./CLASH_TECHNICAL_AUDIT.md)
