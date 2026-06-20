# Almacenamiento local Clash (Fase 56)

Persistencia **local-first** de Clash en `SharedPreferences`. Sin sync remoto en esta fase.

## Schema version global

| Clave | Tipo | Descripción |
|-------|------|-------------|
| `clash_schema_version` | `int` | Versión global del esquema local Clash |
| `clash_last_migrated_at` | `String` (ISO-8601 UTC) | Última migración ejecutada |

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
```

## Relación con otros documentos

- Contratos de contenido JSON: [`CLASH_CONTENT_CONTRACTS.md`](./CLASH_CONTENT_CONTRACTS.md)
- Auditoría técnica: [`CLASH_TECHNICAL_AUDIT.md`](./CLASH_TECHNICAL_AUDIT.md)
