package com.eternalxi.eternalxi_api.repository;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.model.ClashClaim;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Optional;

@Repository
public class ClashClaimRepository {

    public Optional<ClashClaim> findByUserIdAndClaimId(long userId, String claimId) throws SQLException {
        String sql = """
                SELECT id, id_usuario, claim_id, claim_type, source_id, stage_id,
                       request_json, response_json, status, server_revision,
                       created_at, processed_at
                FROM clash_claim
                WHERE id_usuario = ?
                  AND claim_id = ?
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, claimId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRow(rs));
            }
        }
    }

    public boolean existsByUserIdAndClaimId(long userId, String claimId) throws SQLException {
        return findByUserIdAndClaimId(userId, claimId).isPresent();
    }

    public ClashClaim insert(
            long userId,
            String claimId,
            String claimType,
            String sourceId,
            String stageId,
            String requestJson,
            String responseJson,
            String status,
            Integer serverRevision
    ) throws SQLException {
        String sql = """
                INSERT INTO clash_claim (
                    id_usuario, claim_id, claim_type, source_id, stage_id,
                    request_json, response_json, status, server_revision,
                    created_at, processed_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3))
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, claimId);
            ps.setString(3, claimType);
            ps.setString(4, sourceId);
            ps.setString(5, stageId);
            ps.setString(6, requestJson);
            ps.setString(7, responseJson);
            ps.setString(8, status);
            if (serverRevision == null) {
                ps.setNull(9, java.sql.Types.INTEGER);
            } else {
                ps.setInt(9, serverRevision);
            }
            ps.executeUpdate();

            return findByUserIdAndClaimId(userId, claimId)
                    .orElseThrow(() -> new SQLException("clash_claim insertado pero no legible"));
        }
    }

    private static ClashClaim mapRow(ResultSet rs) throws SQLException {
        int serverRevision = rs.getInt("server_revision");
        return new ClashClaim(
                rs.getLong("id"),
                rs.getLong("id_usuario"),
                rs.getString("claim_id"),
                rs.getString("claim_type"),
                rs.getString("source_id"),
                rs.getString("stage_id"),
                rs.getString("request_json"),
                rs.getString("response_json"),
                rs.getString("status"),
                rs.wasNull() ? null : serverRevision,
                rs.getTimestamp("created_at").toInstant(),
                rs.getTimestamp("processed_at").toInstant()
        );
    }
}
