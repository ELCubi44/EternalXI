-- Cambio de correo: código también en el correo actual.
ALTER TABLE usuario_cambio_correo_pendiente
    ADD COLUMN IF NOT EXISTS codigo_correo_actual VARCHAR(6) NULL AFTER codigo;

CREATE TABLE IF NOT EXISTS usuario_cambio_nickname_pendiente (
    id_usuario BIGINT NOT NULL,
    nuevo_nickname VARCHAR(24) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_ucnp_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ucnp_nickname ON usuario_cambio_nickname_pendiente (nuevo_nickname);
