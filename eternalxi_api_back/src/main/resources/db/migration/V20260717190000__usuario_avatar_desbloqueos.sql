CREATE TABLE IF NOT EXISTS usuario_avatar_desbloqueos (
    id_usuario BIGINT NOT NULL,
    id_jugador INT NOT NULL,
    origen VARCHAR(16) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_jugador),
    CONSTRAINT fk_avatar_unlock_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_avatar_unlock_jugador
        FOREIGN KEY (id_jugador) REFERENCES jugadores(id) ON DELETE CASCADE,
    CONSTRAINT chk_avatar_unlock_origen
        CHECK (origen IN ('clash', 'fantasy'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
