USE EternalXI;

-- Tabla monolítica anterior (nunca desplegada en prod; seguro eliminar si existiera)
DROP TABLE IF EXISTS jugador_supertecnicas;

-- Columnas nuevas en jugadores (nullable; no afecta filas existentes)
ALTER TABLE jugadores
    ADD COLUMN pais VARCHAR(64) NULL COMMENT 'País de origen' AFTER genero;

ALTER TABLE jugadores
    ADD COLUMN altura SMALLINT UNSIGNED NULL COMMENT 'Altura en cm' AFTER pais;

ALTER TABLE jugadores
    ADD COLUMN estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NULL COMMENT 'Estilo de juego' AFTER altura;

CREATE TABLE IF NOT EXISTS supertecnicas (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(128) NOT NULL,
    potencia TINYINT UNSIGNED NOT NULL,
    tipo ENUM('REGATE', 'DEFENSA', 'PARADA', 'TIRO') NOT NULL,
    estilo ENUM('PICARO', 'PRECISO', 'POTENTE') NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_supertecnica_def (nombre, potencia, tipo, estilo),
    KEY idx_supertecnicas_tipo (tipo)
);

CREATE TABLE IF NOT EXISTS jugador_supertecnica (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_jugador INT NOT NULL,
    id_supertecnica BIGINT NOT NULL,
    orden TINYINT UNSIGNED NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_jugador_supertecnica_orden (id_jugador, orden),
    UNIQUE KEY uk_jugador_supertecnica_par (id_jugador, id_supertecnica),
    KEY idx_jugador_supertecnica_supertecnica (id_supertecnica),
    CONSTRAINT fk_js_jugador FOREIGN KEY (id_jugador) REFERENCES jugadores (id) ON DELETE CASCADE,
    CONSTRAINT fk_js_supertecnica FOREIGN KEY (id_supertecnica) REFERENCES supertecnicas (id) ON DELETE RESTRICT
);
