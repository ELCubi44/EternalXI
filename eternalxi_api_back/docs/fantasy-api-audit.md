# Auditoría API fantasy / anti-spoiler / operaciones

## URLs de imágenes (assets)

Las respuestas de liga **no** deben incluir rutas de disco (`/opt/eternalxi/...`). Utilidad central: `LeagueAssetUrls`.

| Recurso | URL API |
|---------|---------|
| Equipo | `/api/v1/assets/teams/{idEquipo}` |
| Jugador | `/api/v1/assets/players/{idJugador}` |
| Entrenador | `/api/v1/assets/managers/{idEntrenador}` |
| Cedido | `/api/v1/assets/loan-players/{idJugadorCedido}` |

En partidos en vivo, preferir `fotoUrl` en alineaciones/eventos si el DTO lo expone; `foto` y `fotoUrl` se rellenan con la misma ruta API donde aplica.

## P1 — Desglose oficial (`puntosDesglose`)

- **Calculador único:** `FantasyPointsBreakdownCalculator` (usado por simulación y lecturas).
- **DTO:** `FantasyPointsBreakdownResponse` en:
  - `LeaguePlayerRoundStatsResponse.puntosDesglose`
  - `LeagueParticipantLineupRoundPlayerResponse.puntosDesglose`
- **Regla portero:** `paradas` en desglose = `paradas_raw / 2` (división entera).
- **`total`** del desglose = `puntos` de la misma fila.
- **EN_JUEGO:** stats y desglose desde eventos visibles (`LeagueMatchLiveFantasyMask`).
- **FINALIZADO:** stats persistidos en `jugadores_puntos_jornada`.

## P4 — Recalcular probabilidades de titularidad

```http
POST /api/v1/leagues/{idLiga}/starter-probabilities/recalculate?idUsuario={idUsuario}&idJornada={opcional}&idPartido={opcional}
```

| Parámetros | Efecto |
|------------|--------|
| `idUsuario` (obligatorio) | Debe ser participante de la liga (validación). |
| `idPartido` | Recalcula solo ese partido. |
| `idJornada` (sin `idPartido`) | Recalcula toda la jornada. |
| Ninguno opcional extra | `recalculateForLeague(idLiga)` — **toda la liga**. |

Tras comprimir calendario: llamar por liga o por jornadas afectadas.

## P2 — Endpoints públicos y enmascarado (confirmados en código)

### Enmascarados en partido `EN_JUEGO` / antes de inicio

| Método | Ruta | Qué enmascara |
|--------|------|----------------|
| GET | `/api/v1/leagues/{idLiga}/players/{idLigaJugador}` | `estadisticasJornadas`, `puntosDesglose`, stats hasta minuto visible |
| GET | `/api/v1/leagues/{idLiga}/participants/{id}/lineup-history/{idJornada}` | Puntos/desglose por jugador vía `loadMaskedRoundStats` |
| GET | `/api/v1/leagues/{idLiga}/matches/{idPartido}` | Proyección visible (`buildVisibleMatchProjection`) |
| GET | `/api/v1/leagues/{idLiga}/matches/{idPartido}/live` | Eventos filtrados por tiempo visible |
| GET | `/api/v1/leagues/{idLiga}/unavailable-players` | Lesión/sanción solo si evento visible en partido en curso |
| GET | `/api/v1/leagues/{idLiga}/lineup` | Puntos jornada editable con máscara live |
| GET | `/api/v1/leagues/{idLiga}/rounds/{idJornada}` | Marcador/eventos visibles en partidos en juego |

### Sin enmascarado live (datos persistidos / agregados)

| Método | Ruta | Notas |
|--------|------|--------|
| GET | `/api/v1/leagues/{idLiga}/standings` | Puntos totales participante (no desglose por partido) |
| GET | `/api/v1/leagues/{idLiga}/market` | Mercado, no stats de partido |
| GET | `/api/v1/leagues/{idLiga}/squad` | Estado `liga_jugadores` (lesión aplicada al finalizar partido en sim) |
| GET | `/api/v1/leagues/{idLiga}/participants/{id}/squad` | Igual que squad |
| GET | `/api/v1/leagues/{idLiga}/starter-probabilities` | Probabilidades, no puntos |
| GET | `/api/v1/leagues/{idLiga}/home-feed` | Noticias; lesiones recientes con reglas de visibilidad en SQL |

**Regla producto:** Si `partido_efectos_jugador` existe pero el evento aún no es visible, no debe aparecer en unavailable/squad/detalle en directo — comprobar `getUnavailablePlayers` y joins a `partido_eventos` con filtro temporal.

## P3 — Kick

`POST /api/v1/leagues/{idLiga}/kick` — logs INFO/WARN con ids, admin real, participante, motivo exacto.

Limpieza al expulsar:

- Ofertas del expulsado (comprador) canceladas + reembolso.
- Ofertas de otros sobre sus jugadores canceladas.
- Pujas del expulsado en mercado nocturno (reembolso si mercado activo).
- Mercados diarios **activos** de sus jugadores cancelados (`cancelUnresolvedMarketsForLeaguePlayers`).
- Adjudicación nocturna: si el ganador ya no es participante, resuelve sin ganador y reembolsa.
- Actividad `ADMIN_KICK`.

## P5 — Informe valor de mercado (sin cambiar fórmula)

Ver `docs/informe-valor-mercado-ejemplos.sql` — ejecutar en BD de la liga y rellenar 5 casos.
