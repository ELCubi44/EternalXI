-- Auditoría READ-ONLY: partidos 28 (liga 1) y 979 (liga 7)
-- Columnas en partidos_jornada: id_liga_equipo_local / id_liga_equipo_visitante
-- (no existen id_equipo_local ni id_equipo_visitante en esa tabla).
-- Según LeagueSimulationService.lockMatchHeader, esos campos guardan equipos.id
-- y se resuelve liga_equipos con le.id_liga = j.id_liga AND le.id_equipo = pj.id_liga_equipo_*.

-- 1) Partido, equipos y equipos.alineacion (mismo join que la simulación)
SELECT pj.id AS id_partido,
       j.id_liga,
       j.numero AS jornada,
       pj.estado,
       pj.inicio_en,
       pj.preparacion_bloqueada_en,
       pj.preparacion_bloqueada_motivo,
       pj.id_liga_equipo_local,
       pj.id_liga_equipo_visitante,
       le_l.id AS id_liga_equipos_local,
       le_v.id AS id_liga_equipos_visitante,
       e_l.id AS id_equipo_catalog_local,
       e_v.id AS id_equipo_catalog_visitante,
       e_l.nombre AS nombre_local,
       e_l.alineacion AS alineacion_local,
       e_v.nombre AS nombre_visitante,
       e_v.alineacion AS alineacion_visitante
FROM partidos_jornada pj
INNER JOIN jornadas j ON j.id = pj.id_jornada
INNER JOIN equipos e_l ON e_l.id = pj.id_liga_equipo_local
INNER JOIN equipos e_v ON e_v.id = pj.id_liga_equipo_visitante
INNER JOIN liga_equipos le_l ON le_l.id_liga = j.id_liga AND le_l.id_equipo = e_l.id
INNER JOIN liga_equipos le_v ON le_v.id_liga = j.id_liga AND le_v.id_equipo = e_v.id
WHERE pj.id IN (28, 979);

-- 2) Plantilla por equipo de catálogo (posiciones disponibles)
SELECT lj.id_liga,
       lj.id_equipo,
       e.nombre AS equipo,
       j.posicion,
       COUNT(*) AS jugadores,
       SUM(CASE WHEN lj.estado IN ('DISPONIBLE', 'DUDA') THEN 1 ELSE 0 END) AS disponibles_o_duda
FROM liga_jugadores lj
INNER JOIN jugadores j ON j.id = lj.id_jugador
INNER JOIN equipos e ON e.id = lj.id_equipo
WHERE (lj.id_liga, lj.id_equipo) IN (
    SELECT j2.id_liga, pj.id_liga_equipo_local
    FROM partidos_jornada pj
    INNER JOIN jornadas j2 ON j2.id = pj.id_jornada
    WHERE pj.id IN (28, 979)
    UNION
    SELECT j2.id_liga, pj.id_liga_equipo_visitante
    FROM partidos_jornada pj
    INNER JOIN jornadas j2 ON j2.id = pj.id_jornada
    WHERE pj.id IN (28, 979)
)
GROUP BY lj.id_liga, lj.id_equipo, e.nombre, j.posicion
ORDER BY lj.id_liga, lj.id_equipo, j.posicion;

-- 3) Alineación preparada en alineacion_partido (si existe)
SELECT ap.id_partido_jornada,
       ap.id_liga_equipo,
       ap.titular,
       COALESCE(jct.posicion, j.posicion) AS posicion,
       COUNT(*) AS cnt
FROM alineacion_partido ap
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada IN (28, 979)
GROUP BY ap.id_partido_jornada, ap.id_liga_equipo, ap.titular, COALESCE(jct.posicion, j.posicion)
ORDER BY ap.id_partido_jornada, ap.id_liga_equipo, ap.titular DESC, posicion;

-- 4) Interpretación esperada por parser (referencia tras despliegue del fix)
-- 4-3-3 → DEF 4 MED 3 DEL 3
-- 4-4-2 → DEF 4 MED 4 DEL 2
-- 3-5-2 → DEF 3 MED 5 DEL 2
-- 5-5-0 → DEF 5 MED 5 DEL 0
-- 4-2-3-1 → DEF 4 MED 5 DEL 1
