CREATE TABLE IF NOT EXISTS usuario_notificaciones (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario          BIGINT        NOT NULL,
    id_liga             BIGINT        NULL,
    tipo                VARCHAR(64)   NOT NULL,
    titulo              VARCHAR(255)  NOT NULL,
    mensaje             VARCHAR(500)  NOT NULL,
    leida               TINYINT(1)    NOT NULL DEFAULT 0,
    datos_json          JSON          NULL,
    clave_idempotencia  VARCHAR(160)  NULL,
    creada_en           TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE KEY uq_usuario_notif_idempotencia (clave_idempotencia),
    INDEX idx_usuario_notif_usuario_leida (id_usuario, leida),
    INDEX idx_usuario_notif_usuario_fecha (id_usuario, creada_en DESC),
    INDEX idx_usuario_notif_liga (id_liga, creada_en DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
