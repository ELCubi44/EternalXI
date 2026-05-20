-- Reparación manual (MySQL): partidos simulados con FINAL pero aún EN_JUEGO.
-- Tras desplegar el fix de API, preferir POST /api/v1/leagues/simulations/repair-stuck-finalized
-- (reconcilia goles desde tabla goles y ejecuta el mismo cierre que finalizeMatchNow).

-- 1) Vista de candidatos (solo lectura)
SELECT pj.id            AS id_partido,
       j.id_liga,
       pj.id_jornada,
       pj.estado,
       pj.goles_local,
       pj.goles_visitante,
       (SELECT MAX(e.minuto) FROM partido_eventos e WHERE e.id_partido_jornada = pj.id) AS max_minuto
FROM partidos_jornada pj
INNER JOIN jornadas j ON j.id = pj.id_jornada
WHERE pj.estado = 'EN_JUEGO'
  AND EXISTS (
      SELECT 1
      FROM partido_eventos ev
      WHERE ev.id_partido_jornada = pj.id
        AND ev.tipo = 'FINAL'
  )
  AND COALESCE(
      (SELECT MAX(ev2.minuto) FROM partido_eventos ev2 WHERE ev2.id_partido_jornada = pj.id),
      0
  ) >= 90
  AND EXISTS (
      SELECT 1
      FROM jugadores_puntos_jornada jpj
      WHERE jpj.id_jornada = pj.id_jornada
  );

-- 2) Reconciliar equipos_partido.goles desde tabla goles (opcional, por partido concreto :id_partido y :id_liga)
-- UPDATE equipos_partido ep
-- INNER JOIN (
--     SELECT le.id AS id_liga_equipo, COUNT(*) AS n
--     FROM goles g
--     INNER JOIN liga_jugadores lj ON lj.id = g.id_liga_jugador
--     INNER JOIN liga_equipos le ON le.id_liga = lj.id_liga AND le.id_equipo = lj.id_equipo
--     WHERE g.id_partido_jornada = :id_partido
--       AND lj.id_liga = :id_liga
--     GROUP BY le.id
-- ) x ON x.id_liga_equipo = ep.id_liga_equipo
-- SET ep.goles = x.n
-- WHERE ep.id_partido_jornada = :id_partido;

-- 3) Cierre: usar la API (recomendado) para aplicar fatiga, clasificación, jornada y premios idempotentes:
-- POST /api/v1/leagues/simulations/repair-stuck-finalized
-- o por partido:
-- POST /api/v1/leagues/{idLiga}/matches/{idPartido}/finalize
