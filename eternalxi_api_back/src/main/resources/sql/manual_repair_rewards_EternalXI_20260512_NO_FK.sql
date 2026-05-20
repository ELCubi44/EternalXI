-- =============================================================================
-- EternalXI — Reparación manual SIN FOREIGN KEYS (desbloqueo producción)
-- Mismo común + mismas tablas que manual_repair_rewards_EternalXI_20260512.sql
-- pero sin CONSTRAINT ... FOREIGN KEY (solo PK, UNIQUE donde aplica, índices).
-- Use si la variante con FK falla (errno 150, tipos incompatibles, etc.).
-- NO ejecute este fichero completo si ya aplicó con éxito la variante A del otro fichero
-- (los CREATE IF NOT EXISTS saltarán; los CREATE INDEX pueden fallar por duplicado).
-- =============================================================================

USE EternalXI;

SET @db := DATABASE();
SET @q := IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'usuario_recursos' AND COLUMN_NAME = 'puntos_recompensa') = 0,
    'ALTER TABLE usuario_recursos ADD COLUMN puntos_recompensa BIGINT NOT NULL DEFAULT 0',
    'SELECT 1'
);
PREPARE stmt FROM @q;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP PROCEDURE IF EXISTS _eternalxi_prep_lpc_rename;
DELIMITER $$
CREATE PROCEDURE _eternalxi_prep_lpc_rename()
proc_exit: BEGIN
    DECLARE v_schema VARCHAR(64) DEFAULT DATABASE();
    DECLARE v_t_lpc INT DEFAULT 0;
    DECLARE v_legacy INT DEFAULT 0;
    DECLARE v_has_new INT DEFAULT 0;
    DECLARE v_rows BIGINT DEFAULT 0;

    SELECT COUNT(*) INTO v_t_lpc
    FROM information_schema.tables
    WHERE table_schema = v_schema AND table_name = 'liga_participante_cartas';

    IF v_t_lpc = 0 THEN
        LEAVE proc_exit;
    END IF;

    SELECT COUNT(*) INTO v_has_new
    FROM information_schema.columns
    WHERE table_schema = v_schema AND table_name = 'liga_participante_cartas'
      AND column_name = 'id_definicion_carta';

    IF v_has_new > 0 THEN
        LEAVE proc_exit;
    END IF;

    SELECT COUNT(*) INTO v_rows FROM liga_participante_cartas;
    IF v_rows > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'liga_participante_cartas tiene filas (esquema antiguo). No se renombra.';
    END IF;

    SELECT COUNT(*) INTO v_legacy
    FROM information_schema.tables
    WHERE table_schema = v_schema AND table_name = 'liga_participante_cartas_legacy_empty_20260512';

    IF v_legacy > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe liga_participante_cartas_legacy_empty_20260512. DROP si vacía, o renómbrela, y re-ejecute.';
    END IF;

    RENAME TABLE liga_participante_cartas TO liga_participante_cartas_legacy_empty_20260512;
END$$
DELIMITER ;

CALL _eternalxi_prep_lpc_rename();
DROP PROCEDURE IF EXISTS _eternalxi_prep_lpc_rename;

-- ---------------------------------------------------------------------------
-- Tablas nuevas (sin FK)
-- ---------------------------------------------------------------------------

SET @db := DATABASE();

CREATE TABLE IF NOT EXISTS definiciones_carta (
    id INT NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(80) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    rareza VARCHAR(30) NOT NULL,
    tipo_efecto VARCHAR(60) NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    parametros_json TEXT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT uk_definiciones_carta_codigo UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS liga_participante_cartas (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga_participante INT NOT NULL,
    id_definicion_carta INT NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE',
    obtenido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    usado_en TIMESTAMP(3) NULL,
    metadata_json TEXT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX idx_lpc_participante_estado ON liga_participante_cartas (id_liga_participante, estado);
CREATE INDEX idx_lpc_definicion ON liga_participante_cartas (id_definicion_carta);
CREATE INDEX idx_lpc_estado ON liga_participante_cartas (estado);

CREATE TABLE IF NOT EXISTS liga_participante_ruleta_entrenador (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga_participante INT NOT NULL,
    id_entrenador_asignado INT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    usado_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_liga_participante_ruleta UNIQUE (id_liga_participante)
);

CREATE TABLE IF NOT EXISTS liga_jugador_protecciones (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga INT NOT NULL,
    id_liga_jugador INT NOT NULL,
    id_liga_participante INT NOT NULL,
    id_carta_origen INT NULL,
    id_jornada_inicio INT NULL,
    id_jornada_fin INT NULL,
    hasta_fin_temporada BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expira_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id)
);

CREATE INDEX idx_proteccion_liga_jugador_activa ON liga_jugador_protecciones (id_liga, id_liga_jugador, activo);
CREATE INDEX idx_proteccion_participante ON liga_jugador_protecciones (id_liga_participante);
CREATE INDEX idx_proteccion_carta ON liga_jugador_protecciones (id_carta_origen);

CREATE TABLE IF NOT EXISTS liga_participante_puntos_bonus (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga_participante INT NOT NULL,
    id_carta_origen INT NULL,
    puntos INT NOT NULL,
    motivo VARCHAR(200) NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
);

CREATE INDEX idx_bonus_participante ON liga_participante_puntos_bonus (id_liga_participante);

CREATE TABLE IF NOT EXISTS liga_jugador_modificadores_valor (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga INT NOT NULL,
    id_liga_jugador INT NOT NULL,
    id_liga_participante INT NOT NULL,
    id_carta_origen INT NULL,
    tipo VARCHAR(60) NOT NULL,
    porcentaje DECIMAL(8, 4) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    id_jornada_expiracion INT NULL,
    expira_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id)
);

CREATE INDEX idx_mod_valor_liga_jugador_activo ON liga_jugador_modificadores_valor (id_liga, id_liga_jugador, activo);
CREATE INDEX idx_mod_valor_participante ON liga_jugador_modificadores_valor (id_liga_participante);
CREATE INDEX idx_mod_valor_carta ON liga_jugador_modificadores_valor (id_carta_origen);

CREATE TABLE IF NOT EXISTS liga_recompensa_eventos (
    id INT NOT NULL AUTO_INCREMENT,
    id_liga INT NOT NULL,
    id_liga_participante INT NULL,
    id_usuario INT NULL,
    tipo VARCHAR(80) NOT NULL,
    id_carta INT NULL,
    id_liga_jugador INT NULL,
    id_liga_participante_objetivo INT NULL,
    pack_type VARCHAR(40) NULL,
    cantidad BIGINT NULL,
    descripcion VARCHAR(500) NULL,
    metadata_json TEXT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
);

CREATE INDEX idx_eventos_liga_fecha ON liga_recompensa_eventos (id_liga, creado_en);
CREATE INDEX idx_eventos_participante ON liga_recompensa_eventos (id_liga_participante);
CREATE INDEX idx_eventos_tipo ON liga_recompensa_eventos (tipo);

INSERT INTO definiciones_carta (codigo, nombre, rareza, tipo_efecto, descripcion, parametros_json, activo) VALUES
('SELL_100', 'Venta Justa', 'BASIC', 'SELL_PLAYER_BONUS', 'Vende un jugador por el 100% de su valor.', '{"sellMultiplier":1.0}', TRUE),
('SELL_120', 'Venta Mejorada', 'NORMAL', 'SELL_PLAYER_BONUS', 'Vende un jugador por el 120% de su valor.', '{"sellMultiplier":1.2}', TRUE),
('SELL_140', 'Venta Premium', 'SPECIAL', 'SELL_PLAYER_BONUS', 'Vende un jugador por el 140% de su valor.', '{"sellMultiplier":1.4}', TRUE),
('SELL_160', 'Venta Maestra', 'SUPER_RARE', 'SELL_PLAYER_BONUS', 'Vende un jugador por el 160% de su valor.', '{"sellMultiplier":1.6}', TRUE),
('SELL_200', 'Venta Legendaria', 'LEGENDARY', 'SELL_PLAYER_BONUS', 'Vende un jugador por el 200% de su valor.', '{"sellMultiplier":2.0}', TRUE),
('CLAUSE_5M', 'Cláusula Menor', 'BASIC', 'DIRECT_CLAUSE', 'Ficha directamente un jugador rival de hasta 5M pagando el 120% de su valor. El propietario recibe el 100%.', '{"maxPlayerValue":5000000,"buyerMultiplier":1.2,"ownerCompensationMultiplier":1.0}', TRUE),
('CLAUSE_10M', 'Cláusula Media', 'NORMAL', 'DIRECT_CLAUSE', 'Ficha directamente un jugador rival de hasta 10M pagando el 125% de su valor. El propietario recibe el 100%.', '{"maxPlayerValue":10000000,"buyerMultiplier":1.25,"ownerCompensationMultiplier":1.0}', TRUE),
('CLAUSE_20M', 'Cláusula Especial', 'SPECIAL', 'DIRECT_CLAUSE', 'Ficha directamente un jugador rival de hasta 20M pagando el 130% de su valor. El propietario recibe el 100%.', '{"maxPlayerValue":20000000,"buyerMultiplier":1.3,"ownerCompensationMultiplier":1.0}', TRUE),
('CLAUSE_35M', 'Cláusula Élite', 'SUPER_RARE', 'DIRECT_CLAUSE', 'Ficha directamente un jugador rival de hasta 35M pagando el 140% de su valor. El propietario recibe el 100%.', '{"maxPlayerValue":35000000,"buyerMultiplier":1.4,"ownerCompensationMultiplier":1.0}', TRUE),
('CLAUSE_ANY', 'Cláusula Legendaria', 'LEGENDARY', 'DIRECT_CLAUSE', 'Ficha directamente cualquier jugador rival pagando el 150% de su valor. El propietario recibe el 100%.', '{"maxPlayerValue":null,"buyerMultiplier":1.5,"ownerCompensationMultiplier":1.0}', TRUE),
('PROTECT_1_ROUND', 'Protección Básica', 'BASIC', 'PROTECT_PLAYER', 'Protege un jugador durante 1 jornada.', '{"rounds":1,"seasonLong":false}', TRUE),
('PROTECT_2_ROUNDS', 'Protección Normal', 'NORMAL', 'PROTECT_PLAYER', 'Protege un jugador durante 2 jornadas.', '{"rounds":2,"seasonLong":false}', TRUE),
('PROTECT_4_ROUNDS', 'Protección Especial', 'SPECIAL', 'PROTECT_PLAYER', 'Protege un jugador durante 4 jornadas.', '{"rounds":4,"seasonLong":false}', TRUE),
('PROTECT_8_ROUNDS', 'Protección Élite', 'SUPER_RARE', 'PROTECT_PLAYER', 'Protege un jugador durante 8 jornadas.', '{"rounds":8,"seasonLong":false}', TRUE),
('PROTECT_SEASON', 'Protección Legendaria', 'LEGENDARY', 'PROTECT_PLAYER', 'Protege un jugador durante toda la temporada.', '{"rounds":null,"seasonLong":true}', TRUE),
('LEAGUE_POINTS_5', 'Empujón de Puntos', 'BASIC', 'ADD_LEAGUE_POINTS', 'Suma 5 puntos al total de la liga.', '{"points":5}', TRUE),
('LEAGUE_POINTS_10', 'Racha Positiva', 'NORMAL', 'ADD_LEAGUE_POINTS', 'Suma 10 puntos al total de la liga.', '{"points":10}', TRUE),
('LEAGUE_POINTS_20', 'Jornada Inspirada', 'SPECIAL', 'ADD_LEAGUE_POINTS', 'Suma 20 puntos al total de la liga.', '{"points":20}', TRUE),
('LEAGUE_POINTS_35', 'Golpe de Clasificación', 'SUPER_RARE', 'ADD_LEAGUE_POINTS', 'Suma 35 puntos al total de la liga.', '{"points":35}', TRUE),
('LEAGUE_POINTS_60', 'Leyenda de la Liga', 'LEGENDARY', 'ADD_LEAGUE_POINTS', 'Suma 60 puntos al total de la liga.', '{"points":60}', TRUE),
('VALUE_RECOVERY_SMALL', 'Recuperación Ligera', 'BASIC', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 2% el valor de un jugador propio que esté bajando.', '{"percentage":0.02}', TRUE),
('VALUE_RECOVERY_MEDIUM', 'Recuperación Normal', 'NORMAL', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 5% el valor de un jugador propio que esté bajando.', '{"percentage":0.05}', TRUE),
('VALUE_RECOVERY_SPECIAL', 'Recuperación Especial', 'SPECIAL', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 8% el valor de un jugador propio que esté bajando.', '{"percentage":0.08}', TRUE),
('VALUE_RECOVERY_ELITE', 'Recuperación Élite', 'SUPER_RARE', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 12% el valor de un jugador propio que esté bajando.', '{"percentage":0.12}', TRUE),
('VALUE_RECOVERY_LEGENDARY', 'Resurrección de Mercado', 'LEGENDARY', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 20% el valor de un jugador propio que esté bajando.', '{"percentage":0.20}', TRUE)
ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    rareza = VALUES(rareza),
    tipo_efecto = VALUES(tipo_efecto),
    descripcion = VALUES(descripcion),
    parametros_json = VALUES(parametros_json),
    activo = VALUES(activo);
