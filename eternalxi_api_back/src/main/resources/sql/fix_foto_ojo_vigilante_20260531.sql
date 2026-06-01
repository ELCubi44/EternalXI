USE EternalXI;

SELECT e.id, e.nombre, e.foto, COUNT(j.id) AS jugadores,
       SUM(j.foto IS NULL OR TRIM(j.foto) = '') AS sin_foto
FROM equipos e
LEFT JOIN jugadores j ON j.id_equipo = e.id
WHERE e.nombre LIKE '%Ojo%Vigilante%'
   OR e.nombre LIKE '%Vigilante%'
GROUP BY e.id, e.nombre, e.foto;

UPDATE equipos
SET foto = CONCAT('/opt/eternalxi/teams/', nombre, '.png')
WHERE (foto IS NULL OR TRIM(foto) = '')
  AND (nombre LIKE '%Ojo%Vigilante%' OR nombre LIKE '%Vigilante%');

UPDATE jugadores j
JOIN equipos e ON e.id = j.id_equipo
SET j.foto = CONCAT('/opt/eternalxi/players/', j.nombre, '.png')
WHERE (j.foto IS NULL OR TRIM(j.foto) = '')
  AND (e.nombre LIKE '%Ojo%Vigilante%' OR e.nombre LIKE '%Vigilante%');

SELECT e.id, e.nombre, e.foto FROM equipos e WHERE e.nombre LIKE '%Vigilante%';
SELECT COUNT(*) AS jugadores_con_foto FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo WHERE e.nombre LIKE '%Vigilante%' AND j.foto IS NOT NULL AND TRIM(j.foto) <> '';
SELECT j.id, j.nombre, j.foto FROM jugadores j
JOIN equipos e ON e.id = j.id_equipo WHERE e.nombre LIKE '%Vigilante%' ORDER BY j.id LIMIT 3;
