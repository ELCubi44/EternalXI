-- Edad mínima en registro, correos verificados, bloqueos y reportes de chat.

ALTER TABLE usuarios
    ADD COLUMN fecha_nacimiento DATE NULL AFTER nickname;

CREATE TABLE IF NOT EXISTS correos_verificados (
    correo VARCHAR(190) NOT NULL PRIMARY KEY,
    verificado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE IF NOT EXISTS usuario_bloqueados (
    id_usuario BIGINT NOT NULL,
    id_usuario_bloqueado BIGINT NOT NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id_usuario, id_usuario_bloqueado),
    CONSTRAINT fk_ub_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE,
    CONSTRAINT fk_ub_bloqueado FOREIGN KEY (id_usuario_bloqueado) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS liga_chat_reportes (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_liga BIGINT NOT NULL,
    id_mensaje BIGINT NOT NULL,
    id_usuario_reporter BIGINT NOT NULL,
    id_usuario_reportado BIGINT NOT NULL,
    motivo VARCHAR(500) NULL,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_lcr_liga FOREIGN KEY (id_liga) REFERENCES ligas (id) ON DELETE CASCADE,
    CONSTRAINT fk_lcr_mensaje FOREIGN KEY (id_mensaje) REFERENCES liga_chat_mensajes (id) ON DELETE CASCADE,
    CONSTRAINT fk_lcr_reporter FOREIGN KEY (id_usuario_reporter) REFERENCES usuarios (id) ON DELETE CASCADE,
    CONSTRAINT fk_lcr_reportado FOREIGN KEY (id_usuario_reportado) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE INDEX idx_lcr_liga ON liga_chat_reportes (id_liga, creado_en);
