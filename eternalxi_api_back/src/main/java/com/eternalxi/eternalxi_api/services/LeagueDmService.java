package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueDmMessageResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueDmThreadResponse;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class LeagueDmService {

    private static final int MAX_TEXT_LENGTH = 500;
    private static final int MAX_LIMIT = 200;

    public List<LeagueDmThreadResponse> listThreads(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT m.id, m.id_emisor, m.id_destino, m.texto, m.creado_en,
                           u.nickname, COALESCE(u.foto, '') AS foto
                    FROM liga_dm_mensajes m
                    INNER JOIN usuarios u ON u.id = CASE
                        WHEN m.id_emisor = ? THEN m.id_destino
                        ELSE m.id_emisor
                    END
                    WHERE m.id_liga = ?
                      AND (m.id_emisor = ? OR m.id_destino = ?)
                      AND m.id_emisor NOT IN (
                          SELECT id_usuario_bloqueado FROM usuario_bloqueados WHERE id_usuario = ?
                      )
                      AND m.id_destino NOT IN (
                          SELECT id_usuario_bloqueado FROM usuario_bloqueados WHERE id_usuario = ?
                      )
                    ORDER BY m.id DESC
                    """;

            Map<Long, LeagueDmThreadResponse> latest = new LinkedHashMap<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, idLiga);
                ps.setLong(3, idUsuario);
                ps.setLong(4, idUsuario);
                ps.setLong(5, idUsuario);
                ps.setLong(6, idUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long emisor = rs.getLong("id_emisor");
                        long destino = rs.getLong("id_destino");
                        long peerId = emisor == idUsuario ? destino : emisor;
                        if (latest.containsKey(peerId)) {
                            continue;
                        }
                        Timestamp ts = rs.getTimestamp("creado_en");
                        latest.put(peerId, new LeagueDmThreadResponse(
                                peerId,
                                rs.getString("nickname"),
                                rs.getString("foto"),
                                rs.getString("texto"),
                                ts == null ? Instant.now() : ts.toInstant(),
                                rs.getLong("id"),
                                isFriend(conn, idUsuario, peerId)
                        ));
                    }
                }
            }
            return new ArrayList<>(latest.values());
        }
    }

    public List<LeagueDmMessageResponse> listMessages(
            Long idLiga,
            Long idUsuario,
            Long idPeer,
            Long afterId,
            int limit,
            boolean recent
    ) throws SQLException {
        if (idLiga == null || idUsuario == null || idPeer == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idUsuario.equals(idPeer)) {
            throw new IllegalArgumentException("No puedes chatear contigo mismo");
        }

        int safeLimit = limit <= 0 || limit > MAX_LIMIT ? 100 : limit;

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
            ensureParticipant(conn, idLiga, idPeer);
            ensureNotBlocked(conn, idUsuario, idPeer);

            if (recent) {
                return loadRecentMessages(conn, idLiga, idUsuario, idPeer, safeLimit);
            }

            long safeAfterId = afterId == null || afterId < 0 ? 0L : afterId;
            String sql = """
                    SELECT m.id, m.id_liga, m.id_emisor, m.id_destino, m.nickname_emisor,
                           m.texto, m.creado_en, COALESCE(u.foto, '') AS foto
                    FROM liga_dm_mensajes m
                    INNER JOIN usuarios u ON u.id = m.id_emisor
                    WHERE m.id_liga = ?
                      AND m.id > ?
                      AND (
                          (m.id_emisor = ? AND m.id_destino = ?)
                          OR (m.id_emisor = ? AND m.id_destino = ?)
                      )
                    ORDER BY m.id ASC
                    LIMIT ?
                    """;

            List<LeagueDmMessageResponse> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, safeAfterId);
                ps.setLong(3, idUsuario);
                ps.setLong(4, idPeer);
                ps.setLong(5, idPeer);
                ps.setLong(6, idUsuario);
                ps.setInt(7, safeLimit);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(mapRow(rs));
                    }
                }
            }
            return rows;
        }
    }

    public LeagueDmMessageResponse postMessage(
            Long idLiga,
            Long idUsuario,
            Long idDestino,
            String texto
    ) throws SQLException {
        if (idLiga == null || idUsuario == null || idDestino == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idUsuario.equals(idDestino)) {
            throw new IllegalArgumentException("No puedes enviarte mensajes a ti mismo");
        }

        String trimmed = texto == null ? "" : texto.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("El mensaje no puede estar vacio");
        }
        if (trimmed.length() > MAX_TEXT_LENGTH) {
            throw new IllegalArgumentException("El mensaje es demasiado largo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
            ensureParticipant(conn, idLiga, idDestino);
            ensureNotBlocked(conn, idUsuario, idDestino);
            enforceRateLimit(conn, idLiga, idUsuario, idDestino);

            String nickname = loadNickname(conn, idUsuario);
            if (nickname == null || nickname.isBlank()) {
                throw new IllegalArgumentException("Usuario no encontrado");
            }

            String insertSql = """
                    INSERT INTO liga_dm_mensajes
                        (id_liga, id_emisor, id_destino, nickname_emisor, texto)
                    VALUES (?, ?, ?, ?, ?)
                    """;
            long newId;
            try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idUsuario);
                ps.setLong(3, idDestino);
                ps.setString(4, nickname);
                ps.setString(5, trimmed);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("No se pudo crear el mensaje privado");
                    }
                    newId = keys.getLong(1);
                }
            }

            return loadMessageById(conn, newId);
        }
    }

    private List<LeagueDmMessageResponse> loadRecentMessages(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            Long idPeer,
            int limit
    ) throws SQLException {
        String sql = """
                SELECT m.id, m.id_liga, m.id_emisor, m.id_destino, m.nickname_emisor,
                       m.texto, m.creado_en, COALESCE(u.foto, '') AS foto
                FROM liga_dm_mensajes m
                INNER JOIN usuarios u ON u.id = m.id_emisor
                WHERE m.id_liga = ?
                  AND (
                      (m.id_emisor = ? AND m.id_destino = ?)
                      OR (m.id_emisor = ? AND m.id_destino = ?)
                  )
                ORDER BY m.id DESC
                LIMIT ?
                """;
        List<LeagueDmMessageResponse> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setLong(3, idPeer);
            ps.setLong(4, idPeer);
            ps.setLong(5, idUsuario);
            ps.setInt(6, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
            }
        }
        rows.sort((a, b) -> Long.compare(a.id(), b.id()));
        return rows;
    }

    private LeagueDmMessageResponse loadMessageById(Connection conn, long id) throws SQLException {
        String sql = """
                SELECT m.id, m.id_liga, m.id_emisor, m.id_destino, m.nickname_emisor,
                       m.texto, m.creado_en, COALESCE(u.foto, '') AS foto
                FROM liga_dm_mensajes m
                INNER JOIN usuarios u ON u.id = m.id_emisor
                WHERE m.id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Mensaje privado no encontrado");
                }
                return mapRow(rs);
            }
        }
    }

    private LeagueDmMessageResponse mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("creado_en");
        return new LeagueDmMessageResponse(
                rs.getLong("id"),
                rs.getLong("id_liga"),
                rs.getLong("id_emisor"),
                rs.getLong("id_destino"),
                rs.getString("nickname_emisor"),
                rs.getString("foto"),
                rs.getString("texto"),
                ts == null ? Instant.now() : ts.toInstant()
        );
    }

    private boolean isFriend(Connection conn, Long a, Long b) throws SQLException {
        String sql = """
                SELECT 1 FROM usuario_amistades
                WHERE estado = 'ACEPTADA'
                  AND (
                      (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                      OR (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                  )
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, a);
            ps.setLong(2, b);
            ps.setLong(3, b);
            ps.setLong(4, a);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void enforceRateLimit(Connection conn, Long idLiga, Long idUsuario, Long idDestino)
            throws SQLException {
        String sql = """
                SELECT COUNT(*) FROM liga_dm_mensajes
                WHERE id_liga = ? AND id_emisor = ? AND id_destino = ?
                  AND creado_en >= (NOW(3) - INTERVAL 2 SECOND)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setLong(3, idDestino);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    throw new IllegalArgumentException("Espera un momento antes de enviar otro mensaje");
                }
            }
        }
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

    private void ensureNotBlocked(Connection conn, Long a, Long b) throws SQLException {
        String sql = """
                SELECT 1 FROM usuario_bloqueados
                WHERE (id_usuario = ? AND id_usuario_bloqueado = ?)
                   OR (id_usuario = ? AND id_usuario_bloqueado = ?)
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, a);
            ps.setLong(2, b);
            ps.setLong(3, b);
            ps.setLong(4, a);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalArgumentException("No puedes chatear con este usuario");
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
