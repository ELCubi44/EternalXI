-- Ejecutar en servidor remoto:
-- mysql EternalXI <<'SQL'

CREATE TABLE IF NOT EXISTS liga_actividad (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_liga          BIGINT        NOT NULL,
    id_actor_usuario BIGINT        NULL,
    actor_nickname   VARCHAR(50)   NULL     COMMENT 'Snapshot del nickname del actor al momento del evento',
    tipo             VARCHAR(60)   NOT NULL COMMENT 'Clave fija del tipo de evento',
    mensaje          VARCHAR(500)  NOT NULL COMMENT 'Frase legible para el front',
    id_liga_participante_actor    BIGINT NULL,
    id_liga_participante_objetivo BIGINT NULL,
    id_liga_jugador  BIGINT        NULL,
    id_carta         BIGINT        NULL,
    id_entrenador    BIGINT        NULL,
    cantidad         BIGINT        NULL,
    metadata_json    JSON          NULL,
    creado_en        TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX idx_liga_actividad_liga_fecha (id_liga, creado_en DESC),
    INDEX idx_liga_actividad_tipo (id_liga, tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS liga_notificaciones_enviadas (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_liga          BIGINT       NOT NULL,
    id_jornada       BIGINT       NULL,
    id_usuario       BIGINT       NOT NULL,
    tipo             VARCHAR(60)  NOT NULL,
    creado_en        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE KEY uq_notif_liga_jornada_usuario_tipo (id_liga, id_jornada, id_usuario, tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SQL
