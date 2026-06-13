package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@Service
public class UserSafetyService {

    public void blockUser(Long idUsuario, Long idUsuarioBloqueado) throws SQLException {
        if (idUsuario == null || idUsuarioBloqueado == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idUsuario.equals(idUsuarioBloqueado)) {
            throw new IllegalArgumentException("No puedes bloquearte a ti mismo");
        }
        ensureUserExists(idUsuario);
        ensureUserExists(idUsuarioBloqueado);

        String sql = """
                INSERT INTO usuario_bloqueados (id_usuario, id_usuario_bloqueado)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE creado_en = creado_en
                """;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idUsuarioBloqueado);
            ps.executeUpdate();
        }
    }

    public void unblockUser(Long idUsuario, Long idUsuarioBloqueado) throws SQLException {
        if (idUsuario == null || idUsuarioBloqueado == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        String sql = "DELETE FROM usuario_bloqueados WHERE id_usuario = ? AND id_usuario_bloqueado = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idUsuarioBloqueado);
            ps.executeUpdate();
        }
    }

    public void reportChatMessage(
            Long idLiga,
            Long idMensaje,
            Long idUsuarioReporter,
            String motivo
    ) throws SQLException {
        if (idLiga == null || idMensaje == null || idUsuarioReporter == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        String trimmedMotivo = motivo == null ? null : motivo.trim();
        if (trimmedMotivo != null && trimmedMotivo.length() > 500) {
            throw new IllegalArgumentException("El motivo es demasiado largo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureLeagueParticipant(conn, idLiga, idUsuarioReporter);

            long idReportado;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id_usuario FROM liga_chat_mensajes WHERE id = ? AND id_liga = ? LIMIT 1")) {
                ps.setLong(1, idMensaje);
                ps.setLong(2, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Mensaje no encontrado");
                    }
                    idReportado = rs.getLong("id_usuario");
                }
            }

            if (idReportado == idUsuarioReporter) {
                throw new IllegalArgumentException("No puedes reportar tus propios mensajes");
            }

            String insert = """
                    INSERT INTO liga_chat_reportes
                        (id_liga, id_mensaje, id_usuario_reporter, id_usuario_reportado, motivo)
                    VALUES (?, ?, ?, ?, ?)
                    """;
            try (PreparedStatement ps = conn.prepareStatement(insert)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idMensaje);
                ps.setLong(3, idUsuarioReporter);
                ps.setLong(4, idReportado);
                ps.setString(5, trimmedMotivo == null || trimmedMotivo.isBlank() ? null : trimmedMotivo);
                ps.executeUpdate();
            }
        }
    }

    private void ensureUserExists(Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM usuarios WHERE id = ? LIMIT 1")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Usuario no encontrado");
                }
            }
        }
    }

    private void ensureLeagueParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM liga_participantes WHERE id_liga = ? AND id_usuario = ? LIMIT 1")) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("No perteneces a esta liga");
                }
            }
        }
    }
}
