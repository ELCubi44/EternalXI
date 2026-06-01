USE EternalXI;

-- Equipos sin foto: /opt/eternalxi/teams/{nombre}.png
UPDATE equipos
SET foto = CONCAT('/opt/eternalxi/teams/', nombre, '.png')
WHERE foto IS NULL OR TRIM(foto) = '';

-- Jugadores sin foto: /opt/eternalxi/players/{nombre completo}.png
UPDATE jugadores
SET foto = CONCAT('/opt/eternalxi/players/', nombre, '.png')
WHERE foto IS NULL OR TRIM(foto) = '';

SELECT e.id, e.nombre, e.foto FROM equipos e WHERE e.id = 20;
SELECT COUNT(*) AS jugadores_con_foto FROM jugadores WHERE id_equipo = 20 AND foto IS NOT NULL AND TRIM(foto) <> '';
SELECT id, nombre, foto FROM jugadores WHERE id_equipo = 20 LIMIT 3;
