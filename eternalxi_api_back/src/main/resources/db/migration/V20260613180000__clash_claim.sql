CREATE TABLE IF NOT EXISTS clash_claim (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario       BIGINT        NOT NULL,
    claim_id         VARCHAR(191)  NOT NULL,
    claim_type       VARCHAR(64)   NOT NULL,
    source_id        VARCHAR(191)  NOT NULL,
    stage_id         VARCHAR(191)  NULL,
    request_json     JSON          NOT NULL,
    response_json    JSON          NOT NULL,
    status           VARCHAR(32)   NOT NULL,
    server_revision  INT           NULL,
    created_at       TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    processed_at     TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE KEY uk_clash_claim_usuario_claim (id_usuario, claim_id),
    INDEX idx_clash_claim_usuario (id_usuario),
    CONSTRAINT chk_clash_claim_status CHECK (
        status IN ('ACCEPTED', 'REJECTED', 'FAILED')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
