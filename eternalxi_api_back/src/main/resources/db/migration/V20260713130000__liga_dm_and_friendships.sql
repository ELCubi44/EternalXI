-- Mensajes privados dentro de una liga (DM entre participantes)
CREATE TABLE IF NOT EXISTS liga_dm_mensajes (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_liga         BIGINT        NOT NULL,
    id_emisor       BIGINT        NOT NULL,
    id_destino      BIGINT        NOT NULL,
    nickname_emisor VARCHAR(50)   NOT NULL,
    texto           VARCHAR(500)  NOT NULL,
    creado_en       TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX idx_liga_dm_par_fecha (id_liga, id_emisor, id_destino, creado_en ASC, id ASC),
    INDEX idx_liga_dm_par_rev (id_liga, id_destino, id_emisor, creado_en ASC, id ASC),
    INDEX idx_liga_dm_liga_id (id_liga, id ASC)
);

-- Amistades a nivel plataforma
CREATE TABLE IF NOT EXISTS usuario_amistades (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_solicitante  BIGINT        NOT NULL,
    id_usuario_destinatario BIGINT        NOT NULL,
    estado                  VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    creado_en               TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    respondida_en           TIMESTAMP(3)  NULL,
    UNIQUE KEY uk_amistad_par (id_usuario_solicitante, id_usuario_destinatario),
    INDEX idx_amistad_dest_estado (id_usuario_destinatario, estado),
    INDEX idx_amistad_sol_estado (id_usuario_solicitante, estado)
);
