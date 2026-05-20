-- Auditoría cedidos + alineacion_partido (partidos 28 y 979) — SOLO LECTURA
-- Ejecutar en producción antes de reactivar automation.

-- A) Detalle titular/suplente por partido y equipo (liga_equipos.id en ap.id_liga_equipo)
SELECT ap.id_partido_jornada,
       j.id_liga,
       ap.id_liga_equipo,
       le.id_equipo AS id_equipo_catalogo,
       e.nombre AS equipo,
       ap.titular,
       ap.tipo_origen_jugador,
       ap.id_liga_jugador,
       ap.id_jugador_cedido_temporada,
       COALESCE(jct.nombre, j.nombre) AS jugador,
       COALESCE(jct.posicion, j.posicion) AS posicion
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN jornadas j ON j.id = pj.id_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada IN (28, 979)
ORDER BY ap.id_partido_jornada, ap.id_liga_equipo, ap.titular DESC, posicion, jugador;

-- B) Resumen titulares por posición (incluye cedidos)
SELECT ap.id_partido_jornada,
       ap.id_liga_equipo,
       e.nombre AS equipo,
       COALESCE(jct.posicion, j.posicion) AS posicion,
       SUM(CASE WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 1 ELSE 0 END) AS titulares_cedidos,
       COUNT(*) AS titulares_total
FROM alineacion_partido ap
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada IN (28, 979)
  AND ap.titular = 1
GROUP BY ap.id_partido_jornada, ap.id_liga_equipo, e.nombre, COALESCE(jct.posicion, j.posicion)
ORDER BY ap.id_partido_jornada, ap.id_liga_equipo, posicion;

-- C) Cesiones registradas para el partido
SELECT pc.id_partido_jornada,
       pc.id_liga_equipo_destino,
       ed.nombre AS equipo_destino,
       pc.rol,
       pc.tipo_origen_jugador,
       pc.id_liga_jugador,
       pc.id_jugador_cedido_temporada,
       COALESCE(jct.posicion, j.posicion) AS posicion
FROM partido_cesiones pc
INNER JOIN liga_equipos led ON led.id = pc.id_liga_equipo_destino
INNER JOIN equipos ed ON ed.id = led.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = pc.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = pc.id_jugador_cedido_temporada
WHERE pc.id_partido_jornada IN (28, 979)
ORDER BY pc.id_partido_jornada, pc.id_liga_equipo_destino, pc.rol, posicion;

-- D) Pool de cedidos DEF disponibles en la temporada de la liga (ej. Neo Japón)
-- Sustituir :id_temporada por id_temporada de ligas 1 y 7.
SELECT jct.id,
       jct.nombre,
       jct.posicion,
       jct.valoracion,
       ect.id AS id_equipo_cedidos_temporada,
       ect.activo AS pool_activo
FROM jugadores_cedidos_temporada jct
INNER JOIN equipos_cedidos_temporada ect ON ect.id = jct.id_equipo_cedidos_temporada
WHERE ect.id_temporada = :id_temporada
  AND ect.activo = 1
  AND jct.activo = 1
  AND jct.posicion = 'DEF'
ORDER BY jct.valoracion DESC, jct.nombre;

-- E) ¿Existe alineacion_partido que bloquee prepareLineupIfMissing? (hasPreparedLineup = COUNT>0)
SELECT id_partido_jornada,
       COUNT(*) AS filas_alineacion,
       SUM(CASE WHEN titular = 1 THEN 1 ELSE 0 END) AS titulares,
       SUM(CASE WHEN tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 1 ELSE 0 END) AS cedidos_total
FROM alineacion_partido
WHERE id_partido_jornada IN (28, 979)
GROUP BY id_partido_jornada;
