CREATE TABLE IF NOT EXISTS account_deletion_requests (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario      BIGINT        NOT NULL,
    email_snapshot  VARCHAR(190)  NOT NULL,
    code_hash       CHAR(64)      NOT NULL,
    token_hash      CHAR(64)      NOT NULL,
    expires_at      TIMESTAMP(3)  NOT NULL,
    used_at         TIMESTAMP(3)  NULL,
    created_at      TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX idx_adr_usuario_created (id_usuario, created_at DESC),
    INDEX idx_adr_token_hash (token_hash),
    INDEX idx_adr_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
