-- Seguimiento de cinemática de fin de temporada por participante.
CREATE TABLE IF NOT EXISTS liga_participante_temporada_wrap (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_liga_participante BIGINT NOT NULL,
    id_liga BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    cinematica_vista_en TIMESTAMP NULL DEFAULT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_liga_participante_temporada_wrap_lp (id_liga_participante),
    KEY idx_liga_participante_temporada_wrap_liga (id_liga),
    KEY idx_liga_participante_temporada_wrap_usuario (id_usuario)
);
