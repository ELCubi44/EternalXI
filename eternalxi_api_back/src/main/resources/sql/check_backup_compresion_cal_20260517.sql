-- =============================================================================
-- CHECK: ¿Se modificó algo respecto al backup del intento SQL anterior?
-- Tablas reales en producción (sin sufijo _v3):
--   bak_jornadas_compresion_cal_20260517      (PK: id)
--   bak_partidos_compresion_cal_20260517      (PK: id)
--   bak_ligas_fin_en_compresion_cal_20260517  (PK: id_liga)  ← no tiene columna id
--
-- Solo lectura. Ejecutar antes de preview con LeagueCalendarCompressionTool.
-- Esperado en resumen final: los tres contadores = 0.
-- =============================================================================

SET NAMES utf8mb4;

-- 0) Tablas presentes
SELECT
    TABLE_NAME,
    TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN (
      'bak_jornadas_compresion_cal_20260517',
      'bak_partidos_compresion_cal_20260517',
      'bak_ligas_fin_en_compresion_cal_20260517',
      'plan_compresion_calendario_20260517'
  )
ORDER BY TABLE_NAME;

-- 0.1) Columnas de bak_ligas_fin_en (debe incluir id_liga, fin_en; NO id)
SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'bak_ligas_fin_en_compresion_cal_20260517'
ORDER BY ORDINAL_POSITION;

-- =============================================================================
-- 1) Jornadas PENDIENTE vs backup
-- =============================================================================
SELECT
    'jornadas_diferentes_vs_backup_real' AS check_type,
    COUNT(*) AS filas_con_diferencias
FROM jornadas j
INNER JOIN bak_jornadas_compresion_cal_20260517 bj ON bj.id = j.id
WHERE j.estado = 'PENDIENTE'
  AND (
        NOT (j.inicio <=> bj.inicio)
     OR NOT (j.inicio_en <=> bj.inicio_en)
     OR NOT (j.fin <=> bj.fin)
     OR j.estado <> bj.estado
  );

SELECT
    j.id AS id_jornada,
    j.id_liga,
    j.numero,
    bj.inicio AS inicio_backup,
    j.inicio AS inicio_live,
    bj.inicio_en AS inicio_en_backup,
    j.inicio_en AS inicio_en_live,
    bj.fin AS fin_backup,
    j.fin AS fin_live
FROM jornadas j
INNER JOIN bak_jornadas_compresion_cal_20260517 bj ON bj.id = j.id
WHERE j.estado = 'PENDIENTE'
  AND (
        NOT (j.inicio <=> bj.inicio)
     OR NOT (j.inicio_en <=> bj.inicio_en)
     OR NOT (j.fin <=> bj.fin)
  )
ORDER BY j.id_liga, j.numero;

-- =============================================================================
-- 2) Partidos en jornadas PENDIENTE vs backup
-- =============================================================================
SELECT
    'partidos_diferentes_vs_backup_real' AS check_type,
    COUNT(*) AS filas_con_diferencias
FROM partidos_jornada pj
INNER JOIN bak_partidos_compresion_cal_20260517 bp ON bp.id = pj.id
INNER JOIN jornadas j ON j.id = pj.id_jornada
WHERE j.estado = 'PENDIENTE'
  AND NOT (pj.inicio_en <=> bp.inicio_en);

SELECT
    pj.id AS id_partido,
    pj.id_jornada,
    j.id_liga,
    j.numero,
    bp.inicio_en AS inicio_en_backup,
    pj.inicio_en AS inicio_en_live,
    bp.estado AS estado_backup,
    pj.estado AS estado_live
FROM partidos_jornada pj
INNER JOIN bak_partidos_compresion_cal_20260517 bp ON bp.id = pj.id
INNER JOIN jornadas j ON j.id = pj.id_jornada
WHERE j.estado = 'PENDIENTE'
  AND NOT (pj.inicio_en <=> bp.inicio_en)
ORDER BY j.id_liga, j.numero, pj.id
LIMIT 200;

-- =============================================================================
-- 3) Cobertura backup jornadas / partidos
-- =============================================================================
SELECT 'jornadas_en_backup_sin_live' AS check_type, COUNT(*) AS n
FROM bak_jornadas_compresion_cal_20260517 bj
LEFT JOIN jornadas j ON j.id = bj.id
WHERE j.id IS NULL;

SELECT 'jornadas_pendiente_sin_backup' AS check_type, COUNT(*) AS n
FROM jornadas j
WHERE j.estado = 'PENDIENTE'
  AND NOT EXISTS (
      SELECT 1 FROM bak_jornadas_compresion_cal_20260517 bj WHERE bj.id = j.id
  );

-- =============================================================================
-- 4) ligas.fin_en — JOIN por id_liga (PK del backup, no existe columna id)
-- Solo ligas que fueron respaldadas en bak_ligas_fin_en_*
-- =============================================================================
SELECT
    'ligas_fin_en_diferentes_vs_backup_real' AS check_type,
    COUNT(*) AS filas_con_diferencias
FROM ligas l
INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 bl ON bl.id_liga = l.id
WHERE NOT (bl.fin_en <=> l.fin_en);

SELECT
    l.id AS id_liga,
    l.nombre,
    bl.fin_en AS fin_en_backup,
    l.fin_en AS fin_en_live,
    CASE
        WHEN bl.fin_en <=> l.fin_en THEN 'OK'
        ELSE 'DIFF'
    END AS estado
FROM ligas l
INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 bl ON bl.id_liga = l.id
WHERE NOT (bl.fin_en <=> l.fin_en)
ORDER BY l.id;

SELECT 'ligas_en_backup_sin_live' AS check_type, COUNT(*) AS n
FROM bak_ligas_fin_en_compresion_cal_20260517 bl
LEFT JOIN ligas l ON l.id = bl.id_liga
WHERE l.id IS NULL;

SELECT 'ligas_con_pendiente_sin_backup_fin_en' AS check_type, COUNT(*) AS n
FROM ligas l
WHERE EXISTS (
    SELECT 1 FROM jornadas j
    WHERE j.id_liga = l.id AND j.estado = 'PENDIENTE'
)
AND NOT EXISTS (
    SELECT 1 FROM bak_ligas_fin_en_compresion_cal_20260517 bl
    WHERE bl.id_liga = l.id
);

-- =============================================================================
-- 5) Resumen global (esperado: 0, 0, 0)
-- =============================================================================
SELECT
    (
        SELECT COUNT(*)
        FROM jornadas j
        INNER JOIN bak_jornadas_compresion_cal_20260517 bj ON bj.id = j.id
        WHERE j.estado = 'PENDIENTE'
          AND (
                NOT (j.inicio <=> bj.inicio)
             OR NOT (j.inicio_en <=> bj.inicio_en)
             OR NOT (j.fin <=> bj.fin)
          )
    ) AS jornadas_diferentes_vs_backup_real,
    (
        SELECT COUNT(*)
        FROM partidos_jornada pj
        INNER JOIN bak_partidos_compresion_cal_20260517 bp ON bp.id = pj.id
        INNER JOIN jornadas j ON j.id = pj.id_jornada
        WHERE j.estado = 'PENDIENTE'
          AND NOT (pj.inicio_en <=> bp.inicio_en)
    ) AS partidos_diferentes_vs_backup_real,
    (
        SELECT COUNT(*)
        FROM ligas l
        INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 bl ON bl.id_liga = l.id
        WHERE NOT (bl.fin_en <=> l.fin_en)
    ) AS ligas_fin_en_diferentes_vs_backup_real;
