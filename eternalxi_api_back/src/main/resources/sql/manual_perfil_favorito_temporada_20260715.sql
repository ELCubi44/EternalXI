-- Manual (prod sin Flyway): jugador favorito en perfil + wrap de temporada
USE EternalXI;

SET @has_fav := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'EternalXI'
      AND TABLE_NAME = 'usuarios'
      AND COLUMN_NAME = 'id_jugador_favorito'
);
SET @ddl_fav := IF(
    @has_fav = 0,
    'ALTER TABLE usuarios ADD COLUMN id_jugador_favorito BIGINT NULL DEFAULT NULL, ADD CONSTRAINT fk_usuarios_jugador_favorito FOREIGN KEY (id_jugador_favorito) REFERENCES jugadores(id) ON DELETE SET NULL',
    'SELECT 1'
);
PREPARE stmt_fav FROM @ddl_fav;
EXECUTE stmt_fav;
DEALLOCATE PREPARE stmt_fav;

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
