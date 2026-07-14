package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.user.FriendshipResponse;
import com.eternalxi.eternalxi_api.dto.user.UserSearchResultResponse;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class FriendshipService {

    private final AccountProgressService accountProgressService;

    private final FriendshipNotificationService friendshipNotificationService;

    public FriendshipService(
            AccountProgressService accountProgressService,
            FriendshipNotificationService friendshipNotificationService
    ) {
        this.accountProgressService = accountProgressService;
        this.friendshipNotificationService = friendshipNotificationService;
    }

    public List<FriendshipResponse> listFriendships(Long idUsuario) throws SQLException {
        if (idUsuario == null) {
            throw new IllegalArgumentException("Usuario no valido");
        }

        String sql = """
                SELECT a.id, a.estado, a.creado_en,
                       a.id_usuario_solicitante, a.id_usuario_destinatario,
                       CASE
                           WHEN a.id_usuario_solicitante = ? THEN u2.id
                           ELSE u1.id
                       END AS peer_id,
                       CASE
                           WHEN a.id_usuario_solicitante = ? THEN u2.nickname
                           ELSE u1.nickname
                       END AS peer_nick,
                       CASE
                           WHEN a.id_usuario_solicitante = ? THEN COALESCE(u2.foto, '')
                           ELSE COALESCE(u1.foto, '')
                       END AS peer_foto,
                       (a.id_usuario_solicitante = ?) AS soy_solicitante
                FROM usuario_amistades a
                INNER JOIN usuarios u1 ON u1.id = a.id_usuario_solicitante
                INNER JOIN usuarios u2 ON u2.id = a.id_usuario_destinatario
                WHERE a.id_usuario_solicitante = ? OR a.id_usuario_destinatario = ?
                ORDER BY
                    CASE a.estado WHEN 'PENDIENTE' THEN 0 ELSE 1 END,
                    a.creado_en DESC
                """;

        try (Connection conn = DBConnection.getConnection()) {
            List<FriendshipResponse> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (int i = 1; i <= 6; i++) {
                    ps.setLong(i, idUsuario);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp ts = rs.getTimestamp("creado_en");
                        rows.add(new FriendshipResponse(
                                rs.getLong("id"),
                                rs.getLong("peer_id"),
                                rs.getString("peer_nick"),
                                rs.getString("peer_foto"),
                                rs.getString("estado"),
                                rs.getBoolean("soy_solicitante"),
                                ts == null ? Instant.now() : ts.toInstant()
                        ));
                    }
                }
            }
            return rows;
        }
    }

    public FriendshipResponse sendRequest(Long idUsuario, Long idAmigo) throws SQLException {
        if (idUsuario == null || idAmigo == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idUsuario.equals(idAmigo)) {
            throw new IllegalArgumentException("No puedes anadirte a ti mismo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureUserExists(conn, idAmigo);
            ensureNotBlocked(conn, idUsuario, idAmigo);

            String existing = findExistingRelation(conn, idUsuario, idAmigo);
            if ("ACEPTADA".equals(existing)) {
                throw new IllegalArgumentException("Ya sois amigos");
            }
            if ("PENDIENTE".equals(existing)) {
                Long pendingId = findPendingRequestId(conn, idAmigo, idUsuario);
                if (pendingId != null) {
                    return accept(idUsuario, pendingId);
                }
                throw new IllegalArgumentException("Ya hay una solicitud pendiente");
            }

            String insert = """
                    INSERT INTO usuario_amistades (id_usuario_solicitante, id_usuario_destinatario, estado)
                    VALUES (?, ?, 'PENDIENTE')
                    """;
            long newId;
            try (PreparedStatement ps = conn.prepareStatement(insert, PreparedStatement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, idAmigo);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("No se pudo crear la solicitud");
                    }
                    newId = keys.getLong(1);
                }
            }
            FriendshipResponse created = loadById(conn, newId, idUsuario);
            String solicitanteNick = loadUserNickname(conn, idUsuario);
            friendshipNotificationService.notifyFriendRequest(
                    idAmigo,
                    idUsuario,
                    solicitanteNick,
                    newId
            );
            return created;
        }
    }

    public FriendshipResponse accept(Long idUsuario, Long idAmistad) throws SQLException {
        return updateStatus(idUsuario, idAmistad, "ACEPTADA", true);
    }

    public void reject(Long idUsuario, Long idAmistad) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensurePendingParticipant(conn, idUsuario, idAmistad);
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM usuario_amistades WHERE id = ? AND estado = 'PENDIENTE'")) {
                ps.setLong(1, idAmistad);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Solicitud no encontrada");
                }
            }
        }
    }

    public void remove(Long idUsuario, Long idAmigo) throws SQLException {
        if (idUsuario == null || idAmigo == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    DELETE FROM usuario_amistades
                    WHERE (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                       OR (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                    """;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, idAmigo);
                ps.setLong(3, idAmigo);
                ps.setLong(4, idUsuario);
                ps.executeUpdate();
            }
        }
    }

    public List<UserSearchResultResponse> searchUsers(Long idUsuario, String query) throws SQLException {
        if (idUsuario == null) {
            throw new IllegalArgumentException("Usuario no valido");
        }
        String q = query == null ? "" : query.trim();
        if (q.length() < 2) {
            return List.of();
        }

        String sql = """
                SELECT u.id, u.nickname, COALESCE(u.foto, '') AS foto
                FROM usuarios u
                WHERE u.id <> ?
                  AND u.nickname LIKE ?
                  AND u.id NOT IN (
                      SELECT id_usuario_bloqueado FROM usuario_bloqueados WHERE id_usuario = ?
                  )
                  AND u.id NOT IN (
                      SELECT id_usuario FROM usuario_bloqueados WHERE id_usuario_bloqueado = ?
                  )
                ORDER BY u.nickname ASC
                LIMIT 20
                """;

        try (Connection conn = DBConnection.getConnection()) {
            List<UserSearchResultResponse> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setString(2, "%" + q + "%");
                ps.setLong(3, idUsuario);
                ps.setLong(4, idUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long peerId = rs.getLong("id");
                        rows.add(new UserSearchResultResponse(
                                peerId,
                                rs.getString("nickname"),
                                rs.getString("foto"),
                                findExistingRelation(conn, idUsuario, peerId)
                        ));
                    }
                }
            }
            return rows;
        }
    }

    public boolean areFriends(Long a, Long b) throws SQLException {
        return "ACEPTADA".equals(findExistingRelation(
                DBConnection.getConnection(), a, b
        ));
    }

    private void ensurePendingParticipant(Connection conn, Long idUsuario, Long idAmistad)
            throws SQLException {
        String sql = """
                SELECT id_usuario_solicitante, id_usuario_destinatario, estado
                FROM usuario_amistades WHERE id = ? LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idAmistad);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Solicitud no encontrada");
                }
                if (!"PENDIENTE".equals(rs.getString("estado"))) {
                    throw new IllegalArgumentException("La solicitud ya fue respondida");
                }
                long solicitante = rs.getLong("id_usuario_solicitante");
                long destinatario = rs.getLong("id_usuario_destinatario");
                if (!idUsuario.equals(solicitante) && !idUsuario.equals(destinatario)) {
                    throw new IllegalArgumentException("No tienes permiso");
                }
            }
        }
    }

    private FriendshipResponse updateStatus(
            Long idUsuario,
            Long idAmistad,
            String estado,
            boolean returnRow
    ) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            String check = """
                    SELECT id_usuario_solicitante, id_usuario_destinatario, estado
                    FROM usuario_amistades WHERE id = ? LIMIT 1
                    """;
            long solicitante;
            long destinatario;
            try (PreparedStatement ps = conn.prepareStatement(check)) {
                ps.setLong(1, idAmistad);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Solicitud no encontrada");
                    }
                    solicitante = rs.getLong("id_usuario_solicitante");
                    destinatario = rs.getLong("id_usuario_destinatario");
                    if (!"PENDIENTE".equals(rs.getString("estado"))) {
                        throw new IllegalArgumentException("La solicitud ya fue respondida");
                    }
                }
            }

            if ("ACEPTADA".equals(estado) && idUsuario.equals(solicitante)) {
                throw new IllegalArgumentException("Solo el destinatario puede aceptar");
            }
            if (idUsuario.equals(solicitante) && idUsuario.equals(destinatario)) {
                throw new IllegalArgumentException("Solicitud invalida");
            }
            if (!idUsuario.equals(solicitante) && !idUsuario.equals(destinatario)) {
                throw new IllegalArgumentException("No tienes permiso");
            }

            String update = """
                    UPDATE usuario_amistades
                    SET estado = ?, respondida_en = NOW(3)
                    WHERE id = ?
                    """;
            try (PreparedStatement ps = conn.prepareStatement(update)) {
                ps.setString(1, estado);
                ps.setLong(2, idAmistad);
                ps.executeUpdate();
            }

            if ("ACEPTADA".equals(estado)) {
                accountProgressService.onFriendshipAccepted(solicitante);
                accountProgressService.onFriendshipAccepted(destinatario);
            }

            if (!returnRow) {
                return null;
            }
            return loadById(conn, idAmistad, idUsuario);
        }
    }

    private FriendshipResponse loadById(Connection conn, long id, long viewerId) throws SQLException {
        String sql = """
                SELECT a.id, a.estado, a.creado_en,
                       a.id_usuario_solicitante, a.id_usuario_destinatario,
                       CASE WHEN a.id_usuario_solicitante = ? THEN u2.id ELSE u1.id END AS peer_id,
                       CASE WHEN a.id_usuario_solicitante = ? THEN u2.nickname ELSE u1.nickname END AS peer_nick,
                       CASE WHEN a.id_usuario_solicitante = ? THEN COALESCE(u2.foto,'') ELSE COALESCE(u1.foto,'') END AS peer_foto,
                       (a.id_usuario_solicitante = ?) AS soy_solicitante
                FROM usuario_amistades a
                INNER JOIN usuarios u1 ON u1.id = a.id_usuario_solicitante
                INNER JOIN usuarios u2 ON u2.id = a.id_usuario_destinatario
                WHERE a.id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, viewerId);
            ps.setLong(2, viewerId);
            ps.setLong(3, viewerId);
            ps.setLong(4, viewerId);
            ps.setLong(5, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Amistad no encontrada");
                }
                Timestamp ts = rs.getTimestamp("creado_en");
                return new FriendshipResponse(
                        rs.getLong("id"),
                        rs.getLong("peer_id"),
                        rs.getString("peer_nick"),
                        rs.getString("peer_foto"),
                        rs.getString("estado"),
                        rs.getBoolean("soy_solicitante"),
                        ts == null ? Instant.now() : ts.toInstant()
                );
            }
        }
    }

    private Long findPendingRequestId(Connection conn, Long solicitante, Long destinatario)
            throws SQLException {
        String sql = """
                SELECT id FROM usuario_amistades
                WHERE id_usuario_solicitante = ?
                  AND id_usuario_destinatario = ?
                  AND estado = 'PENDIENTE'
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, solicitante);
            ps.setLong(2, destinatario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    private String findExistingRelation(Connection conn, Long a, Long b) throws SQLException {
        String sql = """
                SELECT estado FROM usuario_amistades
                WHERE (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                   OR (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, a);
            ps.setLong(2, b);
            ps.setLong(3, b);
            ps.setLong(4, a);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("estado") : null;
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
                    throw new IllegalArgumentException("No puedes enviar solicitud a este usuario");
                }
            }
        }
    }

    private void ensureUserExists(Connection conn, Long id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM usuarios WHERE id = ?")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Usuario no encontrado");
                }
            }
        }
    }

    private String loadUserNickname(Connection conn, Long id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT nickname FROM usuarios WHERE id = ? LIMIT 1")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return "Jugador";
                }
                String nick = rs.getString("nickname");
                return nick == null || nick.isBlank() ? "Jugador" : nick.trim();
            }
        }
    }
}
