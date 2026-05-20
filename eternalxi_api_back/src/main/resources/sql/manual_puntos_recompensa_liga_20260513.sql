-- =============================================================================
-- SQL MANUAL: Puntos de recompensa por liga (no globales)
-- Fecha: 2026-05-13
-- Ejecutar en servidor remoto donde Flyway no funciona
-- =============================================================================

-- 1. Añadir columna puntos_recompensa a liga_participantes (si no existe)
SET @col_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'liga_participantes'
      AND COLUMN_NAME = 'puntos_recompensa'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE liga_participantes ADD COLUMN puntos_recompensa BIGINT NOT NULL DEFAULT 0',
    'SELECT ''columna puntos_recompensa ya existe'' AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- 2. Dar puntos de prueba a un participante concreto
-- =============================================================================
-- UPDATE liga_participantes
-- SET puntos_recompensa = 5000
-- WHERE id_liga = ID_LIGA
--   AND id_usuario = ID_USUARIO;

-- =============================================================================
-- 3. Ver puntos de recompensa por liga para un usuario
-- =============================================================================
-- SELECT lp.id, lp.id_liga, l.nombre, lp.id_usuario, u.nickname, lp.puntos_recompensa
-- FROM liga_participantes lp
-- JOIN ligas l ON l.id = lp.id_liga
-- JOIN usuarios u ON u.id = lp.id_usuario
-- WHERE lp.id_usuario = ID_USUARIO
-- ORDER BY lp.id_liga;

-- =============================================================================
-- 4. Ver puntos de recompensa de TODOS los participantes de una liga
-- =============================================================================
-- SELECT lp.id, lp.id_usuario, u.nickname, lp.puntos_recompensa, lp.dinero
-- FROM liga_participantes lp
-- JOIN usuarios u ON u.id = lp.id_usuario
-- WHERE lp.id_liga = ID_LIGA
-- ORDER BY lp.puntos_recompensa DESC;

-- =============================================================================
-- 5. Dar puntos iniciales a todos los participantes de una liga (ej: 1500)
-- =============================================================================
-- UPDATE liga_participantes
-- SET puntos_recompensa = 1500
-- WHERE id_liga = ID_LIGA;
