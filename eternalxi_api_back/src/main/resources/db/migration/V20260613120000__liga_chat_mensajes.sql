-- Mensajes de chat compartidos por liga (visibles para todos los participantes).
CREATE TABLE IF NOT EXISTS liga_chat_mensajes (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_liga      BIGINT        NOT NULL,
    id_usuario   BIGINT        NOT NULL,
    nickname     VARCHAR(50)   NOT NULL,
    texto        VARCHAR(500)  NOT NULL,
    creado_en    TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX idx_liga_chat_liga_fecha (id_liga, creado_en ASC, id ASC),
    INDEX idx_liga_chat_liga_id (id_liga, id ASC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
