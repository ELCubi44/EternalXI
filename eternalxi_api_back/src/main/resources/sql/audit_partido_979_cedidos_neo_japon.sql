-- Auditoría post-simulación: partido 979 (liga 7 TEST) — SOLO LECTURA
-- Objetivo: confirmar que Neo Japón cumple 4-3-3 con cedido DEF titular si faltaban defensas propios.

-- 0) Contexto del partido
SELECT pj.id AS id_partido,
       j.id_liga,
       j.numero AS jornada,
       pj.estado,
       pj.preparacion_bloqueada_en,
       pj.preparacion_bloqueada_motivo,
       e_l.nombre AS local,
       e_v.nombre AS visitante,
       e_l.alineacion AS alineacion_local,
       e_v.alineacion AS alineacion_visitante
FROM partidos_jornada pj
INNER JOIN jornadas j ON j.id = pj.id_jornada
INNER JOIN equipos e_l ON e_l.id = pj.id_liga_equipo_local
INNER JOIN equipos e_v ON e_v.id = pj.id_liga_equipo_visitante
WHERE pj.id = 979;

-- 1) Titulares Neo Japón (visitante) — jugador a jugador
SELECT ap.id_partido_jornada,
       e.nombre AS equipo,
       ap.titular,
       ap.tipo_origen_jugador,
       ap.id_liga_jugador,
       ap.id_jugador_cedido_temporada,
       COALESCE(jct.nombre, j.nombre) AS jugador,
       COALESCE(jct.posicion, j.posicion) AS posicion,
       CASE
           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 'CEDIDO'
           ELSE 'PROPIO'
       END AS origen
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada = 979
  AND le.id_equipo = pj.id_liga_equipo_visitante
  AND ap.titular = 1
ORDER BY FIELD(COALESCE(jct.posicion, j.posicion), 'POR', 'DEF', 'MED', 'DEL'),
         origen DESC,
         jugador;

-- 2) Resumen titulares Neo Japón por posición (esperado 4-3-3: POR 1, DEF 4, MED 3, DEL 3)
SELECT e.nombre AS equipo,
       COALESCE(jct.posicion, j.posicion) AS posicion,
       SUM(CASE WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 1 ELSE 0 END) AS n_cedidos,
       COUNT(*) AS n_titulares
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada = 979
  AND le.id_equipo = pj.id_liga_equipo_visitante
  AND ap.titular = 1
GROUP BY e.nombre, COALESCE(jct.posicion, j.posicion)
ORDER BY FIELD(posicion, 'POR', 'DEF', 'MED', 'DEL');

-- 3) Comprobación rápida vs 4-3-3 (Neo Japón visitante)
SELECT e.nombre AS equipo,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'POR' AND ap.titular = 1 THEN 1 ELSE 0 END) AS por,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'DEF' AND ap.titular = 1 THEN 1 ELSE 0 END) AS def,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'MED' AND ap.titular = 1 THEN 1 ELSE 0 END) AS med,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'DEL' AND ap.titular = 1 THEN 1 ELSE 0 END) AS del,
       SUM(CASE WHEN ap.titular = 1 AND ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 1 ELSE 0 END) AS titulares_cedidos,
       SUM(CASE WHEN ap.titular = 1 AND ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                     AND COALESCE(jct.posicion, j.posicion) = 'DEF' THEN 1 ELSE 0 END) AS cedidos_def_titular
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada = 979
  AND le.id_equipo = pj.id_liga_equipo_visitante
GROUP BY e.nombre;

-- 4) Cedidos DEF titulares (debe haber >= 1 si solo había 3 DEF propios)
SELECT e.nombre AS equipo,
       jct.id AS id_jugador_cedido,
       jct.nombre AS cedido,
       jct.posicion,
       pc.rol
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
INNER JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
LEFT JOIN partido_cesiones pc
       ON pc.id_partido_jornada = ap.id_partido_jornada
      AND pc.id_liga_equipo_destino = ap.id_liga_equipo
      AND pc.id_jugador_cedido_temporada = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada = 979
  AND le.id_equipo = pj.id_liga_equipo_visitante
  AND ap.titular = 1
  AND ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
  AND jct.posicion = 'DEF';

-- 5) Cesiones del partido (ambos equipos)
SELECT ed.nombre AS equipo_destino,
       pc.rol,
       pc.tipo_origen_jugador,
       COALESCE(jct.nombre, j.nombre) AS jugador,
       COALESCE(jct.posicion, j.posicion) AS posicion
FROM partido_cesiones pc
INNER JOIN liga_equipos led ON led.id = pc.id_liga_equipo_destino
INNER JOIN equipos ed ON ed.id = led.id_equipo
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = pc.id_jugador_cedido_temporada
LEFT JOIN liga_jugadores lj ON lj.id = pc.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
WHERE pc.id_partido_jornada = 979
ORDER BY ed.nombre, pc.rol, posicion, jugador;

-- 6) The Little Giants (local) — mismo resumen por si quieres contrastar
SELECT e.nombre AS equipo,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'POR' AND ap.titular = 1 THEN 1 ELSE 0 END) AS por,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'DEF' AND ap.titular = 1 THEN 1 ELSE 0 END) AS def,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'MED' AND ap.titular = 1 THEN 1 ELSE 0 END) AS med,
       SUM(CASE WHEN COALESCE(jct.posicion, j.posicion) = 'DEL' AND ap.titular = 1 THEN 1 ELSE 0 END) AS del
FROM alineacion_partido ap
INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
INNER JOIN liga_equipos le ON le.id = ap.id_liga_equipo
INNER JOIN equipos e ON e.id = le.id_equipo
LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
LEFT JOIN jugadores j ON j.id = lj.id_jugador
LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
WHERE ap.id_partido_jornada = 979
  AND le.id_equipo = pj.id_liga_equipo_local
GROUP BY e.nombre;
