-- Rutas de foto: nombre completo (jugadores.nombre / equipos.nombre) + .png
USE EternalXI;

-- Escudos: /opt/eternalxi/teams/{nombre español del equipo}.png
UPDATE equipos
SET foto = CONCAT('/opt/eternalxi/teams/', nombre, '.png');

-- Jugadores: /opt/eternalxi/players/{nombre completo}.png (NO pila)
UPDATE jugadores
SET foto = CONCAT('/opt/eternalxi/players/', nombre, '.png');

-- Temporadas (misma convención por nombre)
UPDATE temporadas
SET foto = CONCAT('/opt/eternalxi/season/', nombre, '.png')
WHERE nombre IS NOT NULL AND TRIM(nombre) <> '';

-- Entrenadores (carpeta real en VPS: managers)
UPDATE entrenadores
SET foto = CONCAT('/opt/eternalxi/managers/', nombre, '.png')
WHERE nombre IS NOT NULL AND TRIM(nombre) <> '';

-- Verificación
SELECT 'equipos' AS tabla, COUNT(*) AS total, SUM(foto IS NOT NULL) AS con_foto FROM equipos;
SELECT 'jugadores' AS tabla, COUNT(*) AS total, SUM(foto IS NOT NULL) AS con_foto FROM jugadores;
SELECT id, nombre, foto FROM equipos WHERE id IN (17, 18, 19);
SELECT id, nombre, pila, foto FROM jugadores WHERE id_equipo = 17 ORDER BY id LIMIT 3;
