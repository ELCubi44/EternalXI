-- Entrenador de Eternal XI (Eterno Campeón): Víctor Ricarte
INSERT INTO entrenadores (
  nombre,
  pila,
  formacion,
  foto,
  id_equipo,
  id_temporada,
  bonus_puntos,
  activo
)
SELECT
  'Victor Ricarte',
  'Victor',
  '4-3-3',
  '/opt/eternalxi/managers/Victor Ricarte.png',
  e.id,
  e.id_temporada,
  3,
  TRUE
FROM equipos e
WHERE e.nombre = 'Eternal XI'
  AND NOT EXISTS (
    SELECT 1 FROM entrenadores en WHERE en.nombre = 'Victor Ricarte'
  )
LIMIT 1;
