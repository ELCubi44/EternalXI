-- Migración manual idempotente (producción) — V20260519120000
-- Ejecutar una sola vez contra la BD EternalXI. Re-ejecutable sin error si ya aplicada.

-- Columna preparacion_bloqueada_en
SET @db := DATABASE();
SET @ddl := (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE partidos_jornada ADD COLUMN preparacion_bloqueada_en TIMESTAMP NULL DEFAULT NULL',
        'SELECT ''preparacion_bloqueada_en ya existe'' AS info'
    )
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @db
      AND TABLE_NAME = 'partidos_jornada'
      AND COLUMN_NAME = 'preparacion_bloqueada_en'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Columna preparacion_bloqueada_motivo
SET @ddl := (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE partidos_jornada ADD COLUMN preparacion_bloqueada_motivo VARCHAR(512) NULL DEFAULT NULL',
        'SELECT ''preparacion_bloqueada_motivo ya existe'' AS info'
    )
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @db
      AND TABLE_NAME = 'partidos_jornada'
      AND COLUMN_NAME = 'preparacion_bloqueada_motivo'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Índice (solo si no existe)
SET @ddl := (
    SELECT IF(
        COUNT(*) = 0,
        'CREATE INDEX idx_pj_preparacion_bloqueada ON partidos_jornada (preparacion_bloqueada_en, estado)',
        'SELECT ''idx_pj_preparacion_bloqueada ya existe'' AS info'
    )
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = @db
      AND TABLE_NAME = 'partidos_jornada'
      AND INDEX_NAME = 'idx_pj_preparacion_bloqueada'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificación
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @db
  AND TABLE_NAME = 'partidos_jornada'
  AND COLUMN_NAME IN ('preparacion_bloqueada_en', 'preparacion_bloqueada_motivo')
ORDER BY COLUMN_NAME;
