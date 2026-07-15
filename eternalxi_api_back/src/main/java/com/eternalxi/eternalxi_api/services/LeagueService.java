package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.validation.InputValidator;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.CreateLeagueResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueCreationConfig;
import com.eternalxi.eternalxi_api.dto.league.JoinLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.JoinLeagueResponse;
import com.eternalxi.eternalxi_api.dto.league.KickParticipantRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueAssignedCoachResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueOwnSquadResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantSquadResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSquadPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.StarterProbabilityLite;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundStandingsRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueStandingsRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSummaryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaveLeagueRequest;
import com.eternalxi.eternalxi_api.dto.league.TransferLeagueAdminRequest;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Random;
import java.util.Set;

@Service
public class LeagueService {

    private static final Logger log = LoggerFactory.getLogger(LeagueService.class);

    private final NightMarketService nightMarketService;
    private static final int MAX_ACTIVE_LEAGUES_PER_USER = 3;
    private static final Set<Long> LEAGUE_LIMIT_EXEMPT_USER_IDS = Set.of(1L, 3L);
    private static final long MARKET_USER_ID = 1L;
    private static final int STAR_RATING_LIMIT = 86;
    private static final int MAX_PLAYERS_PER_TEAM = 3;

    private static final long INITIAL_TOTAL_BUDGET = 400_000_000L;

    /** Objetivo de plantilla inicial al entrar en liga; no obligatorio si el mercado está agotado. */
    private static final int TARGET_INITIAL_SQUAD_SIZE = InitialSquadSelector.SQUAD_SIZE;

    /** Puntos de recompensa iniciales por participante al crear o unirse a una liga ({@code liga_participantes.puntos_recompensa}). */
    public static final long INITIAL_LEAGUE_REWARD_POINTS = 1000L;

    private static final LocalTime SLOT_1 = LocalTime.of(17, 0);
    private static final LocalTime SLOT_2 = LocalTime.of(19, 0);
    private static final LocalTime SLOT_3 = LocalTime.of(21, 0);

    private final LeaguePlayerPricingService pricingService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeagueDataService leagueDataService;
    private final LeaguePlayerMarketValueService leaguePlayerMarketValueService;
    @Autowired
    private LeagueLineupService leagueLineupService;
    @Autowired
    private LeagueActivityService leagueActivityService;
    @Autowired
    private AccountProgressService accountProgressService;
    @Autowired
    private FriendshipService friendshipService;
    @Autowired
    private LeagueInviteNotificationService leagueInviteNotificationService;

    public LeagueService(
            LeaguePlayerPricingService pricingService,
            NightMarketService nightMarketService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeagueDataService leagueDataService,
            LeaguePlayerMarketValueService leaguePlayerMarketValueService
    ) {
        this.pricingService = pricingService;
        this.nightMarketService = nightMarketService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leagueDataService = leagueDataService;
        this.leaguePlayerMarketValueService = leaguePlayerMarketValueService;
    }

    public CreateLeagueResponse createLeague(CreateLeagueRequest request) throws SQLException {
        validateCreateLeagueRequest(request);
        LeagueCreationConfig config = LeagueCreationConfig.resolve(request);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                validateSeasonAccess(conn, request.idUsuario(), request.idTemporada());
                validateActiveLeagueLimit(conn, request.idUsuario());
                String invitationCode = generateUniqueInvitationCode(conn);
                Long leagueId = insertLeague(
                        conn,
                        request.nombre().trim(),
                        request.idTemporada(),
                        request.idUsuario(),
                        invitationCode,
                        config
                );

                copySeasonPlayersToLeague(conn, leagueId, request.idTemporada());
                CalendarGenerationResult calendar = generateLeagueCalendar(
                        conn,
                        leagueId,
                        request.idTemporada(),
                        config
                );

                insertParticipant(conn, leagueId, request.idUsuario(), 0L);

                InitialSquadAssignment assignment = assignInitialSquadBestEffort(conn, leagueId, request.idUsuario());
                long initialMoney = calculateInitialMoney(assignment.totalValue());

                updateParticipantMoney(conn, leagueId, request.idUsuario(), initialMoney);
                leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, leagueId, request.idUsuario());

                nightMarketService.ensureTodayMarketExists(conn, leagueId);

                conn.commit();

                try {
                    leagueStarterProbabilityService.recalculateForLeague(leagueId);
                } catch (SQLException probEx) {
                    log.warn(
                            "Liga {} creada pero falló el recálculo inicial de probabilidades de titularidad: {}",
                            leagueId,
                            probEx.getMessage()
                    );
                }

                return new CreateLeagueResponse(
                        leagueId,
                        config.maxParticipantes(),
                        config.semanaPreviaFichajes(),
                        config.permiteEntresemana(),
                        config.idaYVuelta(),
                        config.recompensaBaseJornada(),
                        config.recompensaBonusGanador(),
                        config.dineroPorPuntoFantasy(),
                        calendar.numeroJornadas(),
                        calendar.primerPartidoEn(),
                        calendar.finLigaEn()
                );

            } catch (Exception e) {
            conn.rollback();

            if (e instanceof IllegalArgumentException illegalArgumentException) {
                throw illegalArgumentException;
            }

            if (e instanceof SQLException sqlException) {
                throw sqlException;
            }

            throw new SQLException("Error creando liga: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }
}

private void validateActiveLeagueLimit(Connection conn, Long idUsuario) throws SQLException {
    if (idUsuario == null) {
        throw new IllegalArgumentException("El usuario es obligatorio");
    }

    if (LEAGUE_LIMIT_EXEMPT_USER_IDS.contains(idUsuario)) {
        return;
    }

    int totalActiveLeagues = countActiveOpenLeaguesForUser(conn, idUsuario);
    if (totalActiveLeagues >= MAX_ACTIVE_LEAGUES_PER_USER) {
        throw new IllegalArgumentException("Has alcanzado el máximo de 3 ligas activas");
    }
}

private int countActiveOpenLeaguesForUser(Connection conn, Long idUsuario) throws SQLException {
    String sql = """
            SELECT COUNT(*) AS total
            FROM liga_participantes lp
            INNER JOIN ligas l ON l.id = lp.id_liga
            WHERE lp.id_usuario = ?
              AND """ + LeagueSeasonService.sqlVisibleInMyLeagues() + """
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idUsuario);

        try (ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt("total");
        }
    }
}

    public JoinLeagueResponse joinLeague(JoinLeagueRequest request) throws SQLException {
        validateJoinLeagueRequest(request);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                LeagueData league = findLeagueByInvitationCodeForUpdate(conn, request.codigoInvitacion().trim().toUpperCase());

                if (league == null) {
                    throw new IllegalArgumentException("Liga no encontrada");
                }

                if (league.closedAt() != null) {
                    throw new IllegalArgumentException("La liga está cerrada");
                }

                validateSeasonAccess(conn, request.idUsuario(), league.idTemporada());

                if (isParticipant(conn, league.id(), request.idUsuario())) {
                    throw new IllegalArgumentException("Ya perteneces a esta liga");
                }
                validateActiveLeagueLimit(conn, request.idUsuario());

                if (countParticipants(conn, league.id()) >= league.maxParticipantes()) {
                    throw new IllegalArgumentException("La liga ya está completa");
                }

                long idLigaParticipante = insertParticipant(conn, league.id(), request.idUsuario(), 0L);

                InitialSquadAssignment assignment =
                        assignInitialSquadBestEffort(conn, league.id(), request.idUsuario());
                long initialMoney = calculateInitialMoney(assignment.totalValue());

                updateParticipantMoney(conn, league.id(), request.idUsuario(), initialMoney);
                leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, league.id(), request.idUsuario());

                conn.commit();

                String mensaje = buildJoinSquadMessage(assignment);
                return new JoinLeagueResponse(
                        true,
                        league.id(),
                        idLigaParticipante,
                        assignment.assignedCount(),
                        assignment.incomplete(),
                        assignment.totalValue(),
                        InitialSquadSelector.MIN_INITIAL_SQUAD_VALUE,
                        InitialSquadSelector.MAX_INITIAL_SQUAD_VALUE,
                        mensaje
                );

            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error uniéndose a la liga: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void inviteFriendToLeague(Long idLiga, Long idAdmin, Long idAmigo) throws SQLException {
        if (idLiga == null || idAdmin == null || idAmigo == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idAdmin.equals(idAmigo)) {
            throw new IllegalArgumentException("No puedes invitarte a ti mismo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            LeagueData league = findLeagueById(conn, idLiga);
            if (league == null) {
                throw new IllegalArgumentException("Liga no encontrada");
            }
            if (league.closedAt() != null) {
                throw new IllegalArgumentException("La liga está cerrada");
            }
            if (!Objects.equals(league.idAdministrador(), idAdmin)) {
                throw new IllegalArgumentException("Solo el administrador puede invitar amigos");
            }
            if (!friendshipService.areFriends(idAdmin, idAmigo)) {
                throw new IllegalArgumentException("Solo puedes invitar a tus amigos");
            }
            if (isParticipant(conn, league.id(), idAmigo)) {
                throw new IllegalArgumentException("Ese jugador ya está en la liga");
            }
            if (countParticipants(conn, league.id()) >= league.maxParticipantes()) {
                throw new IllegalArgumentException("La liga ya está completa");
            }

            String adminNick = loadUserNickname(conn, idAdmin);
            leagueInviteNotificationService.notifyLeagueInvite(
                    idAmigo,
                    idAdmin,
                    adminNick,
                    league.id(),
                    league.nombre(),
                    league.codigoInvitacion()
            );
        }
    }

    private String loadUserNickname(Connection conn, Long id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT nickname FROM usuarios WHERE id = ? LIMIT 1")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return "Administrador";
                }
                String nick = rs.getString("nickname");
                return nick == null || nick.isBlank() ? "Administrador" : nick.trim();
            }
        }
    }

    public List<LeagueSummaryResponse> getMyLeagues(Long idUsuario) throws SQLException {
        if (idUsuario == null) {
            throw new IllegalArgumentException("El usuario es obligatorio");
        }

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT l.id,
                           l.nombre,
                           l.id_temporada,
                           l.codigo_invitacion,
                           CASE WHEN l.id_administrador = ? THEN TRUE ELSE FALSE END AS soy_admin,
                           (SELECT COUNT(*) FROM liga_participantes lp2 WHERE lp2.id_liga = l.id) AS participantes
                    FROM liga_participantes lp
                    INNER JOIN ligas l ON l.id = lp.id_liga
                    WHERE lp.id_usuario = ?
                      AND """ + LeagueSeasonService.sqlVisibleInMyLeagues() + """
                    ORDER BY l.id DESC
                    """;

            List<LeagueSummaryResponse> leagues = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, idUsuario);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        leagues.add(new LeagueSummaryResponse(
                                rs.getLong("id"),
                                rs.getString("nombre"),
                                rs.getLong("id_temporada"),
                                rs.getString("codigo_invitacion"),
                                rs.getBoolean("soy_admin"),
                                rs.getInt("participantes")
                        ));
                    }
                }
            }

            return leagues;
        }
    }

    public LeagueDetailResponse getLeagueDetail(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            leagueLineupService.recalculateParticipantPoints(conn, idLiga);

            String sql = """
                    SELECT l.id,
                           l.nombre,
                           l.id_temporada,
                           l.codigo_invitacion,
                           l.id_administrador,
                           CASE WHEN l.id_administrador = ? THEN TRUE ELSE FALSE END AS soy_admin,
                           (SELECT COUNT(*) FROM liga_participantes lp2 WHERE lp2.id_liga = l.id) AS participantes,
                           COALESCE(lp.dinero, 0) AS mi_dinero,
                           COALESCE(lp.puntos_totales, 0) AS mis_puntos_fantasy,
                           COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS mis_puntos_bonus,
                           COALESCE(lp.puntos_totales, 0) + COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS mis_puntos,
                           COALESCE((
                               SELECT SUM(lj.valor)
                               FROM liga_jugadores lj
                               WHERE lj.id_liga = l.id
                                 AND lj.id_usuario_dueno = ?
                           ), 0) AS mi_valor_equipo,
                           l.max_participantes,
                           l.semana_previa_fichajes,
                           l.permite_entresemana,
                           l.ida_y_vuelta,
                           l.recompensa_base_jornada,
                           l.recompensa_bonus_ganador,
                           l.dinero_por_punto_fantasy
                    FROM ligas l
                    LEFT JOIN liga_participantes lp
                      ON lp.id_liga = l.id AND lp.id_usuario = ?
                    WHERE l.id = ?
                    """;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, idUsuario);
                ps.setLong(3, idUsuario);
                ps.setLong(4, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Liga no encontrada");
                    }

                    return new LeagueDetailResponse(
                            rs.getLong("id"),
                            rs.getString("nombre"),
                            rs.getLong("id_temporada"),
                            rs.getString("codigo_invitacion"),
                            rs.getLong("id_administrador"),
                            rs.getBoolean("soy_admin"),
                            rs.getInt("participantes"),
                            rs.getLong("mi_dinero"),
                            rs.getInt("mis_puntos_fantasy"),
                            rs.getInt("mis_puntos_bonus"),
                            rs.getInt("mis_puntos"),
                            rs.getLong("mi_valor_equipo"),
                            rs.getInt("max_participantes"),
                            rs.getBoolean("semana_previa_fichajes"),
                            rs.getBoolean("permite_entresemana"),
                            rs.getBoolean("ida_y_vuelta"),
                            rs.getInt("recompensa_base_jornada"),
                            rs.getInt("recompensa_bonus_ganador"),
                            rs.getLong("dinero_por_punto_fantasy")
                    );
                }
            }
        }
    }

    public List<LeagueStandingsRowResponse> getStandings(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            leagueLineupService.recalculateParticipantPoints(conn, idLiga);

            String sql = """
                    SELECT lp.id AS id_liga_participante,
                           lp.id_usuario,
                           u.nickname,
                           lp.puntos_totales AS puntos_fantasy,
                           COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS puntos_bonus,
                           lp.puntos_totales + COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS puntos_efectivos,
                           lp.dinero,
                           CASE WHEN l.id_administrador = lp.id_usuario THEN TRUE ELSE FALSE END AS admin,
                           COALESCE(SUM(lj.valor), 0) AS valor_total_equipo
                    FROM liga_participantes lp
                    INNER JOIN usuarios u ON u.id = lp.id_usuario
                    INNER JOIN ligas l ON l.id = lp.id_liga
                    LEFT JOIN liga_jugadores lj
                      ON lj.id_liga = lp.id_liga
                     AND lj.id_usuario_dueno = lp.id_usuario
                    WHERE lp.id_liga = ?
                    GROUP BY lp.id, lp.id_usuario, u.nickname, lp.puntos_totales, lp.dinero, l.id_administrador
                    ORDER BY puntos_efectivos DESC, valor_total_equipo DESC, u.nickname ASC
                    """;

            List<LeagueStandingsRowResponse> standings = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    int position = 1;

                    while (rs.next()) {
                        standings.add(new LeagueStandingsRowResponse(
                                position,
                                rs.getLong("id_liga_participante"),
                                rs.getLong("id_usuario"),
                                rs.getString("nickname"),
                                rs.getInt("puntos_fantasy"),
                                rs.getInt("puntos_bonus"),
                                rs.getInt("puntos_efectivos"),
                                rs.getLong("dinero"),
                                rs.getLong("valor_total_equipo"),
                                rs.getBoolean("admin")
                        ));
                        position++;
                    }
                }
            }

            return standings;
        }
    }

    public List<LeagueRoundStandingsRowResponse> getRoundStandings(
            Long idLiga,
            Long idJornada,
            Long idUsuario
    ) throws SQLException {
        if (idLiga == null || idJornada == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            String estadoJornada = loadRoundEstado(conn, idLiga, idJornada);
            if (estadoJornada == null) {
                throw new IllegalArgumentException("Jornada no encontrada");
            }
            String estadoNorm = estadoJornada.trim().toUpperCase();
            boolean finalizada = "FINALIZADA".equals(estadoNorm);
            if (!finalizada && !"EN_CURSO".equals(estadoNorm)) {
                throw new IllegalArgumentException("La jornada aún no está disponible");
            }

            int recompensaMinima = loadLeagueRecompensaMinima(conn, idLiga);
            Map<Long, Integer> fantasyByUser = leagueLineupService.calculateRoundPointsByUser(
                    conn,
                    idLiga,
                    idJornada
            );
            Map<Long, Integer> grantedRewards = finalizada
                    ? loadRoundGrantedRewards(conn, idLiga, idJornada)
                    : Map.of();

            String participantsSql = """
                    SELECT lp.id AS id_liga_participante,
                           lp.id_usuario,
                           COALESCE(u.nickname, '') AS nickname,
                           CASE WHEN l.id_administrador = lp.id_usuario THEN TRUE ELSE FALSE END AS admin,
                           COALESCE(SUM(lj.valor), 0) AS valor_total_equipo
                    FROM liga_participantes lp
                    INNER JOIN usuarios u ON u.id = lp.id_usuario
                    INNER JOIN ligas l ON l.id = lp.id_liga
                    LEFT JOIN liga_jugadores lj
                      ON lj.id_liga = lp.id_liga
                     AND lj.id_usuario_dueno = lp.id_usuario
                    WHERE lp.id_liga = ?
                    GROUP BY lp.id, lp.id_usuario, u.nickname, l.id_administrador
                    ORDER BY lp.id ASC
                    """;

            List<LeagueRoundRewardDistribution.ParticipantRef> participantRefs = new ArrayList<>();
            Map<Long, Long> valorByUser = new java.util.HashMap<>();
            Map<Long, Boolean> adminByUser = new java.util.HashMap<>();

            try (PreparedStatement ps = conn.prepareStatement(participantsSql)) {
                ps.setLong(1, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long idUsu = rs.getLong("id_usuario");
                        participantRefs.add(new LeagueRoundRewardDistribution.ParticipantRef(
                                rs.getLong("id_liga_participante"),
                                idUsu,
                                rs.getString("nickname")
                        ));
                        valorByUser.put(idUsu, rs.getLong("valor_total_equipo"));
                        adminByUser.put(idUsu, rs.getBoolean("admin"));
                    }
                }
            }

            List<LeagueRoundRewardDistribution.RankedRoundReward> ranked =
                    LeagueRoundRewardDistribution.rankAndAssignRewards(
                            participantRefs,
                            fantasyByUser,
                            recompensaMinima,
                            grantedRewards
                    );

            List<LeagueRoundStandingsRowResponse> rows = new ArrayList<>(ranked.size());
            for (LeagueRoundRewardDistribution.RankedRoundReward item : ranked) {
                rows.add(new LeagueRoundStandingsRowResponse(
                        item.posicionJornada(),
                        item.idLigaParticipante(),
                        item.idUsuario(),
                        item.nickname(),
                        item.puntosFantasyJornada(),
                        finalizada ? item.puntosRecompensaJornada() : 0,
                        valorByUser.getOrDefault(item.idUsuario(), 0L),
                        adminByUser.getOrDefault(item.idUsuario(), false)
                ));
            }
            return rows;
        }
    }

    private String loadRoundEstado(Connection conn, Long idLiga, Long idJornada) throws SQLException {
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
                return rs.next() ? rs.getString("estado") : null;
            }
        }
    }

    private int loadLeagueRecompensaMinima(Connection conn, Long idLiga) throws SQLException {
        String sql = "SELECT recompensa_base_jornada FROM ligas WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Liga no encontrada: " + idLiga);
                }
                return rs.getInt("recompensa_base_jornada");
            }
        }
    }

    private Map<Long, Integer> loadRoundGrantedRewards(Connection conn, Long idLiga, Long idJornada)
            throws SQLException {
        String sql = """
                SELECT id_usuario, puntos
                FROM liga_movimientos_economicos
                WHERE id_liga = ?
                  AND id_jornada = ?
                  AND tipo = 'PUNTOS_RECOMPENSA_JORNADA'
                """;
        Map<Long, Integer> out = new java.util.HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.put(rs.getLong("id_usuario"), rs.getInt("puntos"));
                }
            }
        }
        return out;
    }

    public List<LeagueParticipantResponse> getParticipants(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            leagueLineupService.recalculateParticipantPoints(conn, idLiga);

            String sql = """
                    SELECT lp.id AS id_liga_participante,
                           lp.id_usuario,
                           u.nickname,
                           CASE WHEN l.id_administrador = lp.id_usuario THEN TRUE ELSE FALSE END AS admin,
                           lp.puntos_totales AS puntos_fantasy,
                           COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS puntos_bonus,
                           lp.puntos_totales + COALESCE((
                               SELECT SUM(pb.puntos)
                               FROM liga_participante_puntos_bonus pb
                               WHERE pb.id_liga_participante = lp.id
                           ), 0) AS puntos_efectivos,
                           lp.dinero,
                           COALESCE(SUM(lj.valor), 0) AS valor_total_equipo
                    FROM liga_participantes lp
                    INNER JOIN usuarios u ON u.id = lp.id_usuario
                    INNER JOIN ligas l ON l.id = lp.id_liga
                    LEFT JOIN liga_jugadores lj
                      ON lj.id_liga = lp.id_liga
                     AND lj.id_usuario_dueno = lp.id_usuario
                    WHERE lp.id_liga = ?
                    GROUP BY lp.id, lp.id_usuario, u.nickname, l.id_administrador, lp.puntos_totales, lp.dinero
                    ORDER BY admin DESC, u.nickname ASC
                    """;

            List<LeagueParticipantResponse> participants = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        participants.add(new LeagueParticipantResponse(
                                rs.getLong("id_liga_participante"),
                                rs.getLong("id_usuario"),
                                rs.getString("nickname"),
                                rs.getBoolean("admin"),
                                rs.getInt("puntos_fantasy"),
                                rs.getInt("puntos_bonus"),
                                rs.getInt("puntos_efectivos"),
                                rs.getLong("dinero"),
                                rs.getLong("valor_total_equipo")
                        ));
                    }
                }
            }

            return participants;
        }
    }

    public LeagueOwnSquadResponse getSquad(Long idLiga, Long idUsuario, Long idJornadaContext) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuario)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            Long idLigaParticipante = loadLeagueParticipantId(conn, idLiga, idUsuario);
            if (idLigaParticipante == null) {
                throw new IllegalArgumentException("Participante no encontrado en la liga");
            }

            List<LeagueSquadPlayerResponse> plantilla =
                    loadSquadForViewer(conn, idLiga, idUsuario, idUsuario, idJornadaContext);
            LeagueAssignedCoachResponse entrenadorAsignado = loadAssignedCoachByParticipant(conn, idLigaParticipante);
            boolean entrenadorActivo = entrenadorAsignado != null && Boolean.TRUE.equals(entrenadorAsignado.activo());
            String formacionEfectiva = entrenadorActivo ? entrenadorAsignado.formacion() : "4-3-3";

            return new LeagueOwnSquadResponse(
                    idLiga,
                    idLigaParticipante,
                    idUsuario,
                    entrenadorAsignado,
                    entrenadorActivo,
                    formacionEfectiva,
                    plantilla
            );
        }
    }

    private List<LeagueSquadPlayerResponse> getSquadForViewer(
            Long idLiga,
            Long idUsuarioDueno,
            Long idUsuarioConsultante
    ) throws SQLException {
    if (idLiga == null || idUsuarioDueno == null || idUsuarioConsultante == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        if (!isParticipant(conn, idLiga, idUsuarioConsultante)) {
            throw new IllegalArgumentException("No perteneces a esta liga");
        }

        String sql = """
                SELECT
                    lj.id AS id_liga_jugador,
                    j.id AS id_jugador,
                    j.nombre,
                    j.pila,
                    j.posicion,
                    CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                    e.id AS id_equipo,
                    e.nombre AS nombre_equipo,
                    lj.estado,
                    lj.cansancio,
                    lj.valor,
                    j.foto AS foto_jugador,
                    CASE
                        WHEN lj.id_usuario_dueno = ?
                         AND EXISTS (
                             SELECT 1
                             FROM ofertas_jugador oj
                             WHERE oj.id_liga = lj.id_liga
                               AND oj.id_liga_jugador = lj.id
                               AND oj.estado = 'PENDIENTE'
                         ) THEN TRUE
                        ELSE FALSE
                    END AS tiene_oferta_pendiente
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = lj.id_equipo
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                ORDER BY
                    CASE j.posicion
                        WHEN 'POR' THEN 1
                        WHEN 'DEF' THEN 2
                        WHEN 'MED' THEN 3
                        WHEN 'DEL' THEN 4
                        ELSE 5
                    END,
                    lj.valor DESC,
                    j.nombre ASC
                """;

        List<LeagueSquadPlayerResponse> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuarioConsultante);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuarioDueno);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id_liga_jugador");
                    long idEq = rs.getLong("id_equipo");
                    String posicionRow = rs.getString("posicion");
                    int puntosTotales =
                            leagueDataService.sumFantasyPointsVisibleForPlayer(conn, idLiga, idLj, idEq, posicionRow);

                    players.add(new LeagueSquadPlayerResponse(
                            idLj,
                            rs.getLong("id_jugador"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            posicionRow,
                            rs.getInt("valoracion"),
                            idEq,
                            rs.getString("nombre_equipo"),
                            rs.getString("estado"),
                            rs.getInt("cansancio"),
                            rs.getLong("valor"),
                            LeagueAssetUrls.player(rs.getLong("id_jugador")),
                            puntosTotales,
                            rs.getBoolean("tiene_oferta_pendiente"),
                            null,
                            null,
                            null,
                            null,
                            rs.getLong("valor"),
                            false,
                            null,
                            false,
                            false,
                            null
                    ));
                }
            }
        }

        return enrichSquadWithStarterProbabilities(conn, idLiga, null, enrichSquadMarketValues(conn, idLiga, players));
    }
    }

    private List<LeagueSquadPlayerResponse> enrichSquadMarketValues(
            Connection conn,
            Long idLiga,
            List<LeagueSquadPlayerResponse> players
    ) throws SQLException {
        if (players == null || players.isEmpty()) {
            return players;
        }
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        List<Long> ids = new ArrayList<>();
        for (LeagueSquadPlayerResponse p : players) {
            if (p.idLigaJugador() != null) {
                ids.add(p.idLigaJugador());
            }
        }
        Map<Long, Double> pctBy = leaguePlayerMarketValueService.batchMaxActiveModifierPercents(conn, idLiga, ids);
        Map<Long, LeaguePlayerMarketValueService.PlayerProtectionState> protBy =
                leaguePlayerMarketValueService.batchProtectionStates(conn, ids);
        List<LeagueSquadPlayerResponse> out = new ArrayList<>();
        for (LeagueSquadPlayerResponse p : players) {
            Long idLj = p.idLigaJugador();
            double pc = idLj == null ? 0d : pctBy.getOrDefault(idLj, 0d);
            long eff = leaguePlayerMarketValueService.effectiveValueFromBase(p.valor(), pc);
            LeaguePlayerMarketValueService.PlayerProtectionState ps =
                    idLj == null
                            ? new LeaguePlayerMarketValueService.PlayerProtectionState(false, false, null, null, null)
                            : protBy.getOrDefault(
                                    idLj,
                                    new LeaguePlayerMarketValueService.PlayerProtectionState(false, false, null, null, null));
            out.add(
                    new LeagueSquadPlayerResponse(
                            p.idLigaJugador(),
                            p.idJugador(),
                            p.nombre(),
                            p.pila(),
                            p.posicion(),
                            p.valoracion(),
                            p.idEquipo(),
                            p.nombreEquipo(),
                            p.estado(),
                            p.cansancio(),
                            p.valor(),
                            p.fotoJugador(),
                            p.puntosTotales(),
                            p.tieneOfertaPendiente(),
                            p.probabilidadTitular(),
                            p.motivoTitularidad(),
                            p.idPartidoProbabilidad(),
                            p.calculadoEnProbabilidad(),
                            eff,
                            pc > 0d,
                            pc > 0d ? pc : null,
                            ps.protegido(),
                            ps.proteccionHastaFinTemporada(),
                            ps.proteccionJornadaFin()
                    )
            );
        }
        return out;
    }

    private List<LeagueSquadPlayerResponse> loadSquadForViewer(
            Connection conn,
            Long idLiga,
            Long idUsuarioDueno,
            Long idUsuarioConsultante,
            Long idJornadaContext
    ) throws SQLException {
        String sql = """
                SELECT
                    lj.id AS id_liga_jugador,
                    j.id AS id_jugador,
                    j.nombre,
                    j.pila,
                    j.posicion,
                    CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                    e.id AS id_equipo,
                    e.nombre AS nombre_equipo,
                    lj.estado,
                    lj.cansancio,
                    lj.valor,
                    j.foto AS foto_jugador,
                    CASE
                        WHEN lj.id_usuario_dueno = ?
                         AND EXISTS (
                             SELECT 1
                             FROM ofertas_jugador oj
                             WHERE oj.id_liga = lj.id_liga
                               AND oj.id_liga_jugador = lj.id
                               AND oj.estado = 'PENDIENTE'
                         ) THEN TRUE
                        ELSE FALSE
                    END AS tiene_oferta_pendiente
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = lj.id_equipo
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                ORDER BY
                    CASE j.posicion
                        WHEN 'POR' THEN 1
                        WHEN 'DEF' THEN 2
                        WHEN 'MED' THEN 3
                        WHEN 'DEL' THEN 4
                        ELSE 5
                    END,
                    lj.valor DESC,
                    j.nombre ASC
                """;

        List<LeagueSquadPlayerResponse> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuarioConsultante);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuarioDueno);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id_liga_jugador");
                    long idEq = rs.getLong("id_equipo");
                    String posicionRow = rs.getString("posicion");
                    int puntosTotales =
                            leagueDataService.sumFantasyPointsVisibleForPlayer(conn, idLiga, idLj, idEq, posicionRow);

                    players.add(new LeagueSquadPlayerResponse(
                            idLj,
                            rs.getLong("id_jugador"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            posicionRow,
                            rs.getInt("valoracion"),
                            idEq,
                            rs.getString("nombre_equipo"),
                            rs.getString("estado"),
                            rs.getInt("cansancio"),
                            rs.getLong("valor"),
                            LeagueAssetUrls.player(rs.getLong("id_jugador")),
                            puntosTotales,
                            rs.getBoolean("tiene_oferta_pendiente"),
                            null,
                            null,
                            null,
                            null,
                            rs.getLong("valor"),
                            false,
                            null,
                            false,
                            false,
                            null
                    ));
                }
            }
        }

        return enrichSquadWithStarterProbabilities(conn, idLiga, idJornadaContext, enrichSquadMarketValues(conn, idLiga, players));
    }

    private List<LeagueSquadPlayerResponse> enrichSquadWithStarterProbabilities(
            Connection conn,
            Long idLiga,
            Long idJornadaExplicit,
            List<LeagueSquadPlayerResponse> players
    ) throws SQLException {
        if (players.isEmpty()) {
            return players;
        }
        Map<Long, Long> ligaJugadorToEquipo = new HashMap<>();
        for (LeagueSquadPlayerResponse p : players) {
            if (p.idLigaJugador() != null && p.idEquipo() != null) {
                ligaJugadorToEquipo.put(p.idLigaJugador(), p.idEquipo());
            }
        }
        Map<Long, StarterProbabilityLite> prob = leagueStarterProbabilityService.loadDisplayProbabilityMapForPlayers(
                conn, idLiga, idJornadaExplicit, ligaJugadorToEquipo);

        List<LeagueSquadPlayerResponse> out = new ArrayList<>();
        for (LeagueSquadPlayerResponse p : players) {
            StarterProbabilityLite l = p.idLigaJugador() == null ? null : prob.get(p.idLigaJugador());
            out.add(
                    new LeagueSquadPlayerResponse(
                            p.idLigaJugador(),
                            p.idJugador(),
                            p.nombre(),
                            p.pila(),
                            p.posicion(),
                            p.valoracion(),
                            p.idEquipo(),
                            p.nombreEquipo(),
                            p.estado(),
                            p.cansancio(),
                            p.valor(),
                            p.fotoJugador(),
                            p.puntosTotales(),
                            p.tieneOfertaPendiente(),
                            l == null ? null : l.probabilidadTitular(),
                            l == null ? null : l.motivoTitularidad(),
                            l == null ? null : l.idPartidoProbabilidad(),
                            l == null ? null : l.calculadoEnProbabilidad(),
                            p.valorMercadoEfectivo(),
                            p.tieneModificadorValorMercado(),
                            p.porcentajeModificadorValorMercado(),
                            p.jugadorProtegido(),
                            p.proteccionHastaFinTemporada(),
                            p.proteccionJornadaFin()
                    )
            );
        }
        return out;
    }

    /**
     * Plantilla y última alineación guardada de otro participante (solo lectura).
     */
    public LeagueParticipantSquadResponse getParticipantSquad(
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuarioSolicitante,
            Long idJornadaContext
    )
            throws SQLException {
        if (idLiga == null || idLigaParticipante == null || idUsuarioSolicitante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (!isParticipant(conn, idLiga, idUsuarioSolicitante)) {
                throw new IllegalArgumentException("No perteneces a esta liga");
            }

            long targetUsuario;
            String nickname;
            String verify = """
                    SELECT lp.id_usuario, u.nickname
                    FROM liga_participantes lp
                    INNER JOIN usuarios u ON u.id = lp.id_usuario
                    WHERE lp.id = ?
                      AND lp.id_liga = ?
                    LIMIT 1
                    """;
            try (PreparedStatement ps = conn.prepareStatement(verify)) {
                ps.setLong(1, idLigaParticipante);
                ps.setLong(2, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Participante no encontrado en la liga");
                    }
                    targetUsuario = rs.getLong("id_usuario");
                    nickname = rs.getString("nickname");
                }
            }

            List<LeagueSquadPlayerResponse> plantilla =
                    loadSquadForViewer(conn, idLiga, targetUsuario, idUsuarioSolicitante, idJornadaContext);
            LeagueAssignedCoachResponse entrenadorAsignado = loadAssignedCoachByParticipant(conn, idLigaParticipante);
            boolean entrenadorActivo = entrenadorAsignado != null && Boolean.TRUE.equals(entrenadorAsignado.activo());
            String formacionEfectiva = entrenadorActivo ? entrenadorAsignado.formacion() : "4-3-3";

            LeagueLineupService.LatestSavedLineupForPeer lineup =
                    leagueLineupService.resolveLatestSavedLineupForPeer(idLiga, idLigaParticipante);

            Map<Long, LeagueSquadPlayerResponse> byId = new HashMap<>();
            for (LeagueSquadPlayerResponse p : plantilla) {
                if (p.idLigaJugador() != null) {
                    byId.put(p.idLigaJugador(), p);
                }
            }

            List<LeagueSquadPlayerResponse> titulares = mapLineupPlayersInOrder(lineup.titularesIds(), byId);
            List<LeagueSquadPlayerResponse> reservas = mapLineupPlayersInOrder(lineup.reservasIds(), byId);

            LeagueParticipantSquadResponse.ParticipantSavedLineupPayload alineacion =
                    new LeagueParticipantSquadResponse.ParticipantSavedLineupPayload(
                            lineup.disponible(),
                            lineup.idJornadaOrigen(),
                            lineup.numeroJornadaOrigen(),
                            formacionEfectiva,
                            lineup.idCapitan(),
                            titulares,
                            reservas,
                            lineup.emptySlots()
                    );

            return new LeagueParticipantSquadResponse(
                    idLiga,
                    idLigaParticipante,
                    targetUsuario,
                    nickname,
                    entrenadorAsignado,
                    entrenadorActivo,
                    formacionEfectiva,
                    alineacion,
                    plantilla
            );
        }
    }

    private Long loadLeagueParticipantId(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT id
                FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private LeagueAssignedCoachResponse loadAssignedCoachByParticipant(Connection conn, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lpe.id_entrenador,
                       lpe.activo,
                       e.nombre,
                       e.pila,
                       e.formacion,
                       e.foto,
                       e.id_equipo,
                       eq.nombre AS equipo_nombre,
                       e.bonus_puntos
                FROM liga_participante_entrenador lpe
                INNER JOIN entrenadores e ON e.id = lpe.id_entrenador
                LEFT JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpe.id_liga_participante = ?
                  AND lpe.activo = TRUE
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new LeagueAssignedCoachResponse(
                        rs.getLong("id_entrenador"),
                        rs.getString("nombre"),
                        rs.getString("pila"),
                        rs.getString("formacion"),
                        LeagueAssetUrls.manager(rs.getLong("id_entrenador")),
                        rs.getInt("id_equipo"),
                        rs.getString("equipo_nombre"),
                        rs.getInt("bonus_puntos"),
                        rs.getBoolean("activo"),
                        0
                );
            }
        }
    }

    private List<LeagueSquadPlayerResponse> mapLineupPlayersInOrder(
            List<Long> ids,
            Map<Long, LeagueSquadPlayerResponse> byId
    ) {
        List<LeagueSquadPlayerResponse> out = new ArrayList<>();
        if (ids == null) {
            return out;
        }
        for (Long id : ids) {
            LeagueSquadPlayerResponse p = byId.get(id);
            if (p != null) {
                out.add(p);
            }
        }
        return out;
    }

    /**
     * Contrato app móvil: {@code POST /leagues/{id}/admin/transfer} con {@code idAdminActual} e {@code idNuevoAdmin}.
     * La convención vigente en BD ({@code ligas.id_administrador}) debe coincidir con {@code idAdminActual}.
     */
    public void transferLeagueAdmin(Long idLiga, TransferLeagueAdminRequest request) throws SQLException {
        if (idLiga == null || request == null || request.idAdminActual() == null || request.idNuevoAdmin() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                LeagueData league = findLeagueByIdForUpdate(conn, idLiga);

                if (league == null) {
                    throw new IllegalArgumentException("Liga no encontrada");
                }

                if (league.closedAt() != null) {
                    throw new IllegalArgumentException("La liga está cerrada");
                }

                if (!Objects.equals(league.idAdministrador(), request.idAdminActual())) {
                    throw new IllegalArgumentException(
                            "El administrador actual no coincide con la liga. Refresca el detalle de la liga e inténtalo de nuevo."
                    );
                }

                if (Objects.equals(request.idAdminActual(), request.idNuevoAdmin())) {
                    throw new IllegalArgumentException("El nuevo administrador debe ser otro usuario");
                }

                if (!isParticipant(conn, idLiga, request.idNuevoAdmin())) {
                    throw new IllegalArgumentException("El nuevo administrador no pertenece a esta liga");
                }

                updateLeagueAdmin(conn, idLiga, request.idNuevoAdmin());

                conn.commit();

            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error transfiriendo administrador: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void leaveLeague(Long idLiga, LeaveLeagueRequest request) throws SQLException {
        if (idLiga == null || request == null || request.idUsuario() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                LeagueData league = findLeagueByIdForUpdate(conn, idLiga);

                if (league == null) {
                    throw new IllegalArgumentException("Liga no encontrada");
                }

                if (!isParticipant(conn, idLiga, request.idUsuario())) {
                    throw new IllegalArgumentException("No perteneces a esta liga");
                }

                boolean isAdmin = Objects.equals(league.idAdministrador(), request.idUsuario());
                int otherParticipants = countParticipantsExcludingUser(conn, idLiga, request.idUsuario());

                if (isAdmin) {
                    if (otherParticipants == 0) {
                        throw new IllegalArgumentException("Si eres el único usuario, no puedes salir. Debes cerrar la liga");
                    }

                    if (request.nuevoAdministradorId() == null) {
                        throw new IllegalArgumentException(
                                "Sigues siendo administrador: usa POST /api/v1/leagues/{idLiga}/admin/transfer "
                                        + "o envía nuevoAdministradorId en el cuerpo de /leave."
                        );
                    }

                    if (Objects.equals(request.nuevoAdministradorId(), request.idUsuario())) {
                        throw new IllegalArgumentException("Debes elegir a otro usuario como administrador");
                    }

                    if (!isParticipant(conn, idLiga, request.nuevoAdministradorId())) {
                        throw new IllegalArgumentException("El nuevo administrador no pertenece a la liga");
                    }

                    updateLeagueAdmin(conn, idLiga, request.nuevoAdministradorId());
                }

                dissolveParticipant(conn, idLiga, request.idUsuario());

                conn.commit();

            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error saliendo de la liga: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void closeLeague(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        log.info("closeLeague inicio idLiga={} idUsuario={}", idLiga, idUsuario);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                LeagueData league = findLeagueByIdForUpdate(conn, idLiga);

                if (league == null) {
                    throw new IllegalArgumentException("Liga no encontrada");
                }

                if (!Objects.equals(league.idAdministrador(), idUsuario)) {
                    throw new IllegalArgumentException("Solo el administrador puede cerrar la liga");
                }

                List<Long> participantes = loadLeagueParticipantUserIds(conn, idLiga);

                // XP y logros antes de disolver participantes (necesitan clasificación en liga_participantes).
                accountProgressService.onLeagueClosed(conn, idLiga);

                for (Long idParticipante : participantes) {
                    dissolveParticipant(conn, idLiga, idParticipante);
                }

                String sql = """
                        UPDATE ligas
                        SET cerrada_en = CURDATE(),
                            fin_en = CURDATE()
                        WHERE id = ?
                        """;

                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, idLiga);
                    ps.executeUpdate();
                }

                conn.commit();
                log.info("closeLeague ok idLiga={} participantesDisueltos={}", idLiga, participantes.size());

            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error cerrando la liga: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void kickParticipant(Long idLiga, KickParticipantRequest request) throws SQLException {
        if (idLiga == null || request == null || request.idAdminUsuario() == null || request.idUsuarioExpulsado() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        log.info(
                "kickParticipant inicio idLiga={} idAdminUsuario={} idUsuarioExpulsado={}",
                idLiga,
                request.idAdminUsuario(),
                request.idUsuarioExpulsado()
        );

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                LeagueData league = findLeagueByIdForUpdate(conn, idLiga);

                if (league == null) {
                    log.warn("kickParticipant rechazado: liga no encontrada idLiga={}", idLiga);
                    throw new IllegalArgumentException("Liga no encontrada");
                }

                log.info(
                        "kickParticipant idLiga={} administradorRealLiga={} idAdminSolicitante={}",
                        idLiga,
                        league.idAdministrador(),
                        request.idAdminUsuario()
                );

                if (!Objects.equals(league.idAdministrador(), request.idAdminUsuario())) {
                    log.warn(
                            "kickParticipant rechazado: admin no coincide idLiga={} adminReal={} idAdminSolicitante={}",
                            idLiga,
                            league.idAdministrador(),
                            request.idAdminUsuario()
                    );
                    throw new IllegalArgumentException("Solo el administrador puede expulsar participantes");
                }

                if (Objects.equals(request.idAdminUsuario(), request.idUsuarioExpulsado())) {
                    log.warn("kickParticipant rechazado: autoexpulsión idLiga={} idUsuario={}", idLiga, request.idUsuarioExpulsado());
                    throw new IllegalArgumentException("El administrador no se puede expulsar a sí mismo");
                }

                boolean participanteExpulsadoEncontrado = isParticipant(conn, idLiga, request.idUsuarioExpulsado());
                log.info(
                        "kickParticipant idLiga={} idAdminUsuario={} adminRealLiga={} idUsuarioExpulsado={} participanteExpulsadoEncontrado={}",
                        idLiga,
                        request.idAdminUsuario(),
                        league.idAdministrador(),
                        request.idUsuarioExpulsado(),
                        participanteExpulsadoEncontrado
                );

                if (!participanteExpulsadoEncontrado) {
                    throw new IllegalArgumentException("El usuario a expulsar no pertenece a la liga");
                }

                Long idLpExpulsado = loadLeagueParticipantId(conn, idLiga, request.idUsuarioExpulsado());
                DissolveParticipantResult dissolved = dissolveParticipant(conn, idLiga, request.idUsuarioExpulsado());
                KickCleanupCounts cleanup = dissolved.cleanup();
                int jugadoresLiberados = dissolved.jugadoresLiberados();
                if (idLpExpulsado == null && dissolved.idLigaParticipante() == null) {
                    log.warn(
                            "kickParticipant: participante en liga pero sin id_liga_participante idLiga={} idUsuario={}",
                            idLiga,
                            request.idUsuarioExpulsado()
                    );
                }

                String nickExpulsado = loadNicknameById(conn, request.idUsuarioExpulsado());
                String nickAdmin = loadNicknameById(conn, request.idAdminUsuario());
                leagueActivityService.recordActivity(
                        conn,
                        idLiga,
                        request.idAdminUsuario(),
                        nickAdmin,
                        "ADMIN_KICK",
                        nickAdmin + " expulsó a " + nickExpulsado + " de la liga.",
                        null, idLpExpulsado,
                        null, null, null, null, null
                );

                conn.commit();
                log.info(
                        "kickParticipant ok idLiga={} idAdminUsuario={} adminRealLiga={} idUsuarioExpulsado={} "
                                + "participanteExpulsadoEncontrado=true idLigaParticipante={} ofertasCanceladas={} "
                                + "pujasCanceladas={} jugadoresLiberados={} recompensaEventosSnapshot={} "
                                + "rewardInventoryRemoved={}",
                        idLiga,
                        request.idAdminUsuario(),
                        league.idAdministrador(),
                        request.idUsuarioExpulsado(),
                        idLpExpulsado,
                        cleanup.ofertasCanceladas(),
                        cleanup.pujasCanceladas(),
                        jugadoresLiberados,
                        cleanup.recompensaEventosSnapshot(),
                        cleanup.rewardInventoryRemoved()
                );

            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    log.warn(
                            "kickParticipant rechazado idLiga={} idAdminUsuario={} idUsuarioExpulsado={} motivo={}",
                            idLiga,
                            request.idAdminUsuario(),
                            request.idUsuarioExpulsado(),
                            illegalArgumentException.getMessage()
                    );
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    log.error(
                            "kickParticipant error SQL idLiga={} idAdminUsuario={} idUsuarioExpulsado={} motivo={}",
                            idLiga,
                            request.idAdminUsuario(),
                            request.idUsuarioExpulsado(),
                            sqlException.getMessage(),
                            sqlException
                    );
                    throw sqlException;
                }

                log.error(
                        "kickParticipant error idLiga={} idAdminUsuario={} idUsuarioExpulsado={} motivo={}",
                        idLiga,
                        request.idAdminUsuario(),
                        request.idUsuarioExpulsado(),
                        e.getMessage(),
                        e
                );
                throw new SQLException("Error expulsando participante: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void validateCreateLeagueRequest(CreateLeagueRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("No se ha enviado el cuerpo de la petición");
        }

        InputValidator.validateLeagueName(request.nombre());

        if (request.idTemporada() == null) {
            throw new IllegalArgumentException("La temporada es obligatoria");
        }

        if (request.idUsuario() == null) {
            throw new IllegalArgumentException("El usuario es obligatorio");
        }

        LeagueCreationConfig.resolve(request);
    }

    private void validateJoinLeagueRequest(JoinLeagueRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("No se ha enviado el cuerpo de la petición");
        }

        InputValidator.validateInvitationCode(request.codigoInvitacion());

        if (request.idUsuario() == null) {
            throw new IllegalArgumentException("El usuario es obligatorio");
        }
    }

    private void validateSeasonAccess(Connection conn, Long idUsuario, Long idTemporada) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM usuario_temporadas
                WHERE id_usuario = ?
                  AND id_temporada = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idTemporada);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getInt("total") <= 0) {
                    throw new IllegalArgumentException("El usuario no tiene acceso a esta temporada");
                }
            }
        }
    }

    private Long insertLeague(
            Connection conn,
            String nombre,
            Long idTemporada,
            Long idAdministrador,
            String codigoInvitacion,
            LeagueCreationConfig config
    ) throws SQLException {
        String sql = """
                INSERT INTO ligas (
                    nombre, id_temporada, id_administrador, creada_en, codigo_invitacion,
                    semana_previa_fichajes, permite_entresemana, ida_y_vuelta, max_participantes,
                    recompensa_base_jornada, recompensa_bonus_ganador, dinero_por_punto_fantasy
                )
                VALUES (?, ?, ?, CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            ps.setLong(2, idTemporada);
            ps.setLong(3, idAdministrador);
            ps.setString(4, codigoInvitacion);
            ps.setBoolean(5, config.semanaPreviaFichajes());
            ps.setBoolean(6, config.permiteEntresemana());
            ps.setBoolean(7, config.idaYVuelta());
            ps.setInt(8, config.maxParticipantes());
            ps.setInt(9, config.recompensaBaseJornada());
            ps.setInt(10, config.recompensaBonusGanador());
            ps.setLong(11, config.dineroPorPuntoFantasy());

            int rows = ps.executeUpdate();

            if (rows <= 0) {
                throw new SQLException("No se pudo crear la liga");
            }

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException("No se pudo obtener el id de la liga creada");
                }
                return rs.getLong(1);
            }
        }
    }

    private void copySeasonPlayersToLeague(Connection conn, Long idLiga, Long idTemporada) throws SQLException {
        String sqlSelect = """
                SELECT j.id, j.id_equipo, j.valoracion, j.posicion
                FROM jugadores j
                INNER JOIN equipos e ON e.id = j.id_equipo
                WHERE e.id_temporada = ?
                """;

        String sqlInsert = """
                INSERT INTO liga_jugadores
                (id_liga, id_jugador, id_equipo, id_usuario_dueno, adquirido_en, estado, cansancio, valor, valor_anterior, valoracion_inicial, valoracion_actual)
                VALUES (?, ?, ?, ?, NULL, 'DISPONIBLE', 0, ?, ?, ?, ?)
                """;

        try (PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psInsert = conn.prepareStatement(sqlInsert)) {

            psSelect.setLong(1, idTemporada);

            try (ResultSet rs = psSelect.executeQuery()) {
                while (rs.next()) {
                    long idJugador = rs.getLong("id");
                    long idEquipo = rs.getLong("id_equipo");
                    int valoracion = rs.getInt("valoracion");
                    String posicion = rs.getString("posicion");

                    long valor = pricingService.calculateInitialValue(valoracion, posicion);

                    psInsert.setLong(1, idLiga);
                    psInsert.setLong(2, idJugador);
                    psInsert.setLong(3, idEquipo);
                    psInsert.setLong(4, MARKET_USER_ID);
                    psInsert.setLong(5, valor);
                    psInsert.setLong(6, valor);
                    psInsert.setDouble(7, valoracion);
                    psInsert.setDouble(8, valoracion);
                    psInsert.addBatch();
                }
            }

            psInsert.executeBatch();
        }
    }

    private CalendarGenerationResult generateLeagueCalendar(
            Connection conn,
            Long idLiga,
            Long idTemporada,
            LeagueCreationConfig config
    ) throws SQLException {
        copySeasonTeamsToLeague(conn, idLiga, idTemporada);

        List<LeagueTeamData> leagueTeams = loadLeagueTeams(conn, idLiga);

        if (leagueTeams.size() < 2) {
            throw new IllegalArgumentException("La temporada debe tener al menos 2 equipos para generar calendario");
        }

        List<List<MatchPair>> firstLegRounds = buildFirstLegRounds(leagueTeams);
        List<List<MatchPair>> fullRounds = buildFullSchedule(firstLegRounds, config.idaYVuelta());

        if (fullRounds.isEmpty()) {
            throw new IllegalArgumentException("No se ha podido generar el calendario de la liga");
        }

        LeagueCalendarPlanner.PlannedCalendar planned = LeagueCalendarPlanner.plan(
                LocalDate.now(),
                fullRounds.size(),
                config.permiteEntresemana(),
                config.semanaPreviaFichajes()
        );

        LocalDateTime primerPartidoEn = insertRoundsAndMatches(
                conn,
                idLiga,
                fullRounds,
                planned.rounds()
        );

        updateLeaguePlannedEndDate(conn, idLiga, planned.finLigaEn());

        return new CalendarGenerationResult(fullRounds.size(), primerPartidoEn, planned.finLigaEn());
    }

    private void copySeasonTeamsToLeague(Connection conn, Long idLiga, Long idTemporada) throws SQLException {
        String sql = """
                INSERT INTO liga_equipos (id_liga, id_equipo)
                SELECT ?, e.id
                FROM equipos e
                WHERE e.id_temporada = ?
                ORDER BY e.id ASC
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idTemporada);
            ps.executeUpdate();
        }
    }

    private List<LeagueTeamData> loadLeagueTeams(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id, id_equipo
                FROM liga_equipos
                WHERE id_liga = ?
                ORDER BY id_equipo ASC, id ASC
                """;

        List<LeagueTeamData> teams = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    teams.add(new LeagueTeamData(
                            rs.getLong("id"),
                            rs.getLong("id_equipo")
                    ));
                }
            }
        }

        return teams;
    }

    private List<List<MatchPair>> buildFirstLegRounds(List<LeagueTeamData> sourceTeams) {
        List<LeagueTeamData> rotation = new ArrayList<>(sourceTeams);

        if (rotation.size() % 2 != 0) {
            rotation.add(null);
        }

        int totalTeams = rotation.size();
        int totalRounds = totalTeams - 1;
        int matchesPerRound = totalTeams / 2;

        List<List<MatchPair>> rounds = new ArrayList<>();

        for (int roundIndex = 0; roundIndex < totalRounds; roundIndex++) {
            List<MatchPair> roundMatches = new ArrayList<>();

            for (int i = 0; i < matchesPerRound; i++) {
                LeagueTeamData teamA = rotation.get(i);
                LeagueTeamData teamB = rotation.get(totalTeams - 1 - i);

                if (teamA == null || teamB == null) {
                    continue;
                }

                boolean swapHomeAway = (i == 0)
                        ? (roundIndex % 2 == 1)
                        : (roundIndex % 2 == 0);

                LeagueTeamData home = swapHomeAway ? teamB : teamA;
                LeagueTeamData away = swapHomeAway ? teamA : teamB;

                roundMatches.add(new MatchPair(home, away));
            }

            rounds.add(roundMatches);

            LeagueTeamData last = rotation.remove(totalTeams - 1);
            rotation.add(1, last);
        }

        return rounds;
    }

    private List<List<MatchPair>> buildFullSchedule(List<List<MatchPair>> firstLegRounds, boolean idaYVuelta) {
        List<List<MatchPair>> allRounds = new ArrayList<>();

        for (List<MatchPair> firstLegRound : firstLegRounds) {
            allRounds.add(new ArrayList<>(firstLegRound));
        }

        if (!idaYVuelta) {
            return allRounds;
        }

        for (List<MatchPair> firstLegRound : firstLegRounds) {
            List<MatchPair> secondLegRound = new ArrayList<>();

            for (MatchPair match : firstLegRound) {
                secondLegRound.add(new MatchPair(
                        match.awayTeam(),
                        match.homeTeam()
                ));
            }

            allRounds.add(secondLegRound);
        }

        return allRounds;
    }

    private LocalDateTime insertRoundsAndMatches(
            Connection conn,
            Long idLiga,
            List<List<MatchPair>> rounds,
            List<LeagueCalendarPlanner.RoundBlock> schedule
    ) throws SQLException {
        LocalDateTime primerPartidoEn = null;

        for (int roundIndex = 0; roundIndex < rounds.size(); roundIndex++) {
            int roundNumber = roundIndex + 1;
            LeagueCalendarPlanner.RoundBlock block = schedule.get(roundIndex);

            Long jornadaId = insertRound(conn, idLiga, roundNumber, block.anchor(), block.midweek());
            LocalDateTime roundFirstKickoff = insertMatchesForRound(
                    conn,
                    jornadaId,
                    rounds.get(roundIndex),
                    block.anchor(),
                    block.midweek()
            );
            if (primerPartidoEn == null) {
                primerPartidoEn = roundFirstKickoff;
            }
        }

        if (primerPartidoEn == null) {
            throw new IllegalStateException("No se programó ningún partido en el calendario");
        }
        return primerPartidoEn;
    }

    private Long insertRound(
            Connection conn,
            Long idLiga,
            int roundNumber,
            LocalDate roundAnchor,
            boolean midweek
    ) throws SQLException {
    String sql = """
            INSERT INTO jornadas (id_liga, numero, inicio, inicio_en, fin, estado)
            VALUES (?, ?, ?, ?, ?, 'PENDIENTE')
            """;

    List<LocalDateTime> baseSlots = LeagueCalendarPlanner.buildBaseSlots(roundAnchor, midweek);
    LocalDateTime firstKickoff = baseSlots.get(0);
    LocalDate roundEnd = LeagueCalendarPlanner.roundEndDate(roundAnchor, midweek);

    try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
        ps.setLong(1, idLiga);
        ps.setInt(2, roundNumber);
        ps.setDate(3, Date.valueOf(roundAnchor));
        ps.setTimestamp(4, Timestamp.valueOf(firstKickoff));
        ps.setDate(5, Date.valueOf(roundEnd));

        int rows = ps.executeUpdate();

        if (rows <= 0) {
            throw new SQLException("No se pudo crear la jornada " + roundNumber);
        }

        try (ResultSet rs = ps.getGeneratedKeys()) {
            if (!rs.next()) {
                throw new SQLException("No se pudo obtener el id de la jornada creada");
            }
            return rs.getLong(1);
        }
    }
}

    private LocalDateTime insertMatchesForRound(
            Connection conn,
            Long jornadaId,
            List<MatchPair> matches,
            LocalDate roundAnchor,
            boolean midweek
    ) throws SQLException {
        String sql = """
                INSERT INTO partidos_jornada (
                    id_jornada,
                    id_liga_equipo_local,
                    id_liga_equipo_visitante,
                    goles_local,
                    goles_visitante,
                    id_liga_equipo_ganador,
                    empate,
                    estado,
                    inicio_en
                )
                VALUES (?, ?, ?, 0, 0, NULL, 0, 'PENDIENTE', ?)
                """;

        List<LocalDateTime> kickoffs = LeagueCalendarPlanner.buildKickoffSlots(
                roundAnchor,
                midweek,
                matches.size()
        );

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < matches.size(); i++) {
                MatchPair match = matches.get(i);
                LocalDateTime kickoff = kickoffs.get(i);

                ps.setLong(1, jornadaId);
                // id_liga_equipo_* en BD referencian equipos.id (id de club), no liga_equipos.id.
                ps.setLong(2, match.homeTeam().teamId());
                ps.setLong(3, match.awayTeam().teamId());
                ps.setTimestamp(4, Timestamp.valueOf(kickoff));
                ps.addBatch();
            }

            ps.executeBatch();
        }

        return kickoffs.get(0);
    }

    private void updateLeaguePlannedEndDate(Connection conn, Long idLiga, LocalDate plannedEndDate) throws SQLException {
        String sql = """
                UPDATE ligas
                SET fin_en = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(plannedEndDate));
            ps.setLong(2, idLiga);
            ps.executeUpdate();
        }
    }

    private long insertParticipant(Connection conn, Long idLiga, Long idUsuario, long dinero) throws SQLException {
        String sql = """
                INSERT INTO liga_participantes (id_liga, id_usuario, puntos_totales, dinero, puntos_recompensa)
                VALUES (?, ?, 0, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setLong(3, dinero);
            ps.setLong(4, INITIAL_LEAGUE_REWARD_POINTS);
            int rows = ps.executeUpdate();
            if (rows <= 0) {
                throw new SQLException("No se pudo crear el participante de liga");
            }
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException("No se pudo obtener el id del participante de liga");
                }
                return rs.getLong(1);
            }
        }
    }

    private void updateParticipantMoney(Connection conn, Long idLiga, Long idUsuario, long dinero) throws SQLException {
        String sql = """
                UPDATE liga_participantes
                SET dinero = ?
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, dinero);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuario);
            ps.executeUpdate();
        }
    }

    private boolean isParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total") > 0;
            }
        }
    }

    private int countParticipants(Connection conn, Long idLiga) throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM liga_participantes WHERE id_liga = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total");
            }
        }
    }

    private int countParticipantsExcludingUser(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario <> ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total");
            }
        }
    }

    private LeagueData findLeagueByInvitationCodeForUpdate(Connection conn, String code) throws SQLException {
        String sql = """
                SELECT id, nombre, id_temporada, id_administrador, codigo_invitacion, cerrada_en,
                       max_participantes
                FROM ligas
                WHERE codigo_invitacion = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new LeagueData(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getLong("id_temporada"),
                        rs.getLong("id_administrador"),
                        rs.getString("codigo_invitacion"),
                        rs.getDate("cerrada_en"),
                        rs.getInt("max_participantes")
                );
            }
        }
    }

    private LeagueData findLeagueById(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id, nombre, id_temporada, id_administrador, codigo_invitacion, cerrada_en,
                       max_participantes
                FROM ligas
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new LeagueData(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getLong("id_temporada"),
                        rs.getLong("id_administrador"),
                        rs.getString("codigo_invitacion"),
                        rs.getDate("cerrada_en"),
                        rs.getInt("max_participantes")
                );
            }
        }
    }

    private LeagueData findLeagueByIdForUpdate(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id, nombre, id_temporada, id_administrador, codigo_invitacion, cerrada_en,
                       max_participantes
                FROM ligas
                WHERE id = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new LeagueData(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getLong("id_temporada"),
                        rs.getLong("id_administrador"),
                        rs.getString("codigo_invitacion"),
                        rs.getDate("cerrada_en"),
                        rs.getInt("max_participantes")
                );
            }
        }
    }

    private void updateLeagueAdmin(Connection conn, Long idLiga, Long nuevoAdministradorId) throws SQLException {
        String sql = """
                UPDATE ligas
                SET id_administrador = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, nuevoAdministradorId);
            ps.setLong(2, idLiga);
            ps.executeUpdate();
        }
    }

    /**
     * Libera plantilla, entrenador y dependencias del participante; devuelve jugadores al mercado de la liga.
     */
    private DissolveParticipantResult dissolveParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        Long idLigaParticipante = loadLeagueParticipantId(conn, idLiga, idUsuario);
        KickCleanupCounts cleanup = KickCleanupCounts.empty();
        if (idLigaParticipante != null) {
            cleanup = removeParticipantDependencies(conn, idLiga, idUsuario, idLigaParticipante);
            detachParticipantForeignKeys(conn, idLiga, idLigaParticipante);
        }
        int jugadoresLiberados = returnPlayersToMarket(conn, idLiga, idUsuario);
        deleteParticipant(conn, idLiga, idUsuario);
        return new DissolveParticipantResult(idLigaParticipante, cleanup, jugadoresLiberados);
    }

    private record DissolveParticipantResult(
            Long idLigaParticipante,
            KickCleanupCounts cleanup,
            int jugadoresLiberados
    ) {
    }

    private List<Long> loadLeagueParticipantUserIds(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id_usuario
                FROM liga_participantes
                WHERE id_liga = ?
                ORDER BY id ASC
                """;

        List<Long> userIds = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    userIds.add(rs.getLong("id_usuario"));
                }
            }
        }

        return userIds;
    }

    /**
     * Evita violaciones de FK al borrar {@code liga_participantes} si en producción aún no hay ON DELETE SET NULL.
     */
    private void detachParticipantForeignKeys(Connection conn, Long idLiga, Long idLigaParticipante) throws SQLException {
        String[] updates = {
                """
                UPDATE liga_recompensa_eventos
                SET id_liga_participante = NULL
                WHERE id_liga = ? AND id_liga_participante = ?
                """,
                """
                UPDATE liga_recompensa_eventos
                SET id_liga_participante_objetivo = NULL
                WHERE id_liga = ? AND id_liga_participante_objetivo = ?
                """,
                """
                UPDATE liga_actividad
                SET id_liga_participante_actor = NULL
                WHERE id_liga = ? AND id_liga_participante_actor = ?
                """,
                """
                UPDATE liga_actividad
                SET id_liga_participante_objetivo = NULL
                WHERE id_liga = ? AND id_liga_participante_objetivo = ?
                """
        };

        for (String sql : updates) {
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idLigaParticipante);
                ps.executeUpdate();
            }
        }

        try (PreparedStatement ps = conn.prepareStatement("""
                UPDATE liga_recompensa_eventos e
                INNER JOIN liga_participante_cartas c ON c.id = e.id_carta
                SET e.id_carta = NULL
                WHERE e.id_liga = ? AND c.id_liga_participante = ?
                """)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }

        try (PreparedStatement ps = conn.prepareStatement("""
                UPDATE liga_actividad a
                INNER JOIN liga_participante_cartas c ON c.id = a.id_carta
                SET a.id_carta = NULL
                WHERE a.id_liga = ? AND c.id_liga_participante = ?
                """)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private int returnPlayersToMarket(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?,
                    adquirido_en = NULL
                WHERE id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, MARKET_USER_ID);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuario);
            return ps.executeUpdate();
        }
    }

    /**
     * Quita filas que referencian {@code liga_participantes.id} para permitir el DELETE del participante.
     */
    private KickCleanupCounts removeParticipantDependencies(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            Long idLigaParticipante
    ) throws SQLException {
        int ofertasCanceladas = refundPendingOffersWhereUserIsBuyer(conn, idLiga, idUsuario);

        List<Long> ownedPlayers = loadOwnedLeaguePlayerIds(conn, idLiga, idUsuario);
        int pujasCanceladas = nightMarketService.cancelUnresolvedMarketsForLeaguePlayers(conn, idLiga, ownedPlayers);
        for (Long idLigaJugador : ownedPlayers) {
            ofertasCanceladas += refundPendingOffersOnLeaguePlayer(conn, idLiga, idLigaJugador);
        }

        pujasCanceladas += removeAllNightMarketBidsForDepartingUser(conn, idLiga, idUsuario);

        deleteFromAlineacionJornadaHuecosForParticipant(conn, idLigaParticipante);

        String delAjp = """
                DELETE FROM alineacion_jornada_participante
                WHERE id_liga_participante = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(delAjp)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }

        String delAjpc = """
                DELETE FROM alineacion_jornada_participante_config
                WHERE id_liga_participante = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(delAjpc)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }

        String delCoach = """
                DELETE FROM liga_participante_entrenador
                WHERE id_liga_participante = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(delCoach)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }

        int recompensaEventosSnapshot = snapshotRewardEventsForDepartingParticipant(
                conn, idLiga, idLigaParticipante, idUsuario
        );
        int rewardInventoryRemoved = removeParticipantRewardInventory(conn, idLigaParticipante);

        return new KickCleanupCounts(
                ofertasCanceladas,
                pujasCanceladas,
                recompensaEventosSnapshot,
                rewardInventoryRemoved
        );
    }

    /**
     * Rellena snapshots de auditoría en eventos de recompensa antes de borrar el participante.
     */
    private int snapshotRewardEventsForDepartingParticipant(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuario
    ) throws SQLException {
        String nickname = loadNicknameById(conn, idUsuario);
        String sql = """
                UPDATE liga_recompensa_eventos
                SET id_usuario = COALESCE(id_usuario, ?),
                    id_usuario_snapshot = COALESCE(id_usuario_snapshot, ?),
                    nickname_snapshot = COALESCE(nickname_snapshot, ?)
                WHERE id_liga = ?
                  AND (id_liga_participante = ? OR id_liga_participante_objetivo = ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idUsuario);
            ps.setString(3, nickname);
            ps.setLong(4, idLiga);
            ps.setLong(5, idLigaParticipante);
            ps.setLong(6, idLigaParticipante);
            return ps.executeUpdate();
        }
    }

    /**
     * Elimina inventario/modificadores de recompensas ligados al participante (no el historial de eventos).
     */
    private int removeParticipantRewardInventory(Connection conn, Long idLigaParticipante) throws SQLException {
        int removed = 0;

        String[] deletes = {
                "DELETE FROM liga_jugador_protecciones WHERE id_liga_participante = ?",
                "DELETE FROM liga_jugador_modificadores_valor WHERE id_liga_participante = ?",
                "DELETE FROM liga_participante_puntos_bonus WHERE id_liga_participante = ?",
                "DELETE FROM liga_participante_ruleta_entrenador WHERE id_liga_participante = ?",
                "DELETE FROM liga_movimientos_economicos WHERE id_liga_participante = ?",
                "DELETE FROM liga_participante_cartas WHERE id_liga_participante = ?"
        };

        for (String sql : deletes) {
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLigaParticipante);
                removed += ps.executeUpdate();
            }
        }

        return removed;
    }

    private record KickCleanupCounts(
            int ofertasCanceladas,
            int pujasCanceladas,
            int recompensaEventosSnapshot,
            int rewardInventoryRemoved
    ) {
        static KickCleanupCounts empty() {
            return new KickCleanupCounts(0, 0, 0, 0);
        }
    }

    private List<Long> loadOwnedLeaguePlayerIds(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT id
                FROM liga_jugadores
                WHERE id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        List<Long> ids = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id"));
                }
            }
        }

        return ids;
    }

    private int refundPendingOffersWhereUserIsBuyer(Connection conn, Long idLiga, Long idUsuarioComprador)
            throws SQLException {
        String selectSql = """
                SELECT id, cantidad
                FROM ofertas_jugador
                WHERE id_liga = ?
                  AND id_usuario_comprador = ?
                  AND estado = 'PENDIENTE'
                FOR UPDATE
                """;

        List<long[]> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuarioComprador);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new long[] { rs.getLong("id"), rs.getLong("cantidad") });
                }
            }
        }

        for (long[] row : rows) {
            long idOferta = row[0];
            long cantidad = row[1];
            addMoneyToParticipantDelta(conn, idLiga, idUsuarioComprador, cantidad);
            finalizeOfferCancelled(conn, idOferta);
        }
        return rows.size();
    }

    private int refundPendingOffersOnLeaguePlayer(Connection conn, Long idLiga, Long idLigaJugador) throws SQLException {
        String selectSql = """
                SELECT id, id_usuario_comprador, cantidad
                FROM ofertas_jugador
                WHERE id_liga = ?
                  AND id_liga_jugador = ?
                  AND estado = 'PENDIENTE'
                FOR UPDATE
                """;

        List<long[]> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new long[] {
                        rs.getLong("id"),
                        rs.getLong("id_usuario_comprador"),
                        rs.getLong("cantidad")
                    });
                }
            }
        }

        for (long[] row : rows) {
            long idOferta = row[0];
            long comprador = row[1];
            long cantidad = row[2];
            addMoneyToParticipantDelta(conn, idLiga, comprador, cantidad);
            finalizeOfferCancelled(conn, idOferta);
        }
        return rows.size();
    }

    /**
     * Mercado nocturno: las pujas activas bloquean saldo (descontado en {@link NightMarketService#upsertBid}).
     * Si el usuario sale, hay que borrar sus pujas; las de mercados <strong>no resueltos</strong> devuelven ese saldo.
     * Las de mercados <strong>ya resueltos</strong> solo se borran (el cobro/reembolso ya se aplicó al resolver;
     * si no las borráramos, seguirían enlazadas al usuario de forma inconsistente).
     */
    private int removeAllNightMarketBidsForDepartingUser(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String selectSql = """
                SELECT p.id, p.cantidad, md.resuelto
                FROM pujas p
                INNER JOIN mercado_diario md ON md.id = p.id_mercado_diario
                WHERE md.id_liga = ?
                  AND p.id_usuario = ?
                FOR UPDATE
                """;

        String delPuja = "DELETE FROM pujas WHERE id = ?";
        int pujasEliminadas = 0;

        try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idPuja = rs.getLong("id");
                    long cantidad = rs.getLong("cantidad");
                    boolean mercadoResuelto = rs.getBoolean("resuelto");

                    if (!mercadoResuelto) {
                        addMoneyToParticipantDelta(conn, idLiga, idUsuario, cantidad);
                    }

                    try (PreparedStatement del = conn.prepareStatement(delPuja)) {
                        del.setLong(1, idPuja);
                        del.executeUpdate();
                    }
                    pujasEliminadas++;
                }
            }
        }
        return pujasEliminadas;
    }

    private void deleteFromAlineacionJornadaHuecosForParticipant(Connection conn, Long idLigaParticipante)
            throws SQLException {
        String sql = """
                DELETE h FROM alineacion_jornada_huecos h
                INNER JOIN alineacion_jornada_participante_config c
                  ON c.id = h.id_alineacion_jornada_participante_config
                WHERE c.id_liga_participante = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private void addMoneyToParticipantDelta(Connection conn, Long idLiga, Long idUsuario, long delta)
            throws SQLException {
        if (delta == 0) {
            return;
        }

        String sql = """
                UPDATE liga_participantes
                SET dinero = dinero + ?
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, delta);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuario);
            ps.executeUpdate();
        }
    }

    private void finalizeOfferCancelled(Connection conn, long idOferta) throws SQLException {
        String sql = """
                UPDATE ofertas_jugador
                SET estado = 'CANCELADA',
                    actualizada_en = NOW(),
                    respondida_en = NOW()
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idOferta);
            ps.executeUpdate();
        }
    }

    private void deleteParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                DELETE FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.executeUpdate();
        }
    }

    private String generateUniqueInvitationCode(Connection conn) throws SQLException {
        final String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        Random random = new Random();
        String code;

        do {
            StringBuilder sb = new StringBuilder();

            for (int i = 0; i < 8; i++) {
                sb.append(chars.charAt(random.nextInt(chars.length())));
            }

            code = sb.toString();
        } while (invitationCodeExists(conn, code));

        return code;
    }

    private boolean invitationCodeExists(Connection conn, String code) throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM ligas WHERE codigo_invitacion = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total") > 0;
            }
        }
    }

    private long calculateInitialMoney(long squadValue) {
        long money = INITIAL_TOTAL_BUDGET - squadValue;
        return Math.max(0L, money);
    }

    private String buildJoinSquadMessage(InitialSquadAssignment assignment) {
        if (assignment.assignedCount() <= 0) {
            return "Has entrado en la liga. No había jugadores libres en el mercado; podrás fichar en el mercado diario.";
        }
        if (assignment.incomplete()) {
            return "Has entrado en la liga. Tu plantilla inicial está incompleta; podrás completarla en el mercado.";
        }
        return "Has entrado en la liga.";
    }

    /**
     * Asigna plantilla inicial competitiva cuando hay pool suficiente; no bloquea la entrada.
     */
    private InitialSquadAssignment assignInitialSquadBestEffort(Connection conn, Long idLiga, Long idUsuario)
            throws SQLException {
        List<CandidateLeaguePlayer> freePlayers = lockEligibleMarketPlayers(conn, idLiga);

        int por = 0;
        int def = 0;
        int med = 0;
        int del = 0;
        for (CandidateLeaguePlayer player : freePlayers) {
            switch (player.position()) {
                case "POR" -> por++;
                case "DEF" -> def++;
                case "MED" -> med++;
                case "DEL" -> del++;
                default -> { }
            }
        }

        List<InitialSquadSelector.SquadCandidate> candidates = freePlayers.stream()
                .map(p -> new InitialSquadSelector.SquadCandidate(
                        p.leaguePlayerId(),
                        p.teamId(),
                        p.position(),
                        p.rating(),
                        p.value()
                ))
                .toList();

        InitialSquadSelector.SelectionResult selection = InitialSquadSelector.select(candidates);

        if (!selection.leaguePlayerIds().isEmpty()) {
            assignPlayersToUser(conn, idUsuario, selection.leaguePlayerIds());
        }

        log.info(
                "Plantilla inicial idLiga={} idUsuario={} disponibles={} (POR={} DEF={} MED={} DEL={}) "
                        + "asignados={} valor={} incompleta={} estrategia={}",
                idLiga,
                idUsuario,
                freePlayers.size(),
                por,
                def,
                med,
                del,
                selection.assignedCount(),
                selection.totalValue(),
                selection.incomplete(),
                selection.strategy()
        );

        return new InitialSquadAssignment(
                selection.assignedCount(),
                selection.totalValue(),
                selection.incomplete(),
                selection.strategy()
        );
    }

    private List<CandidateLeaguePlayer> lockEligibleMarketPlayers(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT lj.id AS id_liga_jugador,
                       lj.id_jugador,
                       lj.id_equipo,
                       lj.valor,
                       j.posicion,
                       CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                       j.nombre
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                  AND COALESCE(lj.valoracion_actual, j.valoracion) < ?
                  AND NOT EXISTS (
                      SELECT 1
                      FROM mercado_diario md
                      WHERE md.id_liga = lj.id_liga
                        AND md.id_liga_jugador = lj.id
                        AND md.resuelto = 0
                  )
                FOR UPDATE
                """;

        List<CandidateLeaguePlayer> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, MARKET_USER_ID);
            ps.setInt(3, STAR_RATING_LIMIT);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    players.add(new CandidateLeaguePlayer(
                            rs.getLong("id_liga_jugador"),
                            rs.getLong("id_jugador"),
                            rs.getLong("id_equipo"),
                            rs.getString("nombre"),
                            rs.getString("posicion"),
                            rs.getInt("valoracion"),
                            rs.getLong("valor")
                    ));
                }
            }
        }

        return players;
    }

    private void assignPlayersToUser(Connection conn, Long idUsuario, List<Long> leaguePlayerIds) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?,
                    adquirido_en = NOW()
                WHERE id = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (Long leaguePlayerId : leaguePlayerIds) {
                ps.setLong(1, idUsuario);
                ps.setLong(2, leaguePlayerId);
                ps.setLong(3, MARKET_USER_ID);
                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    private String loadNicknameById(Connection conn, Long idUsuario) throws SQLException {
        String sql = "SELECT nickname FROM usuarios WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("nickname") : ("Usuario " + idUsuario);
            }
        }
    }

    private record LeagueData(
            Long id,
            String nombre,
            Long idTemporada,
            Long idAdministrador,
            String codigoInvitacion,
            Date closedAt,
            int maxParticipantes
    ) {}

    private record CalendarGenerationResult(
            int numeroJornadas,
            LocalDateTime primerPartidoEn,
            LocalDate finLigaEn
    ) {}

    /**
     * Quita al usuario de todas sus ligas antes de eliminar la cuenta.
     * Transfiere administración o cierra la liga si es el único participante.
     */
    public void removeUserFromAllLeaguesForAccountDeletion(long userId) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                removeUserFromAllLeaguesForAccountDeletion(conn, userId);
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof IllegalArgumentException illegal) {
                    throw illegal;
                }
                if (e instanceof SQLException sql) {
                    throw sql;
                }
                throw new SQLException("Error limpiando ligas del usuario: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void removeUserFromAllLeaguesForAccountDeletion(Connection conn, long userId) throws SQLException {
        List<Long> leagueIds = loadLeagueIdsForUser(conn, userId);
        for (Long idLiga : leagueIds) {
            LeagueData league = findLeagueByIdForUpdate(conn, idLiga);
            if (league == null) {
                continue;
            }
            boolean isAdmin = Objects.equals(league.idAdministrador(), userId);
            int otherParticipants = countParticipantsExcludingUser(conn, idLiga, userId);

            if (isAdmin && otherParticipants == 0) {
                List<Long> participantes = loadLeagueParticipantUserIds(conn, idLiga);
                accountProgressService.onLeagueClosed(conn, idLiga);
                for (Long idParticipante : participantes) {
                    dissolveParticipant(conn, idLiga, idParticipante);
                }
                try (PreparedStatement ps = conn.prepareStatement("""
                        UPDATE ligas SET cerrada_en = CURDATE(), codigo_invitacion = NULL WHERE id = ?
                        """)) {
                    ps.setLong(1, idLiga);
                    ps.executeUpdate();
                }
                continue;
            }

            if (isAdmin && otherParticipants > 0) {
                Long newAdmin = findFirstOtherParticipantUserId(conn, idLiga, userId);
                if (newAdmin != null) {
                    updateLeagueAdmin(conn, idLiga, newAdmin);
                }
            }

            dissolveParticipant(conn, idLiga, userId);
        }

        reassignOrCloseLeaguesStillAdministeredBy(conn, userId);
    }

    private List<Long> loadLeagueIdsForUser(Connection conn, long userId) throws SQLException {
        String sql = """
                SELECT DISTINCT lp.id_liga
                FROM liga_participantes lp
                WHERE lp.id_usuario = ?
                ORDER BY lp.id_liga ASC
                """;
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id_liga"));
                }
            }
        }
        return ids;
    }

    private Long findFirstOtherParticipantUserId(Connection conn, Long idLiga, long excludeUserId)
            throws SQLException {
        String sql = """
                SELECT id_usuario
                FROM liga_participantes
                WHERE id_liga = ? AND id_usuario <> ?
                ORDER BY id ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, excludeUserId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id_usuario") : null;
            }
        }
    }

    private void reassignOrCloseLeaguesStillAdministeredBy(Connection conn, long userId) throws SQLException {
        String sql = "SELECT id FROM ligas WHERE id_administrador = ?";
        List<Long> leagueIds = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    leagueIds.add(rs.getLong("id"));
                }
            }
        }

        for (Long idLiga : leagueIds) {
            Long replacement = findFirstOtherParticipantUserId(conn, idLiga, userId);
            if (replacement != null) {
                updateLeagueAdmin(conn, idLiga, replacement);
            } else {
                try (PreparedStatement ps = conn.prepareStatement("""
                        UPDATE ligas SET cerrada_en = COALESCE(cerrada_en, CURDATE()), codigo_invitacion = NULL
                        WHERE id = ?
                        """)) {
                    ps.setLong(1, idLiga);
                    ps.executeUpdate();
                }
            }
        }
    }

    private record CandidateLeaguePlayer(
            Long leaguePlayerId,
            Long playerId,
            Long teamId,
            String name,
            String position,
            int rating,
            long value
    ) {}

    private record InitialSquadAssignment(
            int assignedCount,
            long totalValue,
            boolean incomplete,
            String strategy
    ) {
    }

    private record LeagueTeamData(
            Long leagueTeamId,
            Long teamId
    ) {}

    private record MatchPair(
            LeagueTeamData homeTeam,
            LeagueTeamData awayTeam
    ) {}
}
