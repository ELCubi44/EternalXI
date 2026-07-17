package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
public class LeagueRewardService {

    private static final Logger log = LoggerFactory.getLogger(LeagueRewardService.class);

    private static final String ROUND_REWARD_POINTS_TYPE = "PUNTOS_RECOMPENSA_JORNADA";
    private static final String ROUND_MONEY_TYPE = "PREMIO_PUNTOS_JORNADA";

    /**
     * Push de cierre de jornada a enviar solo tras {@code COMMIT} de los premios (evita avisar sin haber persistido puntos/dinero).
     */
    public record PendingRoundRewardPush(
            long idLiga,
            long idJornada,
            int numJornada,
            long idUsuario,
            int posicionJornada,
            int puntosFantasyJornada,
            int rewardPts,
            int xpGanada
    ) {}

    private final LeagueLineupService leagueLineupService;
    private final LeaguePlayerMarketValueService leaguePlayerMarketValueService;
    private final LeagueActivityService leagueActivityService;
    private final PushNotificationService pushNotificationService;
    private final AccountProgressService accountProgressService;
    private final UserPublicProfileService userPublicProfileService;

    public LeagueRewardService(
            LeagueLineupService leagueLineupService,
            LeaguePlayerMarketValueService leaguePlayerMarketValueService,
            LeagueActivityService leagueActivityService,
            PushNotificationService pushNotificationService,
            AccountProgressService accountProgressService,
            UserPublicProfileService userPublicProfileService
    ) {
        this.leagueLineupService = leagueLineupService;
        this.leaguePlayerMarketValueService = leaguePlayerMarketValueService;
        this.leagueActivityService = leagueActivityService;
        this.pushNotificationService = pushNotificationService;
        this.accountProgressService = accountProgressService;
        this.userPublicProfileService = userPublicProfileService;
    }

    /**
     * Premios de jornada: puntos de recompensa descendentes por posición fantasy
     * ({@code recompensa_base_jornada} = mínimo del último puesto, +50 por puesto)
     * y dinero por puntos fantasy ({@code dinero_por_punto_fantasy}).
     * Idempotente: usa {@code liga_movimientos_economicos} con UNIQUE para no duplicar.
     *
     * @return datos para enviar push tras hacer {@code commit} en la misma transacción que estos cambios
     */
    public List<PendingRoundRewardPush> rewardFinalizedRound(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        if (conn == null || idLiga == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        if (!isRoundFinalized(conn, idLiga, idJornada)) {
            return List.of();
        }

        if (!allMatchesInRoundFinalized(conn, idLiga, idJornada)) {
            return List.of();
        }

        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);

        LeagueRoundRewardConfig rewardConfig = loadLeagueRoundRewardConfig(conn, idLiga);

        List<ParticipantRow> participants = loadLeagueParticipants(conn, idLiga);
        if (participants.isEmpty()) {
            return List.of();
        }

        Map<Long, Integer> pointsByUser = leagueLineupService.calculateRoundPointsByUser(conn, idLiga, idJornada);
        if (pointsByUser.isEmpty()) {
            return List.of();
        }

        List<LeagueRoundRewardDistribution.ParticipantRef> participantRefs = participants.stream()
                .map(p -> new LeagueRoundRewardDistribution.ParticipantRef(
                        p.idLigaParticipante(),
                        p.idUsuario(),
                        p.nickname()
                ))
                .toList();

        List<LeagueRoundRewardDistribution.RankedRoundReward> rankedRewards =
                LeagueRoundRewardDistribution.rankAndAssignRewards(
                        participantRefs,
                        pointsByUser,
                        rewardConfig.recompensaMinimaJornada(),
                        Map.of()
                );

        Map<Long, Integer> xpByUser = new java.util.HashMap<>();
        for (LeagueRoundRewardDistribution.RankedRoundReward ranked : rankedRewards) {
            Long idUsuario = ranked.idUsuario();
            int puntosJornada = ranked.puntosFantasyJornada();
            long presupuestoEuros = (long) puntosJornada * rewardConfig.dineroPorPuntoFantasy();
            int rewardPts = ranked.puntosRecompensaJornada();

            grantRewardPointsIfMissing(
                    conn,
                    idLiga,
                    idJornada,
                    ranked.idLigaParticipante(),
                    idUsuario,
                    rewardPts
            );
            grantRoundMoneyIfMissing(
                    conn,
                    idLiga,
                    idJornada,
                    ranked.idLigaParticipante(),
                    idUsuario,
                    puntosJornada,
                    presupuestoEuros
            );
            int xpGanada = accountProgressService.onRoundFinished(
                    conn, idLiga, idJornada, idUsuario, puntosJornada);
            try {
                userPublicProfileService.unlockFantasyAvatarsForRound(conn, idUsuario, idJornada);
            } catch (Exception e) {
                log.warn(
                        "No se pudieron desbloquear avatares Fantasy user={} jornada={}: {}",
                        idUsuario,
                        idJornada,
                        e.getMessage()
                );
            }
            xpByUser.put(idUsuario, xpGanada);
        }

        int numJornada = loadRoundNumber(conn, idJornada);

        leagueActivityService.recordActivity(
                conn,
                idLiga,
                null, null,
                "ROUND_FINISHED",
                "Jornada " + numJornada + " finalizada: recompensas repartidas por posición.",
                null, null, null, null, null, null, null
        );

        List<PendingRoundRewardPush> pendingPush = new ArrayList<>(rankedRewards.size());
        for (LeagueRoundRewardDistribution.RankedRoundReward ranked : rankedRewards) {
            pendingPush.add(new PendingRoundRewardPush(
                    idLiga,
                    idJornada,
                    numJornada,
                    ranked.idUsuario(),
                    ranked.posicionJornada(),
                    ranked.puntosFantasyJornada(),
                    ranked.puntosRecompensaJornada(),
                    xpByUser.getOrDefault(ranked.idUsuario(), 0)
            ));
        }
        return Collections.unmodifiableList(pendingPush);
    }

    /**
     * Envía las push de premios de jornada; debe llamarse cuando los premios ya están confirmados en BD ({@code COMMIT} hecho).
     */
    public void deliverRoundRewardPushNotifications(List<PendingRoundRewardPush> pending) {
        if (pending == null || pending.isEmpty()) {
            return;
        }
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(true);
            for (PendingRoundRewardPush item : pending) {
                deliverRoundRewardPush(conn, item);
            }
        } catch (SQLException e) {
            log.warn("No se pudieron enviar notificaciones de premios de jornada: {}", e.getMessage());
        }
    }

    private boolean isRoundFinalized(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT estado
                FROM jornadas
                WHERE id = ? AND id_liga = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                return "FINALIZADA".equals(rs.getString("estado"));
            }
        }
    }

    private boolean allMatchesInRoundFinalized(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS pendientes
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE pj.id_jornada = ? AND j.id_liga = ? AND pj.estado <> 'FINALIZADO'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("pendientes") == 0;
            }
        }
    }

    private void grantRewardPointsIfMissing(
            Connection conn,
            Long idLiga,
            Long idJornada,
            long idLigaParticipante,
            Long idUsuario,
            int puntosRecompensa
    ) throws SQLException {
        String insertSql = """
                INSERT IGNORE INTO liga_movimientos_economicos (
                    id_liga, id_jornada, id_liga_participante, id_usuario, tipo, puntos, cantidad
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """;
        int inserted;
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            ps.setLong(3, idLigaParticipante);
            ps.setLong(4, idUsuario);
            ps.setString(5, ROUND_REWARD_POINTS_TYPE);
            ps.setInt(6, puntosRecompensa);
            ps.setLong(7, puntosRecompensa);
            inserted = ps.executeUpdate();
        }
        if (inserted > 0) {
            addRewardPointsToParticipant(conn, idLigaParticipante, puntosRecompensa);
            insertRewardEvent(conn, idLiga, idLigaParticipante, idUsuario, puntosRecompensa,
                    "Puntos recompensa jornada (" + puntosRecompensa + ")");
        }
    }

    private void grantRoundMoneyIfMissing(
            Connection conn,
            Long idLiga,
            Long idJornada,
            long idLigaParticipante,
            Long idUsuario,
            int puntosJornada,
            long cantidadEuros
    ) throws SQLException {
        if (cantidadEuros <= 0) {
            return;
        }
        String insertSql = """
                INSERT IGNORE INTO liga_movimientos_economicos (
                    id_liga, id_jornada, id_liga_participante, id_usuario, tipo, puntos, cantidad
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """;
        int inserted;
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            ps.setLong(3, idLigaParticipante);
            ps.setLong(4, idUsuario);
            ps.setString(5, ROUND_MONEY_TYPE);
            ps.setInt(6, puntosJornada);
            ps.setLong(7, cantidadEuros);
            inserted = ps.executeUpdate();
        }
        if (inserted > 0) {
            addMoneyToParticipant(conn, idLiga, idUsuario, cantidadEuros);
        }
    }

    private void addRewardPointsToParticipant(Connection conn, long idLigaParticipante, int puntos) throws SQLException {
        String sql = "UPDATE liga_participantes SET puntos_recompensa = puntos_recompensa + ? WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, puntos);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private void insertRewardEvent(
            Connection conn,
            Long idLiga,
            long idLigaParticipante,
            Long idUsuario,
            int cantidad,
            String descripcion
    ) throws SQLException {
        String sql = """
                INSERT INTO liga_recompensa_eventos (
                    id_liga, id_liga_participante, id_usuario, tipo, cantidad, descripcion
                ) VALUES (?,?,?,?,?,?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaParticipante);
            ps.setLong(3, idUsuario);
            ps.setString(4, "ROUND_REWARD_POINTS");
            ps.setLong(5, cantidad);
            ps.setString(6, descripcion);
            ps.executeUpdate();
        }
    }

    private void addMoneyToParticipant(Connection conn, Long idLiga, Long idUsuario, long delta) throws SQLException {
        if (delta == 0) {
            return;
        }
        String sql = """
                UPDATE liga_participantes
                SET dinero = dinero + ?
                WHERE id_liga = ? AND id_usuario = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, delta);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuario);
            ps.executeUpdate();
        }
    }

    private List<ParticipantRow> loadLeagueParticipants(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT lp.id, lp.id_usuario, COALESCE(u.nickname, '') AS nickname
                FROM liga_participantes lp
                LEFT JOIN usuarios u ON u.id = lp.id_usuario
                WHERE lp.id_liga = ?
                ORDER BY lp.id ASC
                """;
        List<ParticipantRow> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new ParticipantRow(
                            rs.getLong("id"),
                            rs.getLong("id_usuario"),
                            rs.getString("nickname")
                    ));
                }
            }
        }
        return rows;
    }

    private LeagueRoundRewardConfig loadLeagueRoundRewardConfig(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT recompensa_base_jornada, recompensa_bonus_ganador, dinero_por_punto_fantasy
                FROM ligas
                WHERE id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Liga no encontrada: " + idLiga);
                }
                return new LeagueRoundRewardConfig(
                        rs.getInt("recompensa_base_jornada"),
                        rs.getLong("dinero_por_punto_fantasy")
                );
            }
        }
    }

    private int loadRoundNumber(Connection conn, Long idJornada) throws SQLException {
        String sql = "SELECT numero FROM jornadas WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("numero") : 0;
            }
        }
    }

    private void deliverRoundRewardPush(Connection conn, PendingRoundRewardPush item) {
        Long idUsuario = item.idUsuario();
        try {
            if (leagueActivityService.wasNotificationSent(conn, item.idLiga(), item.idJornada(), idUsuario, "ROUND_REWARD")) {
                return;
            }

            String title;
            String body;
            String xpSuffix = item.xpGanada() > 0
                    ? " +" + item.xpGanada() + " XP de cuenta."
                    : "";
            if (item.posicionJornada() == 1) {
                title = "¡Ganador de la jornada!";
                body = "Jornada " + item.numJornada() + ": tu equipo sumó "
                        + item.puntosFantasyJornada() + " pts. Recibiste +"
                        + item.rewardPts() + " pts de recompensa por quedar 1º."
                        + xpSuffix;
            } else {
                title = "Jornada finalizada";
                body = "Jornada " + item.numJornada() + ": posición "
                        + item.posicionJornada() + ". Tu equipo sumó "
                        + item.puntosFantasyJornada() + " pts y recibiste +"
                        + item.rewardPts() + " pts de recompensa."
                        + xpSuffix;
            }

            pushNotificationService.sendToUser(
                    idUsuario,
                    title,
                    body,
                    Map.of(
                            "type", "ROUND_REWARD",
                            "idLiga", String.valueOf(item.idLiga()),
                            "idJornada", String.valueOf(item.idJornada())
                    )
            );
            leagueActivityService.markNotificationSent(conn, item.idLiga(), item.idJornada(), idUsuario, "ROUND_REWARD");
        } catch (Exception e) {
            log.warn("Error enviando notificación de jornada a usuario {}: {}", idUsuario, e.getMessage());
        }
    }

    private record LeagueRoundRewardConfig(
            int recompensaMinimaJornada,
            long dineroPorPuntoFantasy
    ) {}

    private record ParticipantRow(long idLigaParticipante, long idUsuario, String nickname) {}
}
