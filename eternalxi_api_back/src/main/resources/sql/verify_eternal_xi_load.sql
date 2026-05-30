USE EternalXI;

SELECT '=== TEMPORADA ===' AS seccion;
SELECT t.id, tt.locale, tt.nombre
FROM temporadas t
JOIN temporada_traduccion tt ON tt.id_temporada = t.id
WHERE tt.nombre IN ('Eterno Campeon', 'Eternal Crown')
   OR t.nombre = 'Eterno Campeon'
ORDER BY t.id, tt.locale;

SELECT '=== EQUIPO ETERNAL XI ===' AS seccion;
SELECT e.id, e.id_temporada, et.locale, et.nombre AS nombre_traducido
FROM equipos e
LEFT JOIN equipo_traduccion et ON et.id_equipo = e.id
WHERE e.nombre = 'Eternal XI' OR et.nombre LIKE '%Eternal XI%'
ORDER BY e.id, et.locale;

SELECT '=== CONTEOS ===' AS seccion;
SELECT
  (SELECT COUNT(*) FROM jugadores j JOIN equipos e ON e.id = j.id_equipo WHERE e.nombre = 'Eternal XI') AS jugadores_equipo,
  (SELECT COUNT(*) FROM jugador_traduccion jt
   JOIN jugadores j ON j.id = jt.id_jugador
   JOIN equipos e ON e.id = j.id_equipo
   WHERE e.nombre = 'Eternal XI' AND jt.locale = 'es') AS bios_es,
  (SELECT COUNT(*) FROM jugador_traduccion jt
   JOIN jugadores j ON j.id = jt.id_jugador
   JOIN equipos e ON e.id = j.id_equipo
   WHERE e.nombre = 'Eternal XI' AND jt.locale = 'en') AS bios_en,
  (SELECT COUNT(*) FROM jugador_supertecnica js
   JOIN jugadores j ON j.id = js.id_jugador
   JOIN equipos e ON e.id = j.id_equipo
   WHERE e.nombre = 'Eternal XI') AS enlaces_st,
  (SELECT COUNT(DISTINCT js.id_supertecnica) FROM jugador_supertecnica js
   JOIN jugadores j ON j.id = js.id_jugador
   JOIN equipos e ON e.id = j.id_equipo
   WHERE e.nombre = 'Eternal XI') AS st_distintas;

SELECT '=== JUGADORES (dorsal, nombre, pos, estilo) ===' AS seccion;
SELECT j.dorsal, j.nombre, j.pila, j.posicion, j.estilo, j.valoracion, j.pais
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
WHERE e.nombre = 'Eternal XI'
ORDER BY j.dorsal;

SELECT '=== ST POR JUGADOR (muestra) ===' AS seccion;
SELECT j.nombre, js.orden, st.nombre AS clave, stt.locale, stt.nombre AS visible, st.potencia, st.tipo, st.estilo
FROM jugador_supertecnica js
JOIN jugadores j ON j.id = js.id_jugador
JOIN equipos e ON e.id = j.id_equipo
JOIN supertecnicas st ON st.id = js.id_supertecnica
LEFT JOIN supertecnica_traduccion stt ON stt.id_supertecnica = st.id
WHERE e.nombre = 'Eternal XI' AND j.nombre = 'Thiago Solari'
ORDER BY js.orden, stt.locale;

SELECT '=== PROBLEMAS: jugadores sin 4 ST ===' AS seccion;
SELECT j.id, j.nombre, COUNT(js.id) AS num_st
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
LEFT JOIN jugador_supertecnica js ON js.id_jugador = j.id
WHERE e.nombre = 'Eternal XI'
GROUP BY j.id, j.nombre
HAVING COUNT(js.id) <> 4;

SELECT '=== PROBLEMAS: sin bio es o en ===' AS seccion;
SELECT j.nombre,
  SUM(CASE WHEN jt.locale = 'es' THEN 1 ELSE 0 END) AS tiene_es,
  SUM(CASE WHEN jt.locale = 'en' THEN 1 ELSE 0 END) AS tiene_en
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
LEFT JOIN jugador_traduccion jt ON jt.id_jugador = j.id
WHERE e.nombre = 'Eternal XI'
GROUP BY j.id, j.nombre
HAVING tiene_es = 0 OR tiene_en = 0;

SELECT '=== ESTILOS USADOS ===' AS seccion;
SELECT j.estilo, COUNT(*) AS cnt FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo WHERE e.nombre = 'Eternal XI'
GROUP BY j.estilo;
