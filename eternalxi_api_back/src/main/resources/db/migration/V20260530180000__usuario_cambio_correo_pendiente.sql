CREATE TABLE IF NOT EXISTS usuario_cambio_correo_pendiente (
    id_usuario BIGINT NOT NULL,
    nuevo_correo VARCHAR(190) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_uccp_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_uccp_nuevo_correo ON usuario_cambio_correo_pendiente (nuevo_correo);
