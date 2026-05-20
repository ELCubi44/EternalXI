-- =============================================================================
-- SQL MANUAL: Comprimir calendario de ligas existentes (solo jornadas PENDIENTE)
-- Fecha: 2026-05-17
-- =============================================================================
--
-- NO EJECUTAR EN PRODUCCIÓN SIN REVISAR PREVIEW Y VALIDACIONES.
-- Recomendado: desactivar automation durante la ventana:
--   app.league.automation.enabled=false
--
-- Qué hace:
--   - Backup real de jornadas/partidos afectados (+ fin_en de ligas)
--   - Reprograma jornadas PENDIENTE alternando mar-mié / vie-dom
--   - Solo partidos_jornada PENDIENTE
--   - Idempotente: no re-aplica si inicio_en ya difiere del backup
--
-- Orden: por j.numero ASC entre PENDIENTE (caso liga 8: J4 PENDIENTE con J5 EN_CURSO
--   → J4 se coloca DESPUÉS del fin de J5, no antes).
--
-- Zona horaria sesión (ajustar si el servidor no está en Madrid):
--   SET time_zone = 'Europe/Madrid';
--
-- Alternativa recomendada para APPLY (recalcula cadena completa por liga, valida liga 8):
--   mvn -q exec:java -Dexec.mainClass="com.eternalxi.eternalxi_api.tools.LeagueCalendarCompressionTool" -Dexec.args="preview"
--   mvn -q exec:java -Dexec.mainClass="com.eternalxi.eternalxi_api.tools.LeagueCalendarCompressionTool" -Dexec.args="apply"
--   mvn -q exec:java -Dexec.mainClass="com.eternalxi.eternalxi_api.tools.LeagueCalendarCompressionTool" -Dexec.args="rollback"
--
-- Orden de ejecución SQL: 1 → 2 → 3 → 4 → 5 (revisar) → 6 (descomentar) → 7
--
-- =============================================================================
-- SECCIÓN 0 — CONFIGURACIÓN
-- =============================================================================

SET NAMES utf8mb4;
SET @MIGRATION_TAG = '20260517_calendario_compresion';

-- Descomentar en servidor si hace falta:
-- SET time_zone = 'Europe/Madrid';

-- =============================================================================
-- SECCIÓN 1 — PRE-VALIDACIONES (solo lectura)
-- =============================================================================

-- 1.1 Ligas con jornadas PENDIENTE cuyo número es menor que alguna EN_CURSO/FINALIZADA
--     (caso liga 8: J4 PENDIENTE + J5 EN_CURSO). Informativo, no bloquea.
SELECT
    j.id_liga,
    l.nombre AS liga,
    MIN(CASE WHEN j.estado = 'PENDIENTE' THEN j.numero END) AS min_num_pendiente,
    MAX(CASE WHEN j.estado = 'EN_CURSO' THEN j.numero END) AS max_num_en_curso,
    MAX(CASE WHEN j.estado = 'FINALIZADA' THEN j.numero END) AS max_num_finalizada,
    GROUP_CONCAT(
        DISTINCT CONCAT('J', j.numero, ':', j.estado)
        ORDER BY j.numero
        SEPARATOR ', '
    ) AS resumen_jornadas
FROM jornadas j
INNER JOIN ligas l ON l.id = j.id_liga
WHERE j.id_liga IN (SELECT DISTINCT id_liga FROM jornadas WHERE estado = 'PENDIENTE')
GROUP BY j.id_liga, l.nombre
HAVING min_num_pendiente IS NOT NULL
   AND (
        (max_num_en_curso IS NOT NULL AND min_num_pendiente < max_num_en_curso)
     OR (max_num_finalizada IS NOT NULL AND min_num_pendiente < max_num_finalizada)
   )
ORDER BY j.id_liga;

-- 1.2 Liga 8 (caso explícito)
SELECT
    j.id AS id_jornada,
    j.id_liga,
    l.nombre AS liga,
    j.numero,
    j.estado,
    j.inicio,
    j.inicio_en,
    j.fin,
    (SELECT MIN(pj.inicio_en) FROM partidos_jornada pj WHERE pj.id_jornada = j.id) AS primer_partido,
    (SELECT MAX(pj.inicio_en) FROM partidos_jornada pj WHERE pj.id_jornada = j.id) AS ultimo_partido
FROM jornadas j
INNER JOIN ligas l ON l.id = j.id_liga
WHERE j.id_liga = 8
ORDER BY j.numero;

-- 1.3 Partidos NO pendientes dentro de jornadas pendientes (debe devolver 0 filas)
SELECT
    j.id_liga,
    j.id AS id_jornada,
    j.numero,
    pj.id AS id_partido,
    pj.estado
FROM jornadas j
INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id
WHERE j.estado = 'PENDIENTE'
  AND pj.estado <> 'PENDIENTE'
ORDER BY j.id_liga, j.numero, pj.id;

-- 1.4 Jornadas pendientes con más de 8 partidos pendientes (no caben en un bloque)
SELECT
    j.id_liga,
    l.nombre AS liga,
    j.id AS id_jornada,
    j.numero,
    COUNT(pj.id) AS partidos_pendientes
FROM jornadas j
INNER JOIN ligas l ON l.id = j.id_liga
INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id AND pj.estado = 'PENDIENTE'
WHERE j.estado = 'PENDIENTE'
GROUP BY j.id_liga, l.nombre, j.id, j.numero
HAVING COUNT(pj.id) > 8
ORDER BY j.id_liga, j.numero;

-- =============================================================================
-- SECCIÓN 2 — TABLAS DE BACKUP Y PLAN (persistentes para preview / idempotencia)
-- =============================================================================

CREATE TABLE IF NOT EXISTS bak_jornadas_compresion_cal_20260517 (
    id              BIGINT       NOT NULL PRIMARY KEY,
    id_liga         BIGINT       NOT NULL,
    numero          INT          NOT NULL,
    inicio          DATE         NULL,
    inicio_en       DATETIME     NULL,
    fin             DATE         NULL,
    estado          VARCHAR(32)  NOT NULL,
    backed_up_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    migration_tag   VARCHAR(64)  NOT NULL DEFAULT '20260517_calendario_compresion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bak_partidos_compresion_cal_20260517 (
    id              BIGINT       NOT NULL PRIMARY KEY,
    id_jornada      BIGINT       NOT NULL,
    inicio_en       DATETIME     NULL,
    estado          VARCHAR(32)  NOT NULL,
    backed_up_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    migration_tag   VARCHAR(64)  NOT NULL DEFAULT '20260517_calendario_compresion',
    KEY idx_jornada (id_jornada)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bak_ligas_fin_en_compresion_cal_20260517 (
    id_liga         BIGINT       NOT NULL PRIMARY KEY,
    fin_en          DATE         NULL,
    backed_up_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    migration_tag   VARCHAR(64)  NOT NULL DEFAULT '20260517_calendario_compresion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS plan_compresion_calendario_20260517 (
    id_jornada              BIGINT       NOT NULL PRIMARY KEY,
    id_liga                 BIGINT       NOT NULL,
    numero                  INT          NOT NULL,
    rn                      INT          NOT NULL,
    block_type              TINYINT      NOT NULL COMMENT '0=mar-mie, 1=vie-dom',
    block_start             DATE         NOT NULL,
    inicio                  DATE         NOT NULL,
    inicio_en               DATETIME     NOT NULL,
    fin                     DATE         NOT NULL,
    primer_partido_nuevo    DATETIME     NOT NULL,
    ultimo_partido_nuevo    DATETIME     NOT NULL,
    num_partidos_pendientes INT          NOT NULL,
    computed_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_liga_rn (id_liga, rn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Slots por bloque (8 partidos máx.)
DROP TEMPORARY TABLE IF EXISTS tmp_slot_def;
CREATE TEMPORARY TABLE tmp_slot_def (
    block_type   TINYINT NOT NULL,
    slot_idx     TINYINT NOT NULL,
    day_offset   TINYINT NOT NULL,
    slot_time    TIME    NOT NULL,
    PRIMARY KEY (block_type, slot_idx)
);

INSERT INTO tmp_slot_def (block_type, slot_idx, day_offset, slot_time) VALUES
-- Entre semana: martes + miércoles, 4 slots/día
(0, 0, 0, '17:00:00'),
(0, 1, 0, '18:30:00'),
(0, 2, 0, '20:00:00'),
(0, 3, 0, '21:30:00'),
(0, 4, 1, '17:00:00'),
(0, 5, 1, '18:30:00'),
(0, 6, 1, '20:00:00'),
(0, 7, 1, '21:30:00'),
-- Fin de semana: vie + sáb + dom
(1, 0, 0, '17:00:00'),
(1, 1, 0, '19:00:00'),
(1, 2, 1, '17:00:00'),
(1, 3, 1, '19:00:00'),
(1, 4, 1, '21:00:00'),
(1, 5, 2, '17:00:00'),
(1, 6, 2, '19:00:00'),
(1, 7, 2, '21:00:00');

-- -----------------------------------------------------------------------------
-- Función auxiliar: primer día de la semana (WEEKDAY Mon=0) estrictamente DESPUÉS de d
-- target_wd: 1=martes, 4=viernes
-- -----------------------------------------------------------------------------
-- Se usa inline: DATE_ADD(d, INTERVAL 1 + MOD(target_wd - WEEKDAY(DATE_ADD(d, INTERVAL 1 DAY)) + 7, 7) DAY)

-- =============================================================================
-- SECCIÓN 3 — BACKUP (idempotente: no sobrescribe filas ya respaldadas)
-- Reejecutar preview: TRUNCATE plan (sección 4) es seguro; bak_* no duplica filas.
-- Para forzar backup desde cero: TRUNCATE bak_jornadas/partidos/ligas_fin_en_* antes de sección 3.
-- =============================================================================

INSERT INTO bak_jornadas_compresion_cal_20260517 (id, id_liga, numero, inicio, inicio_en, fin, estado)
SELECT j.id, j.id_liga, j.numero, j.inicio, j.inicio_en, j.fin, j.estado
FROM jornadas j
WHERE j.estado = 'PENDIENTE'
  AND NOT EXISTS (
      SELECT 1 FROM bak_jornadas_compresion_cal_20260517 b WHERE b.id = j.id
  );

INSERT INTO bak_partidos_compresion_cal_20260517 (id, id_jornada, inicio_en, estado)
SELECT pj.id, pj.id_jornada, pj.inicio_en, pj.estado
FROM partidos_jornada pj
INNER JOIN jornadas j ON j.id = pj.id_jornada
WHERE j.estado = 'PENDIENTE'
  AND pj.estado = 'PENDIENTE'
  AND NOT EXISTS (
      SELECT 1 FROM bak_partidos_compresion_cal_20260517 b WHERE b.id = pj.id
  );

INSERT INTO bak_ligas_fin_en_compresion_cal_20260517 (id_liga, fin_en)
SELECT l.id, l.fin_en
FROM ligas l
WHERE EXISTS (
    SELECT 1 FROM jornadas j
    WHERE j.id_liga = l.id AND j.estado = 'PENDIENTE'
)
AND NOT EXISTS (
    SELECT 1 FROM bak_ligas_fin_en_compresion_cal_20260517 b WHERE b.id_liga = l.id
);

-- =============================================================================
-- SECCIÓN 4 — CALCULAR PLAN (recursive CTE por liga / jornada pendiente)
-- =============================================================================

TRUNCATE TABLE plan_compresion_calendario_20260517;

WITH
league_anchor AS (
    SELECT
        l.id AS id_liga,
        GREATEST(
            COALESCE((
                SELECT MAX(j2.fin)
                FROM jornadas j2
                WHERE j2.id_liga = l.id
                  AND j2.estado IN ('EN_CURSO', 'FINALIZADA')
            ), DATE('1970-01-01')),
            CURDATE()
        ) AS cursor_fecha
    FROM ligas l
    WHERE EXISTS (
        SELECT 1 FROM jornadas j WHERE j.id_liga = l.id AND j.estado = 'PENDIENTE'
    )
),
pending AS (
    SELECT
        j.id   AS id_jornada,
        j.id_liga,
        j.numero,
        ROW_NUMBER() OVER (PARTITION BY j.id_liga ORDER BY j.numero ASC, j.id ASC) AS rn,
        (
            SELECT COUNT(*)
            FROM partidos_jornada pj
            WHERE pj.id_jornada = j.id
              AND pj.estado = 'PENDIENTE'
        ) AS num_partidos_pendientes
    FROM jornadas j
    WHERE j.estado = 'PENDIENTE'
),
round_schedule AS (
    -- Primera jornada pendiente de cada liga
    SELECT
        p.id_jornada,
        p.id_liga,
        p.numero,
        p.rn,
        p.num_partidos_pendientes,
        la.cursor_fecha AS prev_end,
        CASE
            WHEN DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(1 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 ) <= DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(4 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 )
            THEN CAST(0 AS SIGNED)
            ELSE CAST(1 AS SIGNED)
        END AS block_type,
        CASE
            WHEN DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(1 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 ) <= DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(4 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 )
            THEN DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(1 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 )
            ELSE DATE_ADD(
                     la.cursor_fecha,
                     INTERVAL 1 + MOD(4 - WEEKDAY(DATE_ADD(la.cursor_fecha, INTERVAL 1 DAY)) + 7, 7) DAY
                 )
        END AS block_start
    FROM pending p
    INNER JOIN league_anchor la ON la.id_liga = p.id_liga
    WHERE p.rn = 1

    UNION ALL

    -- Siguientes jornadas pendientes: alternar bloque tras fin del bloque anterior
    SELECT
        p.id_jornada,
        p.id_liga,
        p.numero,
        p.rn,
        p.num_partidos_pendientes,
        CASE rs.block_type
            WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)  -- miércoles
            ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)         -- domingo
        END AS prev_end,
        CAST(1 - rs.block_type AS SIGNED) AS block_type,
        CASE (1 - rs.block_type)
            WHEN 0 THEN DATE_ADD(
                CASE rs.block_type
                    WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)
                    ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)
                END,
                INTERVAL 1 + MOD(1 - WEEKDAY(
                    DATE_ADD(
                        CASE rs.block_type
                            WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)
                            ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)
                        END,
                        INTERVAL 1 DAY
                    )
                ) + 7, 7) DAY
            )
            ELSE DATE_ADD(
                CASE rs.block_type
                    WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)
                    ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)
                END,
                INTERVAL 1 + MOD(4 - WEEKDAY(
                    DATE_ADD(
                        CASE rs.block_type
                            WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)
                            ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)
                        END,
                        INTERVAL 1 DAY
                    )
                ) + 7, 7) DAY
            )
        END AS block_start
    FROM round_schedule rs
    INNER JOIN pending p
        ON p.id_liga = rs.id_liga
       AND p.rn = rs.rn + 1
),
plan_base AS (
    SELECT
        rs.id_jornada,
        rs.id_liga,
        rs.numero,
        rs.rn,
        rs.block_type,
        rs.block_start,
        rs.block_start AS inicio,
        CASE rs.block_type
            WHEN 0 THEN DATE_ADD(rs.block_start, INTERVAL 1 DAY)
            ELSE DATE_ADD(rs.block_start, INTERVAL 2 DAY)
        END AS fin,
        rs.num_partidos_pendientes,
        TIMESTAMP(rs.block_start, '17:00:00') AS primer_slot_ts
    FROM round_schedule rs
)
INSERT INTO plan_compresion_calendario_20260517 (
    id_jornada,
    id_liga,
    numero,
    rn,
    block_type,
    block_start,
    inicio,
    inicio_en,
    fin,
    primer_partido_nuevo,
    ultimo_partido_nuevo,
    num_partidos_pendientes
)
SELECT
    pb.id_jornada,
    pb.id_liga,
    pb.numero,
    pb.rn,
    pb.block_type,
    pb.block_start,
    pb.inicio,
    CASE pb.block_type
        WHEN 0 THEN TIMESTAMP(pb.block_start, '17:00:00')
        ELSE TIMESTAMP(pb.block_start, '17:00:00')
    END AS inicio_en,
    pb.fin,
    CASE pb.block_type
        WHEN 0 THEN TIMESTAMP(pb.block_start, '17:00:00')
        ELSE TIMESTAMP(pb.block_start, '17:00:00')
    END AS primer_partido_nuevo,
    CASE pb.block_type
        WHEN 0 THEN TIMESTAMP(DATE_ADD(pb.block_start, INTERVAL 1 DAY), '21:30:00')
        ELSE TIMESTAMP(DATE_ADD(pb.block_start, INTERVAL 2 DAY), '21:00:00')
    END AS ultimo_partido_nuevo,
    pb.num_partidos_pendientes
FROM plan_base pb;

-- Si 5.2 devuelve filas con kickoff en el pasado, NO aplicar sección 6: usar la herramienta Java
-- o recalcular manualmente el cursor de esas ligas.

-- =============================================================================
-- SECCIÓN 5 — PREVIEW (ejecutar y revisar ANTES del UPDATE)
-- Solo jornadas/partidos PENDIENTE en plan y backup.
-- =============================================================================

SELECT
    p.id_liga,
    l.nombre AS liga,
    p.numero AS numero_jornada,
    j.estado,
    b.inicio AS inicio_actual,
    p.inicio AS inicio_nuevo,
    b.fin AS fin_actual,
    p.fin AS fin_nuevo,
    (
        SELECT MIN(bpj.inicio_en)
        FROM bak_partidos_compresion_cal_20260517 bpj
        WHERE bpj.id_jornada = p.id_jornada
          AND bpj.estado = 'PENDIENTE'
    ) AS primer_partido_actual,
    p.primer_partido_nuevo,
    (
        SELECT MAX(bpj.inicio_en)
        FROM bak_partidos_compresion_cal_20260517 bpj
        WHERE bpj.id_jornada = p.id_jornada
          AND bpj.estado = 'PENDIENTE'
    ) AS ultimo_partido_actual,
    p.ultimo_partido_nuevo,
    CASE
        WHEN p.primer_partido_nuevo > COALESCE((
            SELECT MAX(pj.inicio_en)
            FROM jornadas jx
            INNER JOIN partidos_jornada pj ON pj.id_jornada = jx.id
            WHERE jx.id_liga = p.id_liga
              AND jx.estado IN ('EN_CURSO', 'FINALIZADA')
              AND jx.numero > p.numero
        ), TIMESTAMP('1970-01-01 00:00:00'))
        THEN 'OK'
        ELSE 'ERROR: pendiente antes de jornada superior activa/cerrada'
    END AS validacion_orden,
    CASE p.block_type WHEN 0 THEN 'MAR-MIE' ELSE 'VIE-DOM' END AS bloque,
    p.rn AS orden_pendiente_en_liga,
    p.num_partidos_pendientes
FROM plan_compresion_calendario_20260517 p
INNER JOIN ligas l ON l.id = p.id_liga
INNER JOIN jornadas j ON j.id = p.id_jornada AND j.estado = 'PENDIENTE'
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = p.id_jornada
ORDER BY p.id_liga, p.numero;

-- 5.1 Liga 8 — J4 PENDIENTE debe quedar DESPUÉS de J5 EN_CURSO (obligatorio OK)
SELECT
    p.id_liga,
    l.nombre AS liga,
    p.numero AS jornada_pendiente,
    j5.numero AS jornada_en_curso_ref,
    j5.estado AS estado_j5,
    j5.fin AS fin_j5,
    (
        SELECT MAX(pj.inicio_en)
        FROM partidos_jornada pj
        WHERE pj.id_jornada = j5.id
    ) AS ultimo_partido_j5_en_curso,
    p.primer_partido_nuevo AS primer_partido_j4_nuevo,
    CASE
        WHEN p.primer_partido_nuevo > COALESCE((
            SELECT MAX(pj.inicio_en)
            FROM partidos_jornada pj
            WHERE pj.id_jornada = j5.id
        ), TIMESTAMP(j5.fin, '23:59:59'))
        THEN 'OK: J4 despues de J5'
        ELSE 'ERROR: J4 quedaria antes o durante J5'
    END AS validacion_liga_8_j4_vs_j5
FROM plan_compresion_calendario_20260517 p
INNER JOIN ligas l ON l.id = p.id_liga
INNER JOIN jornadas j5
    ON j5.id_liga = p.id_liga
   AND j5.numero = 5
   AND j5.estado = 'EN_CURSO'
WHERE p.id_liga = 8
  AND p.numero = 4;

-- 5.2 Kickoffs en el pasado (debe estar vacío)
SELECT *
FROM plan_compresion_calendario_20260517
WHERE primer_partido_nuevo <= NOW();

-- 5.3 Partidos con más slots de los disponibles
SELECT *
FROM plan_compresion_calendario_20260517
WHERE num_partidos_pendientes > 8;

-- =============================================================================
-- SECCIÓN 6 — APLICAR CAMBIOS
-- =============================================================================
-- DETENER AQUÍ y confirmar preview. Luego descomentar y ejecutar en transacción.

/*
START TRANSACTION;

-- Recrear slots en la misma sesión (tabla temporal)
DROP TEMPORARY TABLE IF EXISTS tmp_slot_def;
CREATE TEMPORARY TABLE tmp_slot_def (
    block_type   TINYINT NOT NULL,
    slot_idx     TINYINT NOT NULL,
    day_offset   TINYINT NOT NULL,
    slot_time    TIME    NOT NULL,
    PRIMARY KEY (block_type, slot_idx)
);
INSERT INTO tmp_slot_def (block_type, slot_idx, day_offset, slot_time) VALUES
(0, 0, 0, '17:00:00'), (0, 1, 0, '18:30:00'), (0, 2, 0, '20:00:00'), (0, 3, 0, '21:30:00'),
(0, 4, 1, '17:00:00'), (0, 5, 1, '18:30:00'), (0, 6, 1, '20:00:00'), (0, 7, 1, '21:30:00'),
(1, 0, 0, '17:00:00'), (1, 1, 0, '19:00:00'),
(1, 2, 1, '17:00:00'), (1, 3, 1, '19:00:00'), (1, 4, 1, '21:00:00'),
(1, 5, 2, '17:00:00'), (1, 6, 2, '19:00:00'), (1, 7, 2, '21:00:00');

-- 6.1 Jornadas (solo PENDIENTE e inicio_en sin cambiar manualmente desde backup)
UPDATE jornadas j
INNER JOIN plan_compresion_calendario_20260517 p ON p.id_jornada = j.id
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = j.id
SET
    j.inicio    = p.inicio,
    j.inicio_en = p.inicio_en,
    j.fin       = p.fin
WHERE j.estado = 'PENDIENTE'
  AND (j.inicio_en <=> b.inicio_en);

-- 6.2 Partidos (orden preservado por inicio_en de backup + id)
UPDATE partidos_jornada pj
INNER JOIN (
    SELECT
        pj2.id,
        pj2.id_jornada,
        p.block_type,
        p.block_start,
        ROW_NUMBER() OVER (
            PARTITION BY pj2.id_jornada
            ORDER BY COALESCE(b.inicio_en, pj2.inicio_en), pj2.id
        ) - 1 AS slot_idx
    FROM partidos_jornada pj2
    INNER JOIN plan_compresion_calendario_20260517 p ON p.id_jornada = pj2.id_jornada
    INNER JOIN bak_partidos_compresion_cal_20260517 b ON b.id = pj2.id
    INNER JOIN jornadas j ON j.id = pj2.id_jornada
    WHERE j.estado = 'PENDIENTE'
      AND pj2.estado = 'PENDIENTE'
) ranked ON ranked.id = pj.id
INNER JOIN tmp_slot_def s
    ON s.block_type = ranked.block_type
   AND s.slot_idx = ranked.slot_idx
INNER JOIN bak_partidos_compresion_cal_20260517 b ON b.id = pj.id
SET pj.inicio_en = TIMESTAMP(
        DATE_ADD(ranked.block_start, INTERVAL s.day_offset DAY),
        s.slot_time
    )
WHERE pj.estado = 'PENDIENTE'
  AND (pj.inicio_en <=> b.inicio_en);

-- 6.3 Recalcular inicio_en / fin de jornada desde partidos (coherencia)
UPDATE jornadas j
INNER JOIN (
    SELECT
        pj.id_jornada,
        MIN(pj.inicio_en) AS min_inicio_en,
        MIN(DATE(pj.inicio_en)) AS min_inicio,
        MAX(DATE(pj.inicio_en)) AS max_fin
    FROM partidos_jornada pj
    INNER JOIN jornadas j2 ON j2.id = pj.id_jornada
    WHERE j2.estado = 'PENDIENTE'
      AND pj.estado = 'PENDIENTE'
    GROUP BY pj.id_jornada
) agg ON agg.id_jornada = j.id
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = j.id
SET
    j.inicio    = agg.min_inicio,
    j.inicio_en = agg.min_inicio_en,
    j.fin       = agg.max_fin
WHERE j.estado = 'PENDIENTE'
  AND (j.inicio_en <=> b.inicio_en);

-- 6.4 fin_en de liga = MAX(fin) de todas sus jornadas
UPDATE ligas l
INNER JOIN (
    SELECT id_liga, MAX(fin) AS nuevo_fin_en
    FROM jornadas
    GROUP BY id_liga
) x ON x.id_liga = l.id
INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 bl ON bl.id_liga = l.id
SET l.fin_en = x.nuevo_fin_en
WHERE EXISTS (
    SELECT 1 FROM jornadas j
    WHERE j.id_liga = l.id AND j.estado = 'PENDIENTE'
);

COMMIT;
*/

-- =============================================================================
-- SECCIÓN 7 — POST-VERIFICACIÓN (tras COMMIT del bloque anterior)
-- =============================================================================

/*
SELECT
    j.id_liga,
    l.nombre AS liga,
    j.numero AS jornada,
    b.inicio AS inicio_backup,
    j.inicio AS inicio_actual,
    b.inicio_en AS inicio_en_backup,
    j.inicio_en AS inicio_en_actual,
    b.fin AS fin_backup,
    j.fin AS fin_actual,
    (
        SELECT MIN(pj.inicio_en)
        FROM partidos_jornada pj
        WHERE pj.id_jornada = j.id AND pj.estado = 'PENDIENTE'
    ) AS primer_partido_actual,
    (
        SELECT MAX(pj.inicio_en)
        FROM partidos_jornada pj
        WHERE pj.id_jornada = j.id AND pj.estado = 'PENDIENTE'
    ) AS ultimo_partido_actual,
    j.estado
FROM jornadas j
INNER JOIN ligas l ON l.id = j.id_liga
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = j.id
WHERE j.estado = 'PENDIENTE'
ORDER BY j.id_liga, j.numero;

-- Jornadas que no se actualizaron (inicio_en tocado a mano o ya migradas)
SELECT j.id, j.id_liga, j.numero, j.inicio_en, b.inicio_en AS backup_inicio_en
FROM jornadas j
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = j.id
WHERE j.estado = 'PENDIENTE'
  AND NOT (j.inicio_en <=> b.inicio_en)
  AND j.inicio <> b.inicio;

-- Liga 8 detalle
SELECT j.numero, j.estado, j.inicio, j.fin, j.inicio_en,
       (SELECT MIN(pj.inicio_en) FROM partidos_jornada pj WHERE pj.id_jornada = j.id) AS primer_p,
       (SELECT MAX(pj.inicio_en) FROM partidos_jornada pj WHERE pj.id_jornada = j.id) AS ultimo_p
FROM jornadas j
WHERE j.id_liga = 8
ORDER BY j.numero;

-- fin_en ligas afectadas
SELECT l.id, l.nombre, bl.fin_en AS fin_en_backup, l.fin_en AS fin_en_actual
FROM ligas l
INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 bl ON bl.id_liga = l.id;
*/

-- =============================================================================
-- SECCIÓN 8 — ROLLBACK COMPLETO
-- =============================================================================
-- Ejecutar solo si hay que deshacer. Restaura jornadas/partidos PENDIENTE desde backup
-- y fin_en de ligas respaldadas.

/*
START TRANSACTION;

UPDATE jornadas j
INNER JOIN bak_jornadas_compresion_cal_20260517 b ON b.id = j.id
SET
    j.inicio    = b.inicio,
    j.inicio_en = b.inicio_en,
    j.fin       = b.fin
WHERE j.estado = 'PENDIENTE';

UPDATE partidos_jornada pj
INNER JOIN bak_partidos_compresion_cal_20260517 b ON b.id = pj.id
SET
    pj.inicio_en = b.inicio_en
WHERE pj.estado = 'PENDIENTE';

UPDATE ligas l
INNER JOIN bak_ligas_fin_en_compresion_cal_20260517 b ON b.id_liga = l.id
SET l.fin_en = b.fin_en;

COMMIT;
*/

-- Opcional: eliminar tablas de backup/plan tras rollback verificado
-- DROP TABLE IF EXISTS plan_compresion_calendario_20260517;
-- DROP TABLE IF EXISTS bak_partidos_compresion_cal_20260517;
-- DROP TABLE IF EXISTS bak_jornadas_compresion_cal_20260517;
-- DROP TABLE IF EXISTS bak_ligas_fin_en_compresion_cal_20260517;
