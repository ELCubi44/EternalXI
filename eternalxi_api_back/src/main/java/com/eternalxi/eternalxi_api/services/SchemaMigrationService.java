package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

@Service
public class SchemaMigrationService {

    private static final Logger log = LoggerFactory.getLogger(SchemaMigrationService.class);

    public void applyPendingMigrations() throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement()) {

            exec(st, """
                    CREATE TABLE IF NOT EXISTS correos_verificados (
                        correo VARCHAR(190) NOT NULL PRIMARY KEY,
                        verificado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                    )
                    """);

            exec(st, """
                    CREATE TABLE IF NOT EXISTS usuario_bloqueados (
                        id_usuario BIGINT NOT NULL,
                        id_usuario_bloqueado BIGINT NOT NULL,
                        creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                        PRIMARY KEY (id_usuario, id_usuario_bloqueado)
                    )
                    """);

            exec(st, """
                    CREATE TABLE IF NOT EXISTS liga_chat_mensajes (
                        id           BIGINT AUTO_INCREMENT PRIMARY KEY,
                        id_liga      BIGINT        NOT NULL,
                        id_usuario   BIGINT        NOT NULL,
                        nickname     VARCHAR(50)   NOT NULL,
                        texto        VARCHAR(500)  NOT NULL,
                        creado_en    TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                        INDEX idx_liga_chat_liga_fecha (id_liga, creado_en ASC, id ASC),
                        INDEX idx_liga_chat_liga_id (id_liga, id ASC)
                    )
                    """);

            exec(st, """
                    CREATE TABLE IF NOT EXISTS liga_chat_reportes (
                        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                        id_liga BIGINT NOT NULL,
                        id_mensaje BIGINT NOT NULL,
                        id_usuario_reporter BIGINT NOT NULL,
                        id_usuario_reportado BIGINT NOT NULL,
                        motivo VARCHAR(500) NULL,
                        creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                        INDEX idx_lcr_liga (id_liga, creado_en)
                    )
                    """);

            addColumnIfMissing(st, "usuarios", "fecha_nacimiento", "DATE NULL");

            exec(st, """
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
                        UNIQUE KEY uk_clash_save_usuario (id_usuario)
                    )
                    """);

            exec(st, """
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
                    )
                    """);

            exec(st, """
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
                    )
                    """);

            exec(st, """
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
                        UNIQUE KEY uk_clash_claim_usuario_claim (id_usuario, claim_id)
                    )
                    """);

            exec(st, """
                    CREATE TABLE IF NOT EXISTS usuario_oauth (
                        id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
                        id_usuario              BIGINT        NOT NULL,
                        proveedor               VARCHAR(20)   NOT NULL,
                        proveedor_usuario_id    VARCHAR(255)  NOT NULL,
                        email                   VARCHAR(190)  NULL,
                        creado_en               TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                        UNIQUE KEY uk_oauth_proveedor_uid (proveedor, proveedor_usuario_id),
                        UNIQUE KEY uk_oauth_usuario_proveedor (id_usuario, proveedor),
                        INDEX idx_oauth_usuario (id_usuario)
                    )
                    """);

            log.info("Schema migrations applied");
        }
    }

    private void addColumnIfMissing(Statement st, String table, String column, String definition)
            throws SQLException {
        try {
            st.executeUpdate("ALTER TABLE " + table + " ADD COLUMN " + column + " " + definition);
            log.info("Added column {}.{}", table, column);
        } catch (SQLException e) {
            String msg = e.getMessage() == null ? "" : e.getMessage().toLowerCase();
            if (msg.contains("duplicate column") || msg.contains("already exists")) {
                return;
            }
            throw e;
        }
    }

    private void exec(Statement st, String sql) throws SQLException {
        st.executeUpdate(sql);
    }
}
