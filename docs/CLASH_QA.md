# QA automatizada Clash

Comandos para validar Clash en local sin dispositivo ni backend remoto.

## Smoke test (rápido)

Valida los flujos locales principales: home, historia, eventos, regalos, tienda, inventario, historial de recompensas y diagnóstico.

```bash
cd eternalxi_front
flutter test test/features/clash/smoke/clash_local_smoke_test.dart
```

**Cuándo usarlo:** antes de commit/push de cambios Clash, tras refactors de navegación o providers, o como comprobación rápida de regresión UI local.

## Suite completa Clash

```bash
cd eternalxi_front
flutter test test/features/clash/
```

**Cuándo usarla:** antes de cerrar una fase del roadmap, tras cambios en economía local, storage, migraciones o pantallas con mucha cobertura de tests.

## Analyze (Clash)

```bash
cd eternalxi_front
flutter analyze lib/features/clash test/features/clash
```

## Notas

- Los smoke tests usan backends in-memory y `SharedPreferences` mock; no dependen del estado del dispositivo.
- No sustituyen pruebas manuales en móvil ni tests E2E contra backend.
- Fantasy, leagues y rewards globales tienen sus propias suites; no se ejecutan con estos comandos.
