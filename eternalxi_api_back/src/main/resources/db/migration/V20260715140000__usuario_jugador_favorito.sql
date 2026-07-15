ALTER TABLE usuarios
    ADD COLUMN id_jugador_favorito BIGINT NULL DEFAULT NULL,
    ADD CONSTRAINT fk_usuarios_jugador_favorito
        FOREIGN KEY (id_jugador_favorito) REFERENCES jugadores(id)
        ON DELETE SET NULL;
