CREATE TABLE IF NOT EXISTS clash_save (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario       BIGINT        NOT NULL,
    contract_version INT           NOT NULL,
    schema_version   INT           NOT NULL,
    server_revision  INT           NOT NULL,
    save_data_json   JSON          NOT NULL,
    created_at       TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at       TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    last_sync_at     TIMESTAMP(3)  NULL,

    UNIQUE KEY uk_clash_save_usuario (id_usuario),
    CONSTRAINT chk_clash_save_server_revision CHECK (server_revision >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
