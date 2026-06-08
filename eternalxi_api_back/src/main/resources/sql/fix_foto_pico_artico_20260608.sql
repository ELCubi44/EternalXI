USE EternalXI;

-- Pico Artico (id 25): rutas de foto según convención VPS
UPDATE equipos
SET foto = CONCAT('/opt/eternalxi/teams/', nombre, '.png')
WHERE id = 25
  AND (foto IS NULL OR TRIM(foto) = '');

UPDATE jugadores j
JOIN equipos e ON e.id = j.id_equipo
SET j.foto = CONCAT('/opt/eternalxi/players/', j.nombre, '.png')
WHERE e.id = 25
  AND (j.foto IS NULL OR TRIM(j.foto) = '');

UPDATE entrenadores en
SET en.foto = CONCAT('/opt/eternalxi/managers/', en.nombre, '.png')
WHERE en.id_equipo = 25
  AND (en.foto IS NULL OR TRIM(en.foto) = '');

SELECT e.id, e.nombre, e.foto FROM equipos e WHERE e.id = 25;
SELECT COUNT(*) AS jugadores_con_foto
FROM jugadores j WHERE j.id_equipo = 25 AND j.foto IS NOT NULL AND TRIM(j.foto) <> '';
SELECT j.id, j.nombre, j.foto FROM jugadores j WHERE j.id_equipo = 25 ORDER BY j.id;
