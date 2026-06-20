# Cierre MVP — Guardado online Clash

Documento de cierre del tema **guardado online de partida Clash** a nivel manual/diagnóstico (Fase 83).

## Qué está implementado

### Backend (desplegado)
- `GET/POST/PUT /api/v1/clash/save` — snapshot + `serverRevision`
- `POST /api/v1/clash/claims` — registro idempotente por `(usuario, claimId)`
- Tablas `clash_save`, `clash_claim`
- Auth JWT; **nunca** `userId` en body

### Flutter — sync manual
- Snapshot builder/validator/coordinator
- `ClashSaveApiClient`, `HttpClashSyncClient`
- Diagnóstico `/clash/debug`: validate, pull, push, apply, restore, bootstrap
- Backup local antes de apply
- Metadata `clash_sync_metadata_v1`
- Auto-check opcional (`clash_sync_auto_check_enabled_v1`, **off**)
- Aviso partida pendiente (`clash_sync_pending_notice_dismissed_revision_v1`)

### Flutter — claims online (experimental)
- DTOs + `ClashClaimApiClient`
- `ClashClaimIdBuilder` — IDs estables por flujo
- `ClashOnlineClaimRegistrar` — registro tolerante
- Toggle `clash_online_claims_enabled_v1` (**off**)
- Botón debug **Probar registro de claim online** (`debug:claim-test`)

## Qué es seguro probar

1. Sync manual desde diagnóstico (pull/push/apply con confirmación).
2. Bootstrap manual de partida online.
3. Auto-check (solo GET, throttling 5 min).
4. Registro de claim debug con toggle activado (accepted / alreadyProcessed).

## Apagado por defecto

| Ajuste | Key | Default |
|--------|-----|---------|
| Auto-check al abrir Clash | `clash_sync_auto_check_enabled_v1` | `false` |
| Registrar claims online | `clash_online_claims_enabled_v1` | `false` |

Gameplay Clash sigue **100 % local** sin activar toggles experimentales.

## Qué NO está implementado (fase futura server-authoritative)

- Concesión real de rewards en backend
- Migración de gifts/missions/events/shop/story al registrador
- Economía/gacha server-side
- Apply/push/create automático
- Merge automático
- Sync al login
- Mutación de `clash_save` desde claims

## Reglas de integración futura

- `alreadyProcessed` → **no** repetir grant local (`shouldContinueLocalGrant = false`)
- Fallo backend en modo opcional → gameplay local continúa
- Mismo `claimId` → idempotente server-side

## Checklist de cierre actual

- [x] Save online real en backend
- [x] Cliente Flutter save + conflictos 409
- [x] Sync manual + metadata + backup
- [x] Auto-check y aviso pending (opcionales, off)
- [x] Claims backend idempotentes (sin rewards reales)
- [x] Cliente + registrador Flutter (sin flujos reales)
- [x] Prueba manual en diagnóstico
- [x] Tests sync/debug/smoke/responsive
- [ ] Migración gradual claims reales (futuro)
- [ ] Rewards server-authoritative (futuro)
