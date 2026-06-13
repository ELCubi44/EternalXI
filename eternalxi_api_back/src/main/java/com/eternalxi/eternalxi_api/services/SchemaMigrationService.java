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
