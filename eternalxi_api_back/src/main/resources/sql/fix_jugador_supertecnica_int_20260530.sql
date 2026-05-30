USE EternalXI;

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
