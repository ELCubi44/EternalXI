CREATE TABLE IF NOT EXISTS liga_movimientos_economicos (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga BIGINT NOT NULL,
    id_jornada BIGINT NOT NULL,
    id_liga_participante BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    tipo VARCHAR(64) NOT NULL,
    puntos INT NOT NULL,
    cantidad BIGINT NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT uk_liga_movimiento_jornada_participante_tipo
        UNIQUE (id_liga, id_jornada, id_liga_participante, tipo)
);

CREATE INDEX idx_liga_movimientos_liga_jornada
    ON liga_movimientos_economicos (id_liga, id_jornada);
