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
| Suite `test/features/clash/` | ~minutos | Regresiones unitarias/UI de todo el módulo Clash |

## Analyze (Clash)

```bash
cd eternalxi_front
flutter analyze lib/features/clash test/features/clash
```

## Notas

- Los smoke tests usan backends in-memory y `SharedPreferences` mock; no dependen del estado del dispositivo.
- No sustituyen pruebas manuales en móvil ni tests E2E contra backend.
- Fantasy, leagues y rewards globales tienen sus propias suites; no se ejecutan con estos comandos.
