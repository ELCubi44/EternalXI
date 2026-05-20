CREATE TABLE IF NOT EXISTS liga_jugador_titularidad_probabilidad (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_liga BIGINT NOT NULL,
    id_jornada BIGINT NOT NULL,
    id_partido_jornada BIGINT NOT NULL,
    id_liga_equipo BIGINT NOT NULL,
    id_liga_jugador BIGINT NOT NULL,
    probabilidad_titular TINYINT UNSIGNED NOT NULL,
    motivo_resumen VARCHAR(255) NULL,
    calculado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version_modelo VARCHAR(30) NOT NULL DEFAULT 'v1',
    PRIMARY KEY (id),
    UNIQUE KEY uk_prob_titular_jugador_partido (id_partido_jornada, id_liga_jugador),
    KEY idx_prob_liga_jornada (id_liga, id_jornada),
    KEY idx_prob_liga_jugador (id_liga_jugador),
    KEY idx_prob_partido_equipo (id_partido_jornada, id_liga_equipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
