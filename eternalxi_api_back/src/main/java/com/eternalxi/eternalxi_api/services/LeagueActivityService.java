package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class LeagueActivityService {

    private static final Logger log = LoggerFactory.getLogger(LeagueActivityService.class);

    public record ActivityEvent(
            long id,
            long idLiga,
            Long idActorUsuario,
            String actorNickname,
            String tipo,
            String mensaje,
            Long idLigaParticipanteActor,
            Long idLigaParticipanteObjetivo,
            Long idLigaJugador,
            Long idCarta,
            Long idEntrenador,
            Long cantidad,
            String metadataJson,
            Instant creadoEn
    ) {}

    /**
     * Insert an activity event within an existing connection/transaction.
     */
    public void recordActivity(
            Connection conn,
            Long idLiga,
            Long idActorUsuario,
            String actorNickname,
            String tipo,
            String mensaje,
            Long idLigaParticipanteActor,
            Long idLigaParticipanteObjetivo,
            Long idLigaJugador,
            Long idCarta,
            Long idEntrenador,
            Long cantidad,
            String metadataJson
    ) throws SQLException {
        String sql = """
                INSERT INTO liga_actividad (
                    id_liga, id_actor_usuario, actor_nickname, tipo, mensaje,
                    id_liga_participante_actor, id_liga_participante_objetivo,
                    id_liga_jugador, id_carta, id_entrenador, cantidad, metadata_json
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            setLongOrNull(ps, 2, idActorUsuario);
            if (actorNickname == null) ps.setNull(3, Types.VARCHAR); else ps.setString(3, actorNickname);
            ps.setString(4, tipo);
            ps.setString(5, truncate(mensaje, 500));
            setLongOrNull(ps, 6, idLigaParticipanteActor);
            setLongOrNull(ps, 7, idLigaParticipanteObjetivo);
            setLongOrNull(ps, 8, idLigaJugador);
            setLongOrNull(ps, 9, idCarta);
            setLongOrNull(ps, 10, idEntrenador);
            setLongOrNull(ps, 11, cantidad);
            if (metadataJson == null) ps.setNull(12, Types.LONGVARCHAR); else ps.setString(12, metadataJson);
            ps.executeUpdate();
        }
    }

    /**
     * Fire-and-forget activity event (opens its own connection).
     */
    public void recordActivityAsync(
            Long idLiga,
            Long idActorUsuario,
            String actorNickname,
            String tipo,
            String mensaje,
            Long idLigaParticipanteActor,
            Long idLigaParticipanteObjetivo,
            Long idLigaJugador,
            Long idCarta,
            Long idEntrenador,
            Long cantidad,
            String metadataJson
    ) {
        try (Connection conn = DBConnection.getConnection()) {
            recordActivity(conn, idLiga, idActorUsuario, actorNickname, tipo, mensaje,
                    idLigaParticipanteActor, idLigaParticipanteObjetivo,
                    idLigaJugador, idCarta, idEntrenador, cantidad, metadataJson);
        } catch (Exception e) {
            log.warn("Error registrando actividad de liga {}: {}", idLiga, e.getMessage());
        }
    }

    public List<ActivityEvent> listActivity(Long idLiga, Long idUsuario, int limit, int offset) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            if (limit <= 0 || limit > 100) limit = 50;
            if (offset < 0) offset = 0;

            String sql = """
                    SELECT id, id_liga, id_actor_usuario, actor_nickname, tipo, mensaje,
                           id_liga_participante_actor, id_liga_participante_objetivo,
                           id_liga_jugador, id_carta, id_entrenador, cantidad, metadata_json, creado_en
                    FROM liga_actividad
                    WHERE id_liga = ?
                    ORDER BY creado_en DESC, id DESC
                    LIMIT ? OFFSET ?
                    """;
            List<ActivityEvent> events = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setInt(2, limit);
                ps.setInt(3, offset);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp ts = rs.getTimestamp("creado_en");
                        events.add(new ActivityEvent(
                                rs.getLong("id"),
                                rs.getLong("id_liga"),
                                rs.getObject("id_actor_usuario", Long.class),
                                rs.getString("actor_nickname"),
                                rs.getString("tipo"),
                                rs.getString("mensaje"),
                                rs.getObject("id_liga_participante_actor", Long.class),
                                rs.getObject("id_liga_participante_objetivo", Long.class),
                                rs.getObject("id_liga_jugador", Long.class),
                                rs.getObject("id_carta", Long.class),
                                rs.getObject("id_entrenador", Long.class),
                                rs.getObject("cantidad", Long.class),
                                rs.getString("metadata_json"),
                                ts == null ? null : ts.toInstant()
                        ));
                    }
                }
            }
            return events;
        }
    }

    /**
     * Check if a notification was already sent for this combination (idempotency).
     * Returns true if already sent.
     */
    public boolean wasNotificationSent(Connection conn, Long idLiga, Long idJornada, Long idUsuario, String tipo) throws SQLException {
        String sql = """
                SELECT 1 FROM liga_notificaciones_enviadas
                WHERE id_liga = ? AND id_jornada = ? AND id_usuario = ? AND tipo = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            ps.setLong(3, idUsuario);
            ps.setString(4, tipo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Mark a notification as sent (INSERT IGNORE for idempotency).
     */
    public void markNotificationSent(Connection conn, Long idLiga, Long idJornada, Long idUsuario, String tipo) throws SQLException {
        String sql = """
                INSERT IGNORE INTO liga_notificaciones_enviadas (id_liga, id_jornada, id_usuario, tipo)
                VALUES (?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            ps.setLong(3, idUsuario);
            ps.setString(4, tipo);
            ps.executeUpdate();
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

    private static void setLongOrNull(PreparedStatement ps, int idx, Long v) throws SQLException {
        if (v == null) ps.setNull(idx, Types.BIGINT); else ps.setLong(idx, v);
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) : s;
    }
}
