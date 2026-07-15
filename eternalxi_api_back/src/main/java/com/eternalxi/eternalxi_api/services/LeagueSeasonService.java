package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueSeasonWrapPlayerHighlight;
import com.eternalxi.eternalxi_api.dto.league.LeagueSeasonWrapResponse;
import com.eternalxi.eternalxi_api.dto.user.UserPublicLeaguePlayerStat;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class LeagueSeasonService {

    private static final Logger log = LoggerFactory.getLogger(LeagueSeasonService.class);

    public static final int ARCHIVE_DAYS_AFTER_LAST_MATCH = 7;
    public static final String NOTIFICATION_TYPE = "LEAGUE_SEASON_WRAP";

    private final UserNotificationService userNotificationService;

    public LeagueSeasonService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    /**
     * Ligas visibles en "Mis ligas": abiertas y no archivadas (menos de 7 dias desde el ultimo partido
     * si la temporada ya termino de forma natural).
     */
    public static String sqlVisibleInMyLeagues() {
        return """
                l.cerrada_en IS NULL
                AND NOT (
                    """ + sqlSeasonNaturallyCompleteOnLeagueAlias("l") + """
                    AND COALESCE((
                        SELECT MAX(pj.inicio_en)
                        FROM partidos_jornada pj
                        INNER JOIN jornadas j ON j.id = pj.id_jornada
                        WHERE j.id_liga = l.id
                          AND COALESCE(pj.estado, '') = 'FINALIZADO'
                    ), '1970-01-01') <= DATE_SUB(NOW(), INTERVAL """
                + ARCHIVE_DAYS_AFTER_LAST_MATCH + " DAY)"
                + """
                )
                """;
    }

    public static String sqlSeasonNaturallyCompleteOnLeagueAlias(String leagueAlias) {
        return """
                EXISTS (SELECT 1 FROM jornadas jx WHERE jx.id_liga = """
                + leagueAlias + ".id)"
                + """
                AND NOT EXISTS (
                    SELECT 1 FROM jornadas jx
                    WHERE jx.id_liga = """
                + leagueAlias + ".id"
                + """
                      AND COALESCE(jx.estado, '') <> 'FINALIZADA'
                )
                """;
    }

    public boolean isSeasonNaturallyComplete(Connection conn, long idLiga) throws SQLException {
        String sql = """
                SELECT 1
                FROM ligas l
                WHERE l.id = ?
                  AND l.cerrada_en IS NULL
                  AND """ + sqlSeasonNaturallyCompleteOnLeagueAlias("l") + """
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public Instant loadLastFinishedMatchInstant(Connection conn, long idLiga) throws SQLException {
        String sql = """
                SELECT MAX(pj.inicio_en) AS ultimo
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE j.id_liga = ?
                  AND COALESCE(pj.estado, '') = 'FINALIZADO'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Timestamp ts = rs.getTimestamp("ultimo");
                return ts == null ? null : ts.toInstant();
            }
        }
    }

    public boolean isArchivedFromActiveList(Instant lastMatchFinished) {
        if (lastMatchFinished == null) {
            return false;
        }
        Instant threshold = Instant.now().minus(ARCHIVE_DAYS_AFTER_LAST_MATCH, ChronoUnit.DAYS);
        return !lastMatchFinished.isAfter(threshold);
    }

    public LeagueSeasonWrapResponse getSeasonWrap(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idLiga <= 0 || idUsuario == null || idUsuario <= 0) {
            throw new IllegalArgumentException("Datos invalidos");
        }
        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }
            String nombreLiga = loadLeagueName(conn, idLiga);
            boolean complete = isSeasonNaturallyComplete(conn, idLiga);
            Instant lastMatch = complete ? loadLastFinishedMatchInstant(conn, idLiga) : null;
            boolean archived = complete && isArchivedFromActiveList(lastMatch);
            boolean cinematicSeen = isCinematicSeen(conn, idLiga, idUsuario);
            boolean showCinematic = complete && !cinematicSeen;

            int posicion = 0;
            int total = 0;
            int puntos = 0;
            LeagueSeasonWrapPlayerHighlight maxPuntos = null;
            LeagueSeasonWrapPlayerHighlight maxGoleador = null;
            LeagueSeasonWrapPlayerHighlight maxAsistente = null;

            if (complete) {
                StandingRow mine = loadParticipantStanding(conn, idLiga, idUsuario);
                if (mine != null) {
                    posicion = mine.posicion();
                    total = mine.totalParticipantes();
                    puntos = mine.puntosEfectivos();
                }
                maxPuntos = loadSquadTopByMetric(conn, idLiga, idUsuario, SquadMetric.PUNTOS);
                maxGoleador = loadSquadTopByMetric(conn, idLiga, idUsuario, SquadMetric.GOLES);
                maxAsistente = loadSquadTopByMetric(conn, idLiga, idUsuario, SquadMetric.ASISTENCIAS);
            }

            return new LeagueSeasonWrapResponse(
                    complete,
                    archived,
                    showCinematic,
                    posicion,
                    total,
                    puntos,
                    nombreLiga,
                    lastMatch,
                    maxPuntos,
                    maxGoleador,
                    maxAsistente
            );
        }
    }

    public void markSeasonWrapSeen(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            return;
        }
        try (Connection conn = DBConnection.getConnection()) {
            Long idLp = loadParticipantId(conn, idLiga, idUsuario);
            if (idLp == null) {
                return;
            }
            String sql = """
                    INSERT INTO liga_participante_temporada_wrap (
                        id_liga_participante, id_liga, id_usuario, cinematica_vista_en
                    )
                    VALUES (?, ?, ?, NOW())
                    ON DUPLICATE KEY UPDATE cinematica_vista_en = NOW()
                    """;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLp);
                ps.setLong(2, idLiga);
                ps.setLong(3, idUsuario);
                ps.executeUpdate();
            }
        }
    }

    public int processSeasonWrapNotifications() throws SQLException {
        int sent = 0;
        List<Long> leagueIds = loadLeaguesReadyForWrapNotification();
        for (Long idLiga : leagueIds) {
            sent += notifyLeagueParticipants(idLiga);
        }
        return sent;
    }

    public UserPublicLeaguePlayerStat loadSquadTopStat(
            Connection conn,
            long idLiga,
            long idUsuario,
            SquadMetric metric
    ) throws SQLException {
        LeagueSeasonWrapPlayerHighlight row = loadSquadTopByMetric(conn, idLiga, idUsuario, metric);
        if (row == null || row.valor() <= 0) {
            return null;
        }
        return new UserPublicLeaguePlayerStat(row.nombreMostrado(), row.fotoJugador(), row.valor());
    }

    public StandingRow loadParticipantStanding(Connection conn, long idLiga, long idUsuario)
            throws SQLException {
        String sql = """
                SELECT lp.id AS id_lp,
                       lp.id_usuario,
                       lp.puntos_totales + COALESCE((
                           SELECT SUM(pb.puntos)
                           FROM liga_participante_puntos_bonus pb
                           WHERE pb.id_liga_participante = lp.id
                       ), 0) AS puntos_efectivos,
                       lp.dinero,
                       COALESCE(SUM(lj.valor), 0) AS valor_total_equipo
                FROM liga_participantes lp
                LEFT JOIN liga_jugadores lj
                  ON lj.id_liga = lp.id_liga
                 AND lj.id_usuario_dueno = lp.id_usuario
                WHERE lp.id_liga = ?
                GROUP BY lp.id, lp.id_usuario, lp.puntos_totales, lp.dinero
                ORDER BY puntos_efectivos DESC, valor_total_equipo DESC, lp.id ASC
                """;
        List<StandingRow> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                int pos = 1;
                while (rs.next()) {
                    rows.add(new StandingRow(
                            pos,
                            0,
                            rs.getLong("id_usuario"),
                            rs.getInt("puntos_efectivos")
                    ));
                    pos++;
                }
            }
        }
        int total = rows.size();
        for (StandingRow row : rows) {
            if (row.idUsuario() == idUsuario) {
                return new StandingRow(row.posicion(), total, idUsuario, row.puntosEfectivos());
            }
        }
        return null;
    }

    private int notifyLeagueParticipants(long idLiga) throws SQLException {
        int sent = 0;
        try (Connection conn = DBConnection.getConnection()) {
            if (!isSeasonNaturallyComplete(conn, idLiga)) {
                return 0;
            }
            Instant lastMatch = loadLastFinishedMatchInstant(conn, idLiga);
            if (lastMatch == null || !isArchivedFromActiveList(lastMatch)) {
                return 0;
            }
            String nombreLiga = loadLeagueName(conn, idLiga);
            List<ParticipantRef> participants = loadParticipants(conn, idLiga);
            for (ParticipantRef p : participants) {
                StandingRow standing = loadParticipantStanding(conn, idLiga, p.idUsuario());
                if (standing == null) {
                    continue;
                }
                String titulo = "Temporada finalizada";
                String mensaje = "En %s has quedado en la posicion %d de %d con %d puntos."
                        .formatted(nombreLiga, standing.posicion(), standing.totalParticipantes(), standing.puntosEfectivos());
                String clave = NOTIFICATION_TYPE + "_" + idLiga + "_" + p.idUsuario();
                Map<String, Object> datos = new HashMap<>();
                datos.put("idLiga", idLiga);
                datos.put("posicion", standing.posicion());
                datos.put("totalParticipantes", standing.totalParticipantes());
                datos.put("puntosEfectivos", standing.puntosEfectivos());
                Map<String, String> pushData = new HashMap<>();
                pushData.put("type", NOTIFICATION_TYPE);
                pushData.put("actionRoute", "league_season_wrap");
                pushData.put("idLiga", String.valueOf(idLiga));
                userNotificationService.notifyUser(
                        p.idUsuario(),
                        idLiga,
                        NOTIFICATION_TYPE,
                        titulo,
                        mensaje,
                        datos,
                        clave,
                        pushData
                );
                sent++;
            }
        }
        return sent;
    }

    private List<Long> loadLeaguesReadyForWrapNotification() throws SQLException {
        String sql = """
                SELECT l.id
                FROM ligas l
                WHERE l.cerrada_en IS NULL
                  AND """ + sqlSeasonNaturallyCompleteOnLeagueAlias("l") + """
                  AND COALESCE((
                      SELECT MAX(pj.inicio_en)
                      FROM partidos_jornada pj
                      INNER JOIN jornadas j ON j.id = pj.id_jornada
                      WHERE j.id_liga = l.id
                        AND COALESCE(pj.estado, '') = 'FINALIZADO'
                  ), '1970-01-01') <= DATE_SUB(NOW(), INTERVAL """
                + ARCHIVE_DAYS_AFTER_LAST_MATCH + " DAY)";
        List<Long> ids = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ids.add(rs.getLong("id"));
            }
        }
        return ids;
    }

    public enum SquadMetric {
        PUNTOS("puntos"),
        GOLES("goles"),
        ASISTENCIAS("asistencias"),
        PORTERIAS_CERO("porteria_cero");

        private final String column;

        SquadMetric(String column) {
            this.column = column;
        }
    }

    private LeagueSeasonWrapPlayerHighlight loadSquadTopByMetric(
            Connection conn,
            long idLiga,
            long idUsuario,
            SquadMetric metric
    ) throws SQLException {
        String having = metric == SquadMetric.PUNTOS ? "" : "HAVING total > 0";
        String sql = """
                SELECT ju.id AS id_jugador,
                       ju.nombre,
                       ju.pila,
                       COALESCE(SUM(jp.%s), 0) AS total
                FROM jugadores_puntos_jornada jp
                INNER JOIN liga_jugadores lj ON lj.id = jp.id_liga_jugador
                INNER JOIN jugadores ju ON ju.id = lj.id_jugador
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                GROUP BY ju.id, ju.nombre, ju.pila
                %s
                ORDER BY total DESC, ju.nombre ASC
                LIMIT 1
                """.formatted(metric.column, having);
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                int total = rs.getInt("total");
                if (metric != SquadMetric.PUNTOS && total <= 0) {
                    return null;
                }
                long idJugador = rs.getLong("id_jugador");
                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");
                return new LeagueSeasonWrapPlayerHighlight(
                        idJugador,
                        nombre,
                        pila,
                        buildDisplayName(nombre, pila),
                        LeagueAssetUrls.player(idJugador),
                        total
                );
            }
        }
    }

    private boolean isCinematicSeen(Connection conn, long idLiga, long idUsuario) throws SQLException {
        String sql = """
                SELECT 1
                FROM liga_participante_temporada_wrap w
                INNER JOIN liga_participantes lp ON lp.id = w.id_liga_participante
                WHERE lp.id_liga = ?
                  AND lp.id_usuario = ?
                  AND w.cinematica_vista_en IS NOT NULL
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean isParticipant(Connection conn, long idLiga, long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM liga_participantes WHERE id_liga = ? AND id_usuario = ? LIMIT 1")) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Long loadParticipantId(Connection conn, long idLiga, long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM liga_participantes WHERE id_liga = ? AND id_usuario = ? LIMIT 1")) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    private String loadLeagueName(Connection conn, long idLiga) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(nombre, CONCAT('Liga ', id)) AS nombre FROM ligas WHERE id = ? LIMIT 1")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("nombre") : ("Liga " + idLiga);
            }
        }
    }

    private List<ParticipantRef> loadParticipants(Connection conn, long idLiga) throws SQLException {
        List<ParticipantRef> out = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id, id_usuario FROM liga_participantes WHERE id_liga = ?")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(new ParticipantRef(rs.getLong("id"), rs.getLong("id_usuario")));
                }
            }
        }
        return out;
    }

    private static String buildDisplayName(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) {
            return pila.trim();
        }
        return nombre == null ? "Jugador" : nombre.trim();
    }

    public record StandingRow(int posicion, int totalParticipantes, long idUsuario, int puntosEfectivos) {
    }

    private record ParticipantRef(long idLigaParticipante, long idUsuario) {
    }
}
