ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS experiencia BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS ultimo_login_xp DATE NULL;

CREATE TABLE IF NOT EXISTS usuario_logros (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_usuario BIGINT NOT NULL,
    codigo_logro VARCHAR(64) NOT NULL,
    desbloqueado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    id_liga BIGINT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_usuario_logro (id_usuario, codigo_logro),
    CONSTRAINT fk_ulogros_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS usuario_progreso_eventos (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_usuario BIGINT NOT NULL,
    tipo VARCHAR(24) NOT NULL,
    cantidad_xp INT NULL,
    nivel_anterior INT NULL,
    nivel_nuevo INT NULL,
    codigo_logro VARCHAR(64) NULL,
    titulo_logro VARCHAR(128) NULL,
    descripcion_logro VARCHAR(255) NULL,
    xp_logro INT NULL,
    xp_total_despues BIGINT NULL,
    xp_en_nivel_despues BIGINT NULL,
    xp_para_siguiente_despues BIGINT NULL,
    visto BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    KEY idx_upe_usuario_visto (id_usuario, visto, creado_en),
    CONSTRAINT fk_upe_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
);
