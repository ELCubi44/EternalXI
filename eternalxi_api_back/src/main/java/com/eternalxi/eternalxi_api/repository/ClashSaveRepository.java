package com.eternalxi.eternalxi_api.repository;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.model.ClashSave;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Optional;

@Repository
public class ClashSaveRepository {

    public Optional<ClashSave> findByUserId(long userId) throws SQLException {
        String sql = """
                SELECT id, id_usuario, contract_version, schema_version, server_revision,
                       save_data_json, created_at, updated_at, last_sync_at
                FROM clash_save
                WHERE id_usuario = ?
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRow(rs));
            }
        }
    }

    public boolean existsByUserId(long userId) throws SQLException {
        return findByUserId(userId).isPresent();
    }

    public ClashSave insert(
            long userId,
            int contractVersion,
            int schemaVersion,
            String saveDataJson
    ) throws SQLException {
        String sql = """
                INSERT INTO clash_save (
                    id_usuario, contract_version, schema_version, server_revision,
                    save_data_json, created_at, updated_at, last_sync_at
                )
                VALUES (?, ?, ?, 1, ?, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3))
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setInt(2, contractVersion);
            ps.setInt(3, schemaVersion);
            ps.setString(4, saveDataJson);
            ps.executeUpdate();

            return findByUserId(userId)
                    .orElseThrow(() -> new SQLException("clash_save insertado pero no legible"));
        }
    }

    /**
     * @return filas actualizadas (0 si la revisión no coincide o no existe).
     */
    public int updateWithExpectedRevision(
            long userId,
            int expectedServerRevision,
            int contractVersion,
            int schemaVersion,
            int newServerRevision,
            String saveDataJson
    ) throws SQLException {
        String sql = """
                UPDATE clash_save
                SET contract_version = ?,
                    schema_version = ?,
                    server_revision = ?,
                    save_data_json = ?,
                    updated_at = CURRENT_TIMESTAMP(3),
                    last_sync_at = CURRENT_TIMESTAMP(3)
                WHERE id_usuario = ?
                  AND server_revision = ?
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractVersion);
            ps.setInt(2, schemaVersion);
            ps.setInt(3, newServerRevision);
            ps.setString(4, saveDataJson);
            ps.setLong(5, userId);
            ps.setInt(6, expectedServerRevision);
            return ps.executeUpdate();
        }
    }

    private static ClashSave mapRow(ResultSet rs) throws SQLException {
        Timestamp lastSync = rs.getTimestamp("last_sync_at");
        return new ClashSave(
                rs.getLong("id"),
                rs.getLong("id_usuario"),
                rs.getInt("contract_version"),
                rs.getInt("schema_version"),
                rs.getInt("server_revision"),
                rs.getString("save_data_json"),
                rs.getTimestamp("created_at").toInstant(),
                rs.getTimestamp("updated_at").toInstant(),
                lastSync == null ? null : lastSync.toInstant()
        );
    }
}
