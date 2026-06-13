package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueChatMessageResponse;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class LeagueChatService {

    private static final int MAX_TEXT_LENGTH = 500;
    private static final int MAX_LIMIT = 200;

    public List<LeagueChatMessageResponse> listMessages(
            Long idLiga,
            Long idUsuario,
            Long afterId,
            int limit,
            boolean recent
    ) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        int safeLimit = limit <= 0 || limit > MAX_LIMIT ? 100 : limit;

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            if (recent) {
                return loadRecentMessages(conn, idLiga, idUsuario, safeLimit);
            }

            long safeAfterId = afterId == null || afterId < 0 ? 0L : afterId;
            String sql = """
                    SELECT m.id, m.id_usuario, m.nickname, m.texto, m.creado_en,
                           COALESCE(u.foto, '') AS foto
                    FROM liga_chat_mensajes m
                    INNER JOIN usuarios u ON u.id = m.id_usuario
                    WHERE m.id_liga = ?
                      AND m.id > ?
                      AND m.id_usuario NOT IN (
                          SELECT id_usuario_bloqueado
                          FROM usuario_bloqueados
                          WHERE id_usuario = ?
                      )
                    ORDER BY m.id ASC
                    LIMIT ?
                    """;

            List<LeagueChatMessageResponse> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, safeAfterId);
                ps.setLong(3, idUsuario);
                ps.setInt(4, safeLimit);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(mapRow(rs));
                    }
                }
            }
            return rows;
        }
    }

    private List<LeagueChatMessageResponse> loadRecentMessages(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            int limit
    ) throws SQLException {
        String sql = """
                SELECT m.id, m.id_usuario, m.nickname, m.texto, m.creado_en,
                       COALESCE(u.foto, '') AS foto
                FROM liga_chat_mensajes m
                INNER JOIN usuarios u ON u.id = m.id_usuario
                WHERE m.id_liga = ?
                  AND m.id_usuario NOT IN (
                      SELECT id_usuario_bloqueado
                      FROM usuario_bloqueados
                      WHERE id_usuario = ?
                  )
                ORDER BY m.id DESC
                LIMIT ?
                """;
        List<LeagueChatMessageResponse> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setInt(3, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
            }
        }
        rows.sort((a, b) -> Long.compare(a.id(), b.id()));
        return rows;
    }

    public LeagueChatMessageResponse postMessage(
            Long idLiga,
            Long idUsuario,
            String texto
    ) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        String trimmed = texto == null ? "" : texto.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("El mensaje no puede estar vacío");
        }
        if (trimmed.length() > MAX_TEXT_LENGTH) {
            throw new IllegalArgumentException("El mensaje es demasiado largo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
            enforceRateLimit(conn, idLiga, idUsuario);

            String nickname = loadNickname(conn, idUsuario);
            if (nickname == null || nickname.isBlank()) {
                throw new IllegalArgumentException("Usuario no encontrado");
            }

            String insertSql = """
                    INSERT INTO liga_chat_mensajes (id_liga, id_usuario, nickname, texto)
                    VALUES (?, ?, ?, ?)
                    """;
            long newId;
            try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idUsuario);
                ps.setString(3, nickname);
                ps.setString(4, trimmed);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("No se pudo crear el mensaje de chat");
                    }
                    newId = keys.getLong(1);
                }
            }

            String selectSql = """
                    SELECT m.id, m.id_usuario, m.nickname, m.texto, m.creado_en,
                           COALESCE(u.foto, '') AS foto
                    FROM liga_chat_mensajes m
                    INNER JOIN usuarios u ON u.id = m.id_usuario
                    WHERE m.id = ?
                    LIMIT 1
                    """;
            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setLong(1, newId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new SQLException("Mensaje de chat no encontrado tras insertar");
                    }
                    return mapRow(rs);
                }
            }
        }
    }

    private LeagueChatMessageResponse mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("creado_en");
        Instant creadoEn = ts == null ? Instant.now() : ts.toInstant();
        return new LeagueChatMessageResponse(
                rs.getLong("id"),
                rs.getLong("id_usuario"),
                rs.getString("nickname"),
                rs.getString("foto"),
                rs.getString("texto"),
                creadoEn
        );
    }

    private String loadNickname(Connection conn, Long idUsuario) throws SQLException {
        String sql = "SELECT COALESCE(nickname, '') FROM usuarios WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    private void enforceRateLimit(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COUNT(*) FROM liga_chat_mensajes
                WHERE id_liga = ? AND id_usuario = ?
                  AND creado_en >= (NOW(3) - INTERVAL 2 SECOND)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    throw new IllegalArgumentException("Espera un momento antes de enviar otro mensaje");
                }
            }
        }
    }

    private void ensureParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = "SELECT 1 FROM liga_participantes WHERE id_liga = ? AND id_usuario = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
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
