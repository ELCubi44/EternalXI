USE EternalXI;

-- 1) ¿Existe el equipo y la traducción?
SELECT '=== EQUIPO ===' AS paso;
SELECT e.id AS id_equipo, e.nombre AS equipos_nombre, e.id_temporada,
       et.locale, et.nombre AS trad_nombre
FROM equipos e
LEFT JOIN equipo_traduccion et ON et.id_equipo = e.id
WHERE e.nombre LIKE '%Furia%' OR et.nombre LIKE '%Furia%'
ORDER BY e.id, et.locale;

-- 2) ¿Cuántos jugadores hay por id_equipo?
SELECT '=== JUGADORES POR EQUIPO ===' AS paso;
SELECT j.id_equipo, COUNT(*) AS num_jugadores, MIN(j.nombre) AS ejemplo
FROM jugadores j
WHERE j.id_equipo IN (
  SELECT e.id FROM equipos e
  LEFT JOIN equipo_traduccion et ON et.id_equipo = e.id
  WHERE e.nombre LIKE '%Furia%' OR et.nombre LIKE '%Furia%'
)
GROUP BY j.id_equipo;

-- 3) Prueba de JOIN del script de reparación (debe devolver 1 fila)
SELECT '=== TEST JOIN Daichi + campana_temeraria ===' AS paso;
SELECT j.id AS id_jugador, j.nombre, st.id AS id_supertecnica, st.nombre AS st_nombre
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'campana_temeraria' AND st.potencia = 80
  AND st.tipo = 'PARADA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';

-- 4) Si el paso 3 devuelve filas, este INSERT debe dar 1 row affected:
INSERT IGNORE INTO jugador_supertecnica (id_jugador, id_supertecnica, orden)
SELECT j.id, st.id, 1
FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo
JOIN equipo_traduccion et ON et.id_equipo = e.id AND et.locale = 'es'
JOIN supertecnicas st ON st.nombre = 'campana_temeraria' AND st.potencia = 80
  AND st.tipo = 'PARADA' AND st.estilo = 'VALIENTE'
WHERE et.nombre = 'Furia Menuda' AND j.nombre = 'Daichi Enomoto';

SELECT '=== Tras prueba: ST de Daichi ===' AS paso;
SELECT j.nombre, COUNT(js.id) AS num_st
FROM jugadores j
LEFT JOIN jugador_supertecnica js ON js.id_jugador = j.id
WHERE j.nombre = 'Daichi Enomoto'
GROUP BY j.id, j.nombre;
