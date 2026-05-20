-- Puntos de recompensa globales (usuario)
ALTER TABLE usuario_recursos
    ADD COLUMN puntos_recompensa BIGINT NOT NULL DEFAULT 0;

-- Definiciones de cartas (catálogo)
CREATE TABLE IF NOT EXISTS definiciones_carta (
    id BIGINT NOT NULL AUTO_INCREMENT,
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

-- Cartas obtenidas por participante de liga
CREATE TABLE IF NOT EXISTS liga_participante_cartas (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga_participante BIGINT NOT NULL,
    id_definicion_carta BIGINT NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE',
    obtenido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    usado_en TIMESTAMP(3) NULL,
    metadata_json TEXT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_lpc_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_lpc_definicion FOREIGN KEY (id_definicion_carta) REFERENCES definiciones_carta (id)
);

CREATE INDEX idx_lpc_participante_estado ON liga_participante_cartas (id_liga_participante, estado);
CREATE INDEX idx_lpc_definicion ON liga_participante_cartas (id_definicion_carta);
CREATE INDEX idx_lpc_estado ON liga_participante_cartas (estado);

-- Ruleta de entrenador (una fila por participante)
CREATE TABLE IF NOT EXISTS liga_participante_ruleta_entrenador (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga_participante BIGINT NOT NULL,
    id_entrenador_asignado BIGINT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    usado_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_liga_participante_ruleta UNIQUE (id_liga_participante),
    CONSTRAINT fk_lpre_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_lpre_entrenador FOREIGN KEY (id_entrenador_asignado) REFERENCES entrenadores (id)
);

-- Protección de jugadores frente a cláusula
CREATE TABLE IF NOT EXISTS liga_jugador_protecciones (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga BIGINT NOT NULL,
    id_liga_jugador BIGINT NOT NULL,
    id_liga_participante BIGINT NOT NULL,
    id_carta_origen BIGINT NULL,
    id_jornada_inicio BIGINT NULL,
    id_jornada_fin BIGINT NULL,
    hasta_fin_temporada BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expira_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_ljp_liga FOREIGN KEY (id_liga) REFERENCES ligas (id),
    CONSTRAINT fk_ljp_liga_jugador FOREIGN KEY (id_liga_jugador) REFERENCES liga_jugadores (id),
    CONSTRAINT fk_ljp_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_ljp_carta FOREIGN KEY (id_carta_origen) REFERENCES liga_participante_cartas (id)
);

CREATE INDEX idx_proteccion_liga_jugador_activa ON liga_jugador_protecciones (id_liga, id_liga_jugador, activo);
CREATE INDEX idx_proteccion_participante ON liga_jugador_protecciones (id_liga_participante);
CREATE INDEX idx_proteccion_carta ON liga_jugador_protecciones (id_carta_origen);

-- Bonus de puntos de liga (no altera puntos_totales fantasy)
CREATE TABLE IF NOT EXISTS liga_participante_puntos_bonus (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga_participante BIGINT NOT NULL,
    id_carta_origen BIGINT NULL,
    puntos INT NOT NULL,
    motivo VARCHAR(200) NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_lppb_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_lppb_carta FOREIGN KEY (id_carta_origen) REFERENCES liga_participante_cartas (id)
);

CREATE INDEX idx_bonus_participante ON liga_participante_puntos_bonus (id_liga_participante);

-- Modificadores temporales de valor de mercado
CREATE TABLE IF NOT EXISTS liga_jugador_modificadores_valor (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga BIGINT NOT NULL,
    id_liga_jugador BIGINT NOT NULL,
    id_liga_participante BIGINT NOT NULL,
    id_carta_origen BIGINT NULL,
    tipo VARCHAR(60) NOT NULL,
    porcentaje DECIMAL(8, 4) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    id_jornada_expiracion BIGINT NULL,
    expira_en TIMESTAMP(3) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_ljmv_liga FOREIGN KEY (id_liga) REFERENCES ligas (id),
    CONSTRAINT fk_ljmv_liga_jugador FOREIGN KEY (id_liga_jugador) REFERENCES liga_jugadores (id),
    CONSTRAINT fk_ljmv_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_ljmv_carta FOREIGN KEY (id_carta_origen) REFERENCES liga_participante_cartas (id),
    CONSTRAINT fk_ljmv_jornada FOREIGN KEY (id_jornada_expiracion) REFERENCES jornadas (id)
);

CREATE INDEX idx_mod_valor_liga_jugador_activo ON liga_jugador_modificadores_valor (id_liga, id_liga_jugador, activo);
CREATE INDEX idx_mod_valor_participante ON liga_jugador_modificadores_valor (id_liga_participante);
CREATE INDEX idx_mod_valor_carta ON liga_jugador_modificadores_valor (id_carta_origen);

-- Auditoría de recompensas
CREATE TABLE IF NOT EXISTS liga_recompensa_eventos (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga BIGINT NOT NULL,
    id_liga_participante BIGINT NULL,
    id_usuario BIGINT NULL,
    tipo VARCHAR(80) NOT NULL,
    id_carta BIGINT NULL,
    id_liga_jugador BIGINT NULL,
    id_liga_participante_objetivo BIGINT NULL,
    pack_type VARCHAR(40) NULL,
    cantidad BIGINT NULL,
    descripcion VARCHAR(500) NULL,
    metadata_json TEXT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_lre_liga FOREIGN KEY (id_liga) REFERENCES ligas (id),
    CONSTRAINT fk_lre_participante FOREIGN KEY (id_liga_participante) REFERENCES liga_participantes (id),
    CONSTRAINT fk_lre_carta FOREIGN KEY (id_carta) REFERENCES liga_participante_cartas (id),
    CONSTRAINT fk_lre_liga_jugador FOREIGN KEY (id_liga_jugador) REFERENCES liga_jugadores (id),
    CONSTRAINT fk_lre_part_obj FOREIGN KEY (id_liga_participante_objetivo) REFERENCES liga_participantes (id)
);

CREATE INDEX idx_eventos_liga_fecha ON liga_recompensa_eventos (id_liga, creado_en);
CREATE INDEX idx_eventos_participante ON liga_recompensa_eventos (id_liga_participante);
CREATE INDEX idx_eventos_tipo ON liga_recompensa_eventos (tipo);

-- Seed definiciones de cartas
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
('VALUE_RECOVERY_LEGENDARY', 'Resurrección de Mercado', 'LEGENDARY', 'TEMPORARY_VALUE_RECOVERY', 'Aumenta temporalmente un 20% el valor de un jugador propio que esté bajando.', '{"percentage":0.20}', TRUE);
