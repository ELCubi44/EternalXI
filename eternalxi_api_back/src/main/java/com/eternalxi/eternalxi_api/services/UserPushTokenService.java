package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
public class UserPushTokenService {

    public void saveOrUpdateToken(Long idUsuario, String token, String plataforma, String deviceId) throws SQLException {
        if (idUsuario == null || token == null || token.isBlank() || plataforma == null || plataforma.isBlank()) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    INSERT INTO usuario_push_tokens (id_usuario, token, plataforma, device_id, activo)
                    VALUES (?, ?, ?, ?, 1)
                    ON DUPLICATE KEY UPDATE
                        id_usuario = VALUES(id_usuario),
                        plataforma = VALUES(plataforma),
                        device_id = VALUES(device_id),
                        activo = 1
                    """;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setString(2, token);
                ps.setString(3, plataforma.trim().toUpperCase());
                ps.setString(4, deviceId);
                ps.executeUpdate();
            }
        }
    }

    public void deactivateToken(String token) throws SQLException {
        if (token == null || token.isBlank()) {
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    UPDATE usuario_push_tokens
                    SET activo = 0
                    WHERE token = ?
                    """;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, token);
                ps.executeUpdate();
            }
        }
    }

    public List<String> findActiveTokensByUser(Long idUsuario) throws SQLException {
        List<String> tokens = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT token
                    FROM usuario_push_tokens
                    WHERE id_usuario = ?
                      AND activo = 1
                    ORDER BY id ASC
                    """;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        tokens.add(rs.getString("token"));
                    }
                }
            }
        }

        return tokens;
    }
}