package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.config.LeagueAutomationProperties;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationMatchResultResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationRepairResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationRunResponse;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Random;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class LeagueSimulationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueSimulationService.class);
    private static final int FULL_MATCH_MINUTES = 90;
    private static final int MAX_SUBSTITUTIONS = 5;
    private static final int MIN_TACTICAL_SUBSTITUTIONS = 3;
    private static final int PREPARATION_HOURS_BEFORE_MATCH = 1;
    /** Titulares obligatorios en la convocatoria persistida para simulación de partido real. */
    private static final int MATCH_STARTERS = 11;
    /**
     * Mínimo de convocados (titulares + banquillo). Cedidos de banquillo solo si el club no llega solo con
     * jugadores propios disponibles a este número ({@link #buildPreparedLineupWithLoans}).
     */
    private static final int MATCH_MIN_CONVOCATORIA_PLAYERS = MATCH_STARTERS + 3;
    /** Descenso diario de cansancio (cron medianoche): 2 en ligas solo fin de semana, 4 si hay entresemana. */
    private static final int DAILY_MIDNIGHT_FATIGUE_DECAY_WEEKEND_ONLY = 2;
    private static final int DAILY_MIDNIGHT_FATIGUE_DECAY_MIDWEEK_LEAGUE = 4;
    private static final double ATTACK_SEQUENCE_CHANCE = 0.23;
    /** Recuperaciones fuera de jugadas de ataque (no afecta goles/asistencias). */
    private static final double RECOVERY_EVENT_CHANCE = 0.27;
    /** Microduelos dentro de jugadas ofensivas para generar más regates/recuperaciones sin disparar el marcador. */
    private static final double ATTACK_DUEL_EVENT_CHANCE = 0.42;
    private static final double MISSED_SHOT_SAVE_EVENT_CHANCE = 0.90;
    private static final double HOME_ATTACK_ADVANTAGE = 4.0;
    private static final double QUALITY_IMPACT_MULTIPLIER = 1.30;
    private static final String PLAYER_ORIGIN_LEAGUE = "LIGA_JUGADOR";
    private static final String PLAYER_ORIGIN_EXCLUSIVE_LOAN = "CEDIDO_EXCLUSIVO";

    private final LeaguePlayerPricingService pricingService;
    private final LeagueRewardService leagueRewardService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeagueAutomationProperties leagueAutomationProperties;

    @Autowired
    private LeagueLineupService leagueLineupService;

    @Autowired
    private LeagueLineupAvailabilityNotificationService lineupAvailabilityNotificationService;

    public LeagueSimulationService(
            LeaguePlayerPricingService pricingService,
            LeagueRewardService leagueRewardService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeagueAutomationProperties leagueAutomationProperties
    ) {
        this.pricingService = pricingService;
        this.leagueRewardService = leagueRewardService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leagueAutomationProperties = leagueAutomationProperties;
    }

    public int prepareDueLineups() throws SQLException {
        List<DueMatchRef> dueMatches = loadMatchesNeedingLineupPreparation();
        int prepared = 0;

        for (DueMatchRef dueMatch : dueMatches) {
            if (!leagueAutomationProperties.isLeagueAllowed(dueMatch.idLiga())) {
                continue;
            }
            try {
                prepareMatchLineupNow(dueMatch.idLiga(), dueMatch.idPartido());
                prepared++;
            } catch (IllegalArgumentException e) {
                if (isStructuralPreparationFailure(e)) {
                    recordStructuralPreparationFailure(dueMatch.idLiga(), dueMatch.idPartido(), e);
                }
            }
        }

        return prepared;
    }

    public void prepareMatchLineupNow(Long idLiga, Long idPartido) throws SQLException {
        if (idLiga == null || idPartido == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                MatchHeader header = lockMatchHeader(conn, idLiga, idPartido);

                if (header == null) {
                    throw new IllegalArgumentException("Partido no encontrado");
                }

                if (!"PENDIENTE".equals(header.estado())) {
                    throw new IllegalArgumentException("Solo se pueden preparar alineaciones de partidos pendientes");
                }

                prepareLineupIfMissing(conn, header, true);

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error preparando alineación: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public LeagueSimulationRunResponse runDueSimulations() throws SQLException {
    List<DueMatchRef> dueMatches = loadDueMatches();
    List<LeagueSimulationMatchResultResponse> results = new ArrayList<>();

    for (DueMatchRef dueMatch : dueMatches) {
        if (!leagueAutomationProperties.isLeagueAllowed(dueMatch.idLiga())) {
            continue;
        }
        try {
            LeagueSimulationMatchResultResponse result =
                    simulateMatchInternal(dueMatch.idLiga(), dueMatch.idPartido(), false);

            if (result != null) {
                results.add(result);
            }
        } catch (Exception e) {
            if (e instanceof IllegalArgumentException iae && isStructuralPreparationFailure(iae)) {
                recordStructuralPreparationFailure(dueMatch.idLiga(), dueMatch.idPartido(), iae);
            }
            log.error(
                    "Error simulando partido automático. liga={}, partido={}",
                    dueMatch.idLiga(),
                    dueMatch.idPartido(),
                    e
            );
        }
    }

    return new LeagueSimulationRunResponse(
            dueMatches.size(),
            results.size(),
            results
    );
}

private void deleteStaleSimulationArtifacts(Connection conn, Long idPartido) throws SQLException {
    deleteByMatch(conn, "partido_eventos", idPartido);
    deleteByMatch(conn, "goles", idPartido);
    deleteByMatch(conn, "equipos_partido", idPartido);
    deleteByMatch(conn, "partido_efectos_jugador", idPartido);
    deleteByMatch(conn, "partido_cesiones", idPartido);
    // La alineación de partido debe regenerarse junto a las cesiones para no quedar huérfanas al re-simular.
    deleteByMatch(conn, "alineacion_partido", idPartido);
}

private void deleteByMatch(Connection conn, String tableName, Long idPartido) throws SQLException {
    String sql = "DELETE FROM " + tableName + " WHERE id_partido_jornada = ?";

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);
        ps.executeUpdate();
    }
}

    public LeagueSimulationMatchResultResponse simulateMatchNow(Long idLiga, Long idPartido) throws SQLException {
        return simulateMatchInternal(idLiga, idPartido, true);
    }

    private LeagueSimulationMatchResultResponse simulateMatchInternal(
        Long idLiga,
        Long idPartido,
        boolean forceNow
) throws SQLException {
    if (idLiga == null || idPartido == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);

        try {
            MatchHeader header = lockMatchHeader(conn, idLiga, idPartido);

            if (header == null) {
                throw new IllegalArgumentException("Partido no encontrado");
            }

            if (!"PENDIENTE".equals(header.estado())) {
                throw new IllegalArgumentException("El partido no está pendiente de simulación");
            }

            Instant now = Instant.now();

            if (!forceNow && header.inicioEn() != null && header.inicioEn().isAfter(now)) {
                throw new IllegalArgumentException("El partido todavía no está listo para simular");
            }

            deleteStaleSimulationArtifacts(conn, header.idPartido());
            leagueLineupService.ensureFrozenLineupsForRound(conn, header.idLiga(), header.idJornada());
            prepareLineupIfMissing(conn, header, true);
            markMatchInProgress(conn, header.idJornada(), header.idPartido());

            PreparedRuntimeStates preparedStates = loadPreparedRuntimeStates(conn, header);
            RuntimeTeamState localState = preparedStates.localState();
            RuntimeTeamState awayState = preparedStates.awayState();

            Random rng = new Random(System.nanoTime() ^ header.idPartido());

            List<SimulatedEvent> loanChronologyPrefix = buildLoanChronologyPrefixEvents(conn, header);
            MatchSimulationOutput output = simulateMatch(header, localState, awayState, rng, loanChronologyPrefix);

            insertMatchEvents(conn, header.idPartido(), output.events());
            insertGoals(conn, header.idPartido(), output.goalRows());
            insertTeamMatchRows(conn, header.idPartido(), localState, awayState);

            upsertPlayerRoundStats(conn, header.idJornada(), localState, awayState);
            upsertPendingPlayerEffects(conn, header.idPartido(), output.availabilityChanges(), localState, awayState);

            // Simulación automática (cron): EN_JUEGO hasta ventana + finalize-due.
            // POST .../simulate (forceNow): si ya llegó el inicio, finaliza en el mismo commit.
            // Si se simula antes del inicio, se mantiene EN_JUEGO para no aplicar lesiones/sanciones antes de tiempo.
            String estadoFinalRespuesta = "EN_JUEGO";
            boolean kickoffReached = header.inicioEn() == null || !header.inicioEn().isAfter(now);
            boolean finalizedInSameTx = false;
            if (forceNow && kickoffReached) {
                applyFullMatchFinalization(conn, header, localState.goals, awayState.goals);
                estadoFinalRespuesta = "FINALIZADO";
                finalizedInSameTx = true;
            }

            conn.commit();

            if (finalizedInSameTx) {
                try {
                    leagueStarterProbabilityService.recalculateForMatch(idLiga, idPartido);
                } catch (SQLException ex) {
                    log.warn(
                            "No se pudieron recalcular probabilidades de titular tras simular partido {}: {}",
                            idPartido,
                            ex.getMessage());
                }
                postCommitRoundFantasyRewards(header.idLiga(), header.idJornada());
            }

            return new LeagueSimulationMatchResultResponse(
                    header.idLiga(),
                    header.idJornada(),
                    header.idPartido(),
                    header.nombreEquipoLocal(),
                    localState.goals,
                    header.nombreEquipoVisitante(),
                    awayState.goals,
                    estadoFinalRespuesta
            );
        } catch (Exception e) {
            conn.rollback();

            if (e instanceof IllegalArgumentException illegalArgumentException) {
                throw illegalArgumentException;
            }

            if (e instanceof SQLException sqlException) {
                throw sqlException;
            }

            throw new SQLException("Error simulando partido: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }
    }

    private List<DueMatchRef> loadMatchesNeedingLineupPreparation() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT j.id_liga,
                           pj.id AS id_partido
                    FROM partidos_jornada pj
                    INNER JOIN jornadas j ON j.id = pj.id_jornada
                    LEFT JOIN alineacion_partido ap ON ap.id_partido_jornada = pj.id
                    WHERE pj.estado = 'PENDIENTE'
                      AND pj.inicio_en IS NOT NULL
                      AND pj.inicio_en <= DATE_ADD(NOW(), INTERVAL 1 HOUR)
                      AND pj.preparacion_bloqueada_en IS NULL
                    GROUP BY j.id_liga, pj.id
                    HAVING COUNT(ap.id) = 0
                    ORDER BY pj.inicio_en ASC, pj.id ASC
                    """;

            List<DueMatchRef> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    rows.add(new DueMatchRef(
                            rs.getLong("id_liga"),
                            rs.getLong("id_partido")
                    ));
                }
            }

            return rows;
        }
    }

    private List<DueMatchRef> loadDueMatches() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT j.id_liga,
                           pj.id AS id_partido
                    FROM partidos_jornada pj
                    INNER JOIN jornadas j ON j.id = pj.id_jornada
                    WHERE pj.estado = 'PENDIENTE'
                      AND pj.inicio_en IS NOT NULL
                      AND pj.inicio_en <= NOW()
                      AND pj.preparacion_bloqueada_en IS NULL
                    ORDER BY pj.inicio_en ASC, pj.id ASC
                    """;

            List<DueMatchRef> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    rows.add(new DueMatchRef(
                            rs.getLong("id_liga"),
                            rs.getLong("id_partido")
                    ));
                }
            }

            return rows;
        }
    }

    private MatchHeader lockMatchHeader(Connection conn, Long idLiga, Long idPartido) throws SQLException {
        String sql = """
                SELECT pj.id AS id_partido,
                       pj.id_jornada,
                       j.id_liga,
                       pj.estado,
                       pj.inicio_en,
                       le_local.id AS id_liga_equipo_local,
                       le_local.id_equipo AS id_equipo_local,
                       e_local.nombre AS nombre_equipo_local,
                       e_local.alineacion AS alineacion_equipo_local,
                       le_visitante.id AS id_liga_equipo_visitante,
                       le_visitante.id_equipo AS id_equipo_visitante,
                       e_visitante.nombre AS nombre_equipo_visitante,
                       e_visitante.alineacion AS alineacion_equipo_visitante
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                INNER JOIN liga_equipos le_local
                    ON le_local.id_liga = j.id_liga AND le_local.id_equipo = pj.id_liga_equipo_local
                INNER JOIN equipos e_local ON e_local.id = le_local.id_equipo
                INNER JOIN liga_equipos le_visitante
                    ON le_visitante.id_liga = j.id_liga AND le_visitante.id_equipo = pj.id_liga_equipo_visitante
                INNER JOIN equipos e_visitante ON e_visitante.id = le_visitante.id_equipo
                WHERE pj.id = ?
                  AND j.id_liga = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            ps.setLong(2, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Timestamp kickoffTs = rs.getTimestamp("inicio_en");
                Instant kickoff = kickoffTs == null ? null : kickoffTs.toInstant();

                return new MatchHeader(
                        rs.getLong("id_partido"),
                        rs.getLong("id_jornada"),
                        rs.getLong("id_liga"),
                        rs.getString("estado"),
                        kickoff,
                        rs.getLong("id_liga_equipo_local"),
                        rs.getLong("id_equipo_local"),
                        rs.getString("nombre_equipo_local"),
                        rs.getLong("id_liga_equipo_visitante"),
                        rs.getLong("id_equipo_visitante"),
                        rs.getString("nombre_equipo_visitante"),
                        rs.getString("alineacion_equipo_local"),
                        rs.getString("alineacion_equipo_visitante")
                );
            }
        }
    }

    private void prepareLineupIfMissing(Connection conn, MatchHeader header, boolean forceNow) throws SQLException {
        if (hasPreparedLineup(conn, header.idPartido())) {
            return;
        }

        if (!"PENDIENTE".equals(header.estado())) {
            throw new IllegalArgumentException("Solo se puede preparar alineación de partidos pendientes");
        }

        Instant now = Instant.now();
        Instant preparationWindow = now.plus(PREPARATION_HOURS_BEFORE_MATCH, ChronoUnit.HOURS);

        if (!forceNow && header.inicioEn() != null && header.inicioEn().isAfter(preparationWindow)) {
            throw new IllegalArgumentException("Todavía no toca preparar la alineación de este partido");
        }

        normalizeExpiredUnavailablePlayers(conn, header.idLiga(), header.idEquipoLocal());
        normalizeExpiredUnavailablePlayers(conn, header.idLiga(), header.idEquipoVisitante());

        List<TeamPlayerData> localPlayers = loadAvailableTeamPlayers(conn, header.idLiga(), header.idEquipoLocal());
        List<TeamPlayerData> awayPlayers = loadAvailableTeamPlayers(conn, header.idLiga(), header.idEquipoVisitante());

        Set<Long> reservedForMatch = new HashSet<>();
        for (TeamPlayerData p : localPlayers) {
            reservedForMatch.add(p.idLigaJugador());
        }
        for (TeamPlayerData p : awayPlayers) {
            reservedForMatch.add(p.idLigaJugador());
        }

        Random prepRng = new Random(System.nanoTime() ^ header.idPartido());
        PreparedLineupWithLoans localBundle = buildPreparedLineupWithLoans(
                conn, header, true, localPlayers, reservedForMatch, prepRng
        );
        PreparedLineupWithLoans awayBundle = buildPreparedLineupWithLoans(
                conn, header, false, awayPlayers, reservedForMatch, prepRng
        );

        insertPreparedLineup(conn, header.idPartido(), header.idLigaEquipoLocal(), localBundle.lineup());
        insertPreparedLineup(conn, header.idPartido(), header.idLigaEquipoVisitante(), awayBundle.lineup());
        insertPartidoCesiones(conn, header.idPartido(), localBundle.loanRows(), awayBundle.loanRows());
    }

    private boolean hasPreparedLineup(Connection conn, Long idPartido) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM alineacion_partido
                WHERE id_partido_jornada = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total") > 0;
            }
        }
    }

    /**
     * Baja el cansancio de todos los jugadores en todas las ligas (una vez al día, p. ej. medianoche).
     *
     * @return filas actualizadas ({@code cansancio > 0} antes del {@code UPDATE})
     */
    public int applyMidnightFatigueDecayAllLeaguePlayers() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    UPDATE liga_jugadores lj
                    INNER JOIN ligas l ON l.id = lj.id_liga
                    SET lj.cansancio = GREATEST(
                        0,
                        lj.cansancio - CASE WHEN l.permite_entresemana = 1 THEN ? ELSE ? END
                    )
                    WHERE lj.cansancio > 0
                    """;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, DAILY_MIDNIGHT_FATIGUE_DECAY_MIDWEEK_LEAGUE);
                ps.setInt(2, DAILY_MIDNIGHT_FATIGUE_DECAY_WEEKEND_ONLY);
                return ps.executeUpdate();
            }
        }
    }

    private void normalizeExpiredUnavailablePlayers(Connection conn, Long idLiga, Long idEquipo) throws SQLException {
        String sqlLesion = """
                UPDATE liga_jugadores
                SET estado = 'DISPONIBLE',
                    lesionado_hasta = NULL
                WHERE id_liga = ?
                  AND id_equipo = ?
                  AND estado = 'LESIONADO'
                  AND lesionado_hasta IS NOT NULL
                  AND lesionado_hasta <= NOW()
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlLesion)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idEquipo);
            ps.executeUpdate();
        }

        String sqlSanction = """
                UPDATE liga_jugadores
                SET estado = 'DISPONIBLE',
                    sancionado_hasta = NULL
                WHERE id_liga = ?
                  AND id_equipo = ?
                  AND estado = 'SANCIONADO'
                  AND sancionado_hasta IS NOT NULL
                  AND sancionado_hasta <= NOW()
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlSanction)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idEquipo);
            ps.executeUpdate();
        }
    }

    private List<TeamPlayerData> loadAvailableTeamPlayers(Connection conn, Long idLiga, Long idEquipo) throws SQLException {
        String sql = """
                SELECT lj.id AS id_liga_jugador,
                       j.id AS id_jugador,
                       j.nombre,
                       j.pila,
                       j.foto,
                       j.posicion,
                       COALESCE(lj.valoracion_actual, j.valoracion) AS valoracion_actual,
                       lj.estado,
                       lj.cansancio,
                       lj.valor,
                       COALESCE((
                           SELECT AVG(t.puntos)
                           FROM (
                               SELECT jp.puntos
                               FROM jugadores_puntos_jornada jp
                               WHERE jp.id_liga_jugador = lj.id
                               ORDER BY jp.id_jornada DESC
                               LIMIT 3
                           ) t
                       ), 0) AS media_ultimos_3,
                       COALESCE((
                           SELECT AVG(jp2.puntos)
                           FROM jugadores_puntos_jornada jp2
                           WHERE jp2.id_liga_jugador = lj.id
                       ), 0) AS media_temporada
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id_liga = ?
                  AND lj.id_equipo = ?
                  AND lj.estado IN ('DISPONIBLE', 'DUDA')
                ORDER BY
                    CASE j.posicion
                        WHEN 'POR' THEN 1
                        WHEN 'DEF' THEN 2
                        WHEN 'MED' THEN 3
                        WHEN 'DEL' THEN 4
                        ELSE 5
                    END,
                    COALESCE(lj.valoracion_actual, j.valoracion) DESC,
                    lj.valor DESC,
                    j.nombre ASC
                """;

        List<TeamPlayerData> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idEquipo);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    double currentRating = rs.getDouble("valoracion_actual");
                    double recentAverage = rs.getDouble("media_ultimos_3");
                    double seasonAverage = rs.getDouble("media_temporada");
                    int cansancio = rs.getInt("cansancio");
                    String estado = rs.getString("estado");

                    double selectionScore = calculateSelectionScore(
                            currentRating,
                            recentAverage,
                            seasonAverage,
                            cansancio,
                            estado
                    );

                    players.add(new TeamPlayerData(
                            rs.getLong("id_liga_jugador"),
                            rs.getLong("id_jugador"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            rs.getString("posicion"),
                            currentRating,
                            estado,
                            cansancio,
                            rs.getLong("valor"),
                            recentAverage,
                            seasonAverage,
                            selectionScore,
                            false,
                            PLAYER_ORIGIN_LEAGUE,
                            null,
                            null,
                            rs.getString("foto")
                    ));
                }
            }
        }

        return players;
    }

    private double calculateSelectionScore(
        double currentRating,
        double recentAverage,
        double seasonAverage,
        int cansancio,
        String estado
) {
    double formBonus = 0.0;

    if (recentAverage >= 9.0) {
        formBonus += 2.5;
    } else if (recentAverage >= 7.0) {
        formBonus += 1.5;
    } else if (recentAverage >= 5.0) {
        formBonus += 0.5;
    }

    if (seasonAverage >= 7.5) {
        formBonus += 0.5;
    } else if (seasonAverage >= 6.0) {
        formBonus += 0.25;
    }

    double fatiguePenalty = resolveFatiguePenalty(cansancio);
    double doubtPenalty = "DUDA".equalsIgnoreCase(estado) ? 2.5 : 0.0;

    return currentRating + formBonus - fatiguePenalty - doubtPenalty;
}

    private double resolveFatiguePenalty(int cansancio) {
    if (cansancio <= 0) {
        return 0.0;
    }

    double normalized = Math.min(100, Math.max(0, cansancio)) / 100.0;
    double penalty = Math.pow(normalized, 1.35) * 14.0;

    if (cansancio >= 80) {
        penalty += 2.5;
    } else if (cansancio >= 60) {
        penalty += 1.0;
    }

    return round2(penalty);
}

    /**
     * Once inicial solo con jugadores del pool: respeta conteos de formación (1 POR + def/med/del).
     * Si tras agotar el pool faltan titulares, el llamador completa con cedidos exclusivos por posición.
     */
    private PreparedLineup buildPreparedLineup(List<TeamPlayerData> players, TeamFormation formation) {
        List<TeamPlayerData> pool = new ArrayList<>(players);
        sortBySelectionDescending(pool);

        List<TeamPlayerData> starters = new ArrayList<>();
        starters.addAll(pickBestPlayersByPosition(pool, "POR", 1));
        starters.addAll(pickBestPlayersByPosition(pool, "DEF", formation.def()));
        starters.addAll(pickBestPlayersByPosition(pool, "MED", formation.med()));
        starters.addAll(pickBestPlayersByPosition(pool, "DEL", formation.del()));

        fillStartersFromPoolRespectingFormation(starters, pool, formation);

        sortForPitchDisplay(starters);
        sortBenchForSubstitutions(pool);

        return new PreparedLineup(starters, new ArrayList<>(pool));
    }

    private static long countStartersByPosition(List<TeamPlayerData> starters, String position) {
        return starters.stream().filter(p -> position.equals(p.posicion())).count();
    }

    /** Plazas titulares que faltan por línea respecto a {@code equipos.alineacion} (solo déficits, no sobrantes). */
    private int countFormationStarterDeficits(List<TeamPlayerData> starters, TeamFormation formation) {
        int deficits = 0;
        deficits += Math.max(0, 1 - (int) countStartersByPosition(starters, "POR"));
        deficits += Math.max(0, formation.def() - (int) countStartersByPosition(starters, "DEF"));
        deficits += Math.max(0, formation.med() - (int) countStartersByPosition(starters, "MED"));
        deficits += Math.max(0, formation.del() - (int) countStartersByPosition(starters, "DEL"));
        return deficits;
    }

    private int computeStarterLoansNeeded(List<TeamPlayerData> starters, TeamFormation formation) {
        int sizeGap = MATCH_STARTERS - starters.size();
        int positionDeficits = countFormationStarterDeficits(starters, formation);
        return Math.max(sizeGap, positionDeficits);
    }

    /**
     * Libera plazas en el once si hay sobrantes por línea (p. ej. 4 MED en 4-3-3) para poder ceder la posición faltante.
     */
    private void removeSurplusStartersForFormation(
            List<TeamPlayerData> starters,
            List<TeamPlayerData> bench,
            TeamFormation formation
    ) {
        removeSurplusStartersForPosition(starters, bench, "DEL", formation.del());
        removeSurplusStartersForPosition(starters, bench, "MED", formation.med());
        removeSurplusStartersForPosition(starters, bench, "DEF", formation.def());
        removeSurplusStartersForPosition(starters, bench, "POR", 1);
    }

    private void removeSurplusStartersForPosition(
            List<TeamPlayerData> starters,
            List<TeamPlayerData> bench,
            String position,
            int required
    ) {
        while (countStartersByPosition(starters, position) > required) {
            TeamPlayerData toBench = starters.stream()
                    .filter(p -> position.equals(p.posicion()))
                    .min(Comparator.comparingDouble(TeamPlayerData::selectionScore)
                            .thenComparing(TeamPlayerData::nombre))
                    .orElse(null);
            if (toBench == null) {
                break;
            }
            starters.remove(toBench);
            bench.add(toBench);
        }
    }

    private static String loanUnavailableForPositionMessage(String position) {
        return "No hay jugadores cedibles disponibles para la posición " + position;
    }

    /** Primera línea de la formación que aún no cumple el cupo (orden POR → DEF → MED → DEL). */
    private String firstFormationDeficitPosition(List<TeamPlayerData> starters, TeamFormation formation) {
        if (countStartersByPosition(starters, "POR") < 1) {
            return "POR";
        }
        if (countStartersByPosition(starters, "DEF") < formation.def()) {
            return "DEF";
        }
        if (countStartersByPosition(starters, "MED") < formation.med()) {
            return "MED";
        }
        if (countStartersByPosition(starters, "DEL") < formation.del()) {
            return "DEL";
        }
        return null;
    }

    /** Solo añade del pool jugadores cuya posición cubre un déficit de formación (mejor score por línea). */
    private void fillStartersFromPoolRespectingFormation(
            List<TeamPlayerData> starters,
            List<TeamPlayerData> pool,
            TeamFormation formation
    ) {
        sortBySelectionDescending(pool);
        boolean progress = true;
        while (starters.size() < MATCH_STARTERS && progress) {
            progress = false;
            String deficitPos = firstFormationDeficitPosition(starters, formation);
            if (deficitPos == null) {
                break;
            }
            List<TeamPlayerData> picked = pickBestPlayersByPosition(pool, deficitPos, 1);
            if (!picked.isEmpty()) {
                starters.addAll(picked);
                progress = true;
            }
        }
    }

    /**
     * Mejor jugador propio restante para una posición (lista ya ordenada por score descendente).
     */
    private TeamPlayerData removeBestRemainingOwnForPosition(List<TeamPlayerData> remainingOwn, String position) {
        for (int i = 0; i < remainingOwn.size(); i++) {
            if (position.equals(remainingOwn.get(i).posicion())) {
                return remainingOwn.remove(i);
            }
        }
        return null;
    }

    private void validateStartersMatchFormation(List<TeamPlayerData> starters, TeamFormation formation) {
        if (starters.size() != MATCH_STARTERS) {
            throw new IllegalArgumentException(
                    "Once titular incompleto: hay " + starters.size() + " jugadores, se esperaban " + MATCH_STARTERS
            );
        }
        long por = countStartersByPosition(starters, "POR");
        long def = countStartersByPosition(starters, "DEF");
        long med = countStartersByPosition(starters, "MED");
        long del = countStartersByPosition(starters, "DEL");
        if (por != 1
                || def != formation.def()
                || med != formation.med()
                || del != formation.del()) {
            throw new IllegalArgumentException(
                    "La formación titular no coincide con equipos.alineacion (esperado POR 1, DEF "
                            + formation.def() + ", MED " + formation.med() + ", DEL " + formation.del()
                            + "; actual POR " + por + ", DEF " + def + ", MED " + med + ", DEL " + del + ")"
            );
        }
    }

    private List<TeamPlayerData> pickBestPlayersByPosition(List<TeamPlayerData> source, String position, int count) {
        List<TeamPlayerData> result = new ArrayList<>();
        List<TeamPlayerData> toRemove = new ArrayList<>();

        for (TeamPlayerData player : source) {
            if (position.equals(player.posicion())) {
                result.add(player);
                toRemove.add(player);

                if (result.size() == count) {
                    break;
                }
            }
        }

        source.removeAll(toRemove);
        return result;
    }

    private void sortBySelectionDescending(List<TeamPlayerData> players) {
    players.sort(
            Comparator.comparingDouble(TeamPlayerData::selectionScore).reversed()
                    .thenComparing(Comparator.comparingDouble(TeamPlayerData::valoracionActual).reversed())
                    .thenComparing(Comparator.comparingLong(TeamPlayerData::valor).reversed())
                    .thenComparing(TeamPlayerData::nombre)
    );
}

private void sortForPitchDisplay(List<TeamPlayerData> players) {
    players.sort(
            Comparator.comparingInt((TeamPlayerData p) -> positionOrder(p.posicion()))
                    .thenComparing(Comparator.comparingDouble(TeamPlayerData::selectionScore).reversed())
                    .thenComparing(TeamPlayerData::nombre)
    );
}

private void sortBenchForSubstitutions(List<TeamPlayerData> players) {
    players.sort(
            Comparator.comparingInt((TeamPlayerData p) -> benchPriority(p.posicion()))
                    .thenComparing(Comparator.comparingDouble(TeamPlayerData::selectionScore).reversed())
                    .thenComparingInt(TeamPlayerData::cansancio)
                    .thenComparing(TeamPlayerData::nombre)
    );
}

private int benchPriority(String position) {
    return switch (position) {
        case "POR" -> 1;
        case "DEF" -> 2;
        case "MED" -> 3;
        case "DEL" -> 4;
        default -> 5;
    };
}

    private boolean isExclusiveLoanPlayer(TeamPlayerData player) {
        return player != null && PLAYER_ORIGIN_EXCLUSIVE_LOAN.equals(player.tipoOrigenJugador());
    }

    private TeamFormation resolveTeamFormation(MatchHeader header, boolean localSide) {
        String raw = localSide ? header.alineacionEquipoLocal() : header.alineacionEquipoVisitante();
        return parseTeamFormation(raw);
    }

    private TeamFormation parseTeamFormation(String raw) {
        TeamFormation fallback = new TeamFormation(4, 3, 3);
        if (raw == null || raw.isBlank()) {
            return fallback;
        }
        String normalized = raw.trim().replace(" ", "");
        String[] parts = normalized.split("-");
        try {
            if (parts.length == 3) {
                return teamFormationFromParts(parts[0], parts[1], parts[2], fallback);
            }
            if (parts.length == 4) {
                // p. ej. 4-2-3-1 → DEF 4, MED 2+3=5, DEL 1
                int medCombined = Integer.parseInt(parts[1]) + Integer.parseInt(parts[2]);
                return teamFormationFromParts(parts[0], String.valueOf(medCombined), parts[3], fallback);
            }
            log.warn("Formación de equipo no reconocida '{}'; se usa 4-3-3", raw);
            return fallback;
        } catch (NumberFormatException e) {
            log.warn("Formación de equipo inválida '{}'; se usa 4-3-3", raw);
            return fallback;
        }
    }

    private TeamFormation teamFormationFromParts(String defPart, String medPart, String delPart, TeamFormation fallback) {
        int def = Integer.parseInt(defPart);
        int med = Integer.parseInt(medPart);
        int del = Integer.parseInt(delPart);
        if (def < 0 || med < 0 || del < 0 || def + med + del != 10) {
            return fallback;
        }
        return new TeamFormation(def, med, del);
    }

    private boolean isStructuralPreparationFailure(IllegalArgumentException e) {
        if (e == null || e.getMessage() == null) {
            return false;
        }
        String m = e.getMessage();
        return m.contains("formación titular no coincide")
                || m.contains("Huecos titulares inconsistentes")
                || m.contains("Once titular incompleto")
                || m.contains("No se ha podido completar el once titular")
                || m.contains("Convocatoria inválida")
                || m.contains("No hay jugadores cedibles disponibles para la posición");
    }

    /**
     * Marca el partido para que el scheduler no lo reintente cada minuto tras un fallo estructural de plantilla/formación.
     */
    void recordStructuralPreparationFailure(Long idLiga, Long idPartido, IllegalArgumentException cause) {
        if (idLiga == null || idPartido == null) {
            return;
        }
        String motivo = cause.getMessage();
        if (motivo != null && motivo.length() > 500) {
            motivo = motivo.substring(0, 500);
        }
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    UPDATE partidos_jornada pj
                    INNER JOIN jornadas j ON j.id = pj.id_jornada
                    SET pj.preparacion_bloqueada_en = NOW(),
                        pj.preparacion_bloqueada_motivo = ?
                    WHERE pj.id = ?
                      AND j.id_liga = ?
                      AND pj.estado = 'PENDIENTE'
                    """;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, motivo);
                ps.setLong(2, idPartido);
                ps.setLong(3, idLiga);
                int updated = ps.executeUpdate();
                if (updated > 0) {
                    log.warn(
                            "Preparación de partido bloqueada (error estructural). liga={}, partido={}, motivo={}",
                            idLiga,
                            idPartido,
                            motivo
                    );
                }
            }
        } catch (SQLException ex) {
            log.error(
                    "No se pudo registrar bloqueo de preparación. liga={}, partido={}",
                    idLiga,
                    idPartido,
                    ex
            );
        }
    }

    private Long loadLeagueSeasonId(Connection conn, Long idLiga) throws SQLException {
        String sql = "SELECT id_temporada FROM ligas WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id_temporada");
            }
        }
    }

    private int positionOrder(String position) {
        return switch (position) {
            case "POR" -> 1;
            case "DEF" -> 2;
            case "MED" -> 3;
            case "DEL" -> 4;
            default -> 5;
        };
    }

    private void insertPreparedLineup(Connection conn, Long idPartido, Long idLigaEquipo, PreparedLineup lineup) throws SQLException {
        if (lineup.starters().size() != MATCH_STARTERS) {
            throw new IllegalArgumentException(
                    "Convocatoria inválida: se esperaban " + MATCH_STARTERS + " titulares, hay " + lineup.starters().size()
            );
        }

        List<TeamPlayerData> benchToPersist = new ArrayList<>(lineup.bench());

        String sql = """
                INSERT INTO alineacion_partido (
                    id_liga_equipo,
                    id_partido_jornada,
                    id_liga_jugador,
                    id_jugador_cedido_temporada,
                    tipo_origen_jugador,
                    titular
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (TeamPlayerData player : lineup.starters()) {
                ps.setLong(1, idLigaEquipo);
                ps.setLong(2, idPartido);
                if (isExclusiveLoanPlayer(player)) {
                    ps.setNull(3, Types.BIGINT);
                    ps.setInt(4, player.idJugadorCedidoTemporada());
                    ps.setString(5, PLAYER_ORIGIN_EXCLUSIVE_LOAN);
                } else {
                    ps.setLong(3, player.idLigaJugador());
                    ps.setNull(4, Types.INTEGER);
                    ps.setString(5, PLAYER_ORIGIN_LEAGUE);
                }
                ps.setBoolean(6, true);
                ps.addBatch();
            }

            for (TeamPlayerData player : benchToPersist) {
                ps.setLong(1, idLigaEquipo);
                ps.setLong(2, idPartido);
                if (isExclusiveLoanPlayer(player)) {
                    ps.setNull(3, Types.BIGINT);
                    ps.setInt(4, player.idJugadorCedidoTemporada());
                    ps.setString(5, PLAYER_ORIGIN_EXCLUSIVE_LOAN);
                } else {
                    ps.setLong(3, player.idLigaJugador());
                    ps.setNull(4, Types.INTEGER);
                    ps.setString(5, PLAYER_ORIGIN_LEAGUE);
                }
                ps.setBoolean(6, false);
                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    private void insertPartidoCesiones(
            Connection conn,
            Long idPartido,
            List<PartidoCesionRow> localLoans,
            List<PartidoCesionRow> awayLoans
    ) throws SQLException {
        List<PartidoCesionRow> all = new ArrayList<>(localLoans.size() + awayLoans.size());
        all.addAll(localLoans);
        all.addAll(awayLoans);

        if (all.isEmpty()) {
            return;
        }

        String sql = """
                INSERT INTO partido_cesiones (
                    id_partido_jornada,
                    id_liga_jugador,
                    id_liga_equipo_origen,
                    id_equipo_cedidos_temporada_origen,
                    id_jugador_cedido_temporada,
                    tipo_origen_jugador,
                    id_liga_equipo_destino,
                    rol,
                    posicion
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (PartidoCesionRow row : all) {
                ps.setLong(1, idPartido);
                if (PLAYER_ORIGIN_EXCLUSIVE_LOAN.equals(row.tipoOrigenJugador())) {
                    ps.setNull(2, Types.BIGINT);
                    ps.setNull(3, Types.BIGINT);
                    ps.setInt(4, row.idEquipoCedidosTemporadaOrigen());
                    ps.setInt(5, row.idJugadorCedidoTemporada());
                    ps.setString(6, PLAYER_ORIGIN_EXCLUSIVE_LOAN);
                } else {
                    ps.setLong(2, row.idLigaJugador());
                    setNullableLong(ps, 3, row.idLigaEquipoOrigen());
                    ps.setNull(4, Types.INTEGER);
                    ps.setNull(5, Types.INTEGER);
                    ps.setString(6, PLAYER_ORIGIN_LEAGUE);
                }
                ps.setLong(7, row.idLigaEquipoDestino());
                ps.setString(8, row.rol());
                ps.setString(9, row.posicion());
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private Set<Long> loadBusyLigaJugadorIdsForJornada(Connection conn, Long idJornada, Long idPartidoExcluir)
            throws SQLException {
        String sql = """
                SELECT DISTINCT
                    CASE
                        WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN -ap.id_jugador_cedido_temporada
                        ELSE ap.id_liga_jugador
                    END AS id_jugador_runtime
                FROM alineacion_partido ap
                INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
                WHERE pj.id_jornada = ?
                  AND pj.id <> ?
                """;

        Set<Long> ids = new HashSet<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idPartidoExcluir);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Long value = rs.getObject("id_jugador_runtime", Long.class);
                    if (value != null) {
                        ids.add(value);
                    }
                }
            }
        }

        return ids;
    }

    private PreparedLineupWithLoans buildPreparedLineupWithLoans(
            Connection conn,
            MatchHeader header,
            boolean localSide,
            List<TeamPlayerData> ownPlayers,
            Set<Long> reservedPlayerIds,
            Random rng
    ) throws SQLException {
        Set<Long> busyThisRound = loadBusyLigaJugadorIdsForJornada(conn, header.idJornada(), header.idPartido());

        long idLigaEquipoDestino = localSide ? header.idLigaEquipoLocal() : header.idLigaEquipoVisitante();
        long idEquipoDestinoCatalog = localSide ? header.idEquipoLocal() : header.idEquipoVisitante();
        TeamFormation formation = resolveTeamFormation(header, localSide);

        Map<Long, Long> loanOrigenByLigaJugador = new HashMap<>();
        List<TeamPlayerData> sortedOwnPlayers = new ArrayList<>(ownPlayers);
        sortBySelectionDescending(sortedOwnPlayers);

        // Regla de producto: si hay 11+ propios disponibles, el once titular es solo de propios.
        if (sortedOwnPlayers.size() >= MATCH_STARTERS) {
            PreparedLineup ownLineup = buildPreparedLineup(new ArrayList<>(sortedOwnPlayers), formation);
            List<TeamPlayerData> starters = new ArrayList<>(ownLineup.starters());
            List<TeamPlayerData> bench = new ArrayList<>(ownLineup.bench());

            completeStartersWithLoans(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    starters,
                    bench,
                    formation,
                    reservedPlayerIds,
                    busyThisRound,
                    loanOrigenByLigaJugador,
                    rng
            );
            sortForPitchDisplay(starters);

            boolean cedidosBanquilloPermitidos =
                    sortedOwnPlayers.size() < MATCH_MIN_CONVOCATORIA_PLAYERS;
            fillBenchWithLoansIfNeeded(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    starters,
                    bench,
                    loanOrigenByLigaJugador,
                    rng,
                    formation,
                    cedidosBanquilloPermitidos);

            sortBenchForSubstitutions(bench);

            PreparedLineup finalLineup = new PreparedLineup(starters, bench);
            return new PreparedLineupWithLoans(
                    finalLineup,
                    reconcilePartidoCesionRows(finalLineup, idLigaEquipoDestino, loanOrigenByLigaJugador)
            );
        }

        // Si hay menos de 11 propios:
        // 1) entran titulares todos los propios posibles (sin desplazar ninguno por cedidos)
        // 2) cedidos TITULAR solo para completar hasta 11
        // 3) banquillo: propios restantes; cedidos solo si hay <14 propios y falta llegar a 14 convocados
        OwnSelectionResult ownSelection = buildOwnSelectionForFormation(sortedOwnPlayers, formation);
        List<TeamPlayerData> starters = new ArrayList<>(ownSelection.starters());
        List<TeamPlayerData> remainingOwn = new ArrayList<>(ownSelection.remainingOwn());
        sortBySelectionDescending(remainingOwn);

        int maxStartersFromOwn = Math.min(MATCH_STARTERS, sortedOwnPlayers.size());
        while (starters.size() < maxStartersFromOwn && !remainingOwn.isEmpty()) {
            String deficitPos = firstFormationDeficitPosition(starters, formation);
            if (deficitPos == null) {
                break;
            }
            TeamPlayerData extraOwn = removeBestRemainingOwnForPosition(remainingOwn, deficitPos);
            if (extraOwn == null) {
                break;
            }
            starters.add(extraOwn);
        }

        List<TeamPlayerData> bench = new ArrayList<>(remainingOwn);
        completeStartersWithLoans(
                conn,
                header,
                idLigaEquipoDestino,
                idEquipoDestinoCatalog,
                starters,
                bench,
                formation,
                reservedPlayerIds,
                busyThisRound,
                loanOrigenByLigaJugador,
                rng
        );

        if (starters.size() != MATCH_STARTERS) {
            throw new IllegalArgumentException("No se ha podido completar el once titular");
        }

        sortForPitchDisplay(starters);
        sortBenchForSubstitutions(bench);
        boolean cedidosBanquilloPermitidosMenosOnce =
                sortedOwnPlayers.size() < MATCH_MIN_CONVOCATORIA_PLAYERS;
        fillBenchWithLoansIfNeeded(
                conn,
                header,
                idLigaEquipoDestino,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                starters,
                bench,
                loanOrigenByLigaJugador,
                rng,
                formation,
                cedidosBanquilloPermitidosMenosOnce);

        sortBenchForSubstitutions(bench);

        PreparedLineup finalLineup = new PreparedLineup(starters, bench);
        return new PreparedLineupWithLoans(
                finalLineup,
                reconcilePartidoCesionRows(finalLineup, idLigaEquipoDestino, loanOrigenByLigaJugador)
        );
    }

    /**
     * Completa el once titular con cedidos por posición (tras liberar sobrantes de línea si hace falta).
     */
    private void completeStartersWithLoans(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            List<TeamPlayerData> starters,
            List<TeamPlayerData> bench,
            TeamFormation formation,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            Map<Long, Long> loanOrigenByLigaJugador,
            Random rng
    ) throws SQLException {
        removeSurplusStartersForFormation(starters, bench, formation);

        int starterLoansNeeded = computeStarterLoansNeeded(starters, formation);
        for (String preferredPosition : starterLoanPositionHints(starters, starterLoansNeeded, formation)) {
            LoanPickResult pick = tryPickLoanPlayer(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    preferredPosition,
                    rng,
                    true
            );
            if (pick == null) {
                throw new IllegalArgumentException(loanUnavailableForPositionMessage(preferredPosition));
            }
            reservedPlayerIds.add(pick.player().idLigaJugador());
            starters.add(pick.player());
            if (pick.idLigaEquipoOrigen() != null) {
                loanOrigenByLigaJugador.put(pick.player().idLigaJugador(), pick.idLigaEquipoOrigen());
            }
        }

        validateStartersMatchFormation(starters, formation);
    }

    /**
     * Lista exactamente una entrada por plaza titular faltante según la formación (orden POR, DEF, MED, DEL).
     * No debe usarse si los titulares ya violan la formación más allá de “faltan N jugadores”.
     */
    private List<String> starterLoanPositionHints(List<TeamPlayerData> starters, int loansNeeded, TeamFormation formation) {
        if (loansNeeded <= 0) {
            return List.of();
        }

        List<String> hints = new ArrayList<>();
        appendStarterLoanHintsForPosition(hints, starters, "POR", 1);
        appendStarterLoanHintsForPosition(hints, starters, "DEF", formation.def());
        appendStarterLoanHintsForPosition(hints, starters, "MED", formation.med());
        appendStarterLoanHintsForPosition(hints, starters, "DEL", formation.del());

        if (hints.size() != loansNeeded) {
            throw new IllegalArgumentException(
                    "Huecos titulares inconsistentes con equipos.alineacion: hace falta completar "
                            + loansNeeded + " plazas con cedidos, déficit por posición cuenta "
                            + hints.size()
                            + ". Revisa composición previa al préstamo."
            );
        }
        return hints;
    }

    private void appendStarterLoanHintsForPosition(
            List<String> hints,
            List<TeamPlayerData> starters,
            String position,
            int required
    ) {
        long current = countStartersByPosition(starters, position);
        while (current < required) {
            hints.add(position);
            current++;
        }
    }

    private OwnSelectionResult buildOwnSelectionForFormation(List<TeamPlayerData> ownPlayers, TeamFormation formation) {
        List<TeamPlayerData> por = new ArrayList<>();
        List<TeamPlayerData> def = new ArrayList<>();
        List<TeamPlayerData> med = new ArrayList<>();
        List<TeamPlayerData> del = new ArrayList<>();
        List<TeamPlayerData> other = new ArrayList<>();

        for (TeamPlayerData p : ownPlayers) {
            switch (p.posicion()) {
                case "POR" -> por.add(p);
                case "DEF" -> def.add(p);
                case "MED" -> med.add(p);
                case "DEL" -> del.add(p);
                default -> other.add(p);
            }
        }

        sortBySelectionDescending(por);
        sortBySelectionDescending(def);
        sortBySelectionDescending(med);
        sortBySelectionDescending(del);
        sortBySelectionDescending(other);

        List<TeamPlayerData> starters = new ArrayList<>();
        List<TeamPlayerData> remainingOwn = new ArrayList<>();

        takeForStarters(por, 1, starters, remainingOwn);
        takeForStarters(def, formation.def(), starters, remainingOwn);
        takeForStarters(med, formation.med(), starters, remainingOwn);
        takeForStarters(del, formation.del(), starters, remainingOwn);
        remainingOwn.addAll(other);

        return new OwnSelectionResult(starters, remainingOwn);
    }

    private void takeForStarters(
            List<TeamPlayerData> source,
            int required,
            List<TeamPlayerData> starters,
            List<TeamPlayerData> remainingOwn
    ) {
        for (int i = 0; i < source.size(); i++) {
            TeamPlayerData p = source.get(i);
            if (i < required) {
                starters.add(p);
            } else {
                remainingOwn.add(p);
            }
        }
    }

    private void addStarterLoansForDeficit(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            List<TeamPlayerData> starters,
            Map<Long, Long> loanOrigenByLigaJugador,
            String position,
            int required,
            Random rng
    ) throws SQLException {
        long current = starters.stream().filter(p -> position.equals(p.posicion())).count();
        while (current < required) {
            LoanPickResult pick = tryPickLoanPlayer(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    position,
                    rng
            );
            if (pick == null) {
                throw new IllegalArgumentException("No hay jugadores cedibles para completar la posición " + position + " en 4-3-3");
            }
            reservedPlayerIds.add(pick.player().idLigaJugador());
            starters.add(pick.player());
            if (pick.idLigaEquipoOrigen() != null) {
                loanOrigenByLigaJugador.put(pick.player().idLigaJugador(), pick.idLigaEquipoOrigen());
            }
            current++;
        }
    }

    private void fillLoansForMissingClassic433(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            List<TeamPlayerData> pool,
            Map<Long, Long> loanOrigenByLigaJugador,
            Random rng
    ) throws SQLException {
        addLoansForMissingPosition(conn, header, idLigaEquipoDestino, idEquipoDestinoCatalog, reservedPlayerIds, busyThisRound, pool, loanOrigenByLigaJugador, "POR", 1, rng);
        addLoansForMissingPosition(conn, header, idLigaEquipoDestino, idEquipoDestinoCatalog, reservedPlayerIds, busyThisRound, pool, loanOrigenByLigaJugador, "DEF", 4, rng);
        addLoansForMissingPosition(conn, header, idLigaEquipoDestino, idEquipoDestinoCatalog, reservedPlayerIds, busyThisRound, pool, loanOrigenByLigaJugador, "MED", 3, rng);
        addLoansForMissingPosition(conn, header, idLigaEquipoDestino, idEquipoDestinoCatalog, reservedPlayerIds, busyThisRound, pool, loanOrigenByLigaJugador, "DEL", 3, rng);
    }

    private void addLoansForMissingPosition(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            List<TeamPlayerData> pool,
            Map<Long, Long> loanOrigenByLigaJugador,
            String position,
            int required,
            Random rng
    ) throws SQLException {
        long current = pool.stream().filter(p -> position.equals(p.posicion())).count();
        while (current < required) {
            LoanPickResult pick = tryPickLoanPlayer(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    position,
                    rng
            );
            if (pick == null) {
                throw new IllegalArgumentException("No hay jugadores cedibles para completar la posición " + position + " en 4-3-3");
            }
            reservedPlayerIds.add(pick.player().idLigaJugador());
            pool.add(pick.player());
            if (pick.idLigaEquipoOrigen() != null) {
                loanOrigenByLigaJugador.put(pick.player().idLigaJugador(), pick.idLigaEquipoOrigen());
            }
            current++;
        }
    }

    private boolean canBuildClassic433WithOwnPlayers(List<TeamPlayerData> ownPlayers) {
        long por = ownPlayers.stream().filter(p -> "POR".equals(p.posicion())).count();
        long def = ownPlayers.stream().filter(p -> "DEF".equals(p.posicion())).count();
        long med = ownPlayers.stream().filter(p -> "MED".equals(p.posicion())).count();
        long del = ownPlayers.stream().filter(p -> "DEL".equals(p.posicion())).count();
        return por >= 1 && def >= 4 && med >= 3 && del >= 3;
    }

    private void fillBenchWithLoansIfNeeded(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            List<TeamPlayerData> starters,
            List<TeamPlayerData> bench,
            Map<Long, Long> loanOrigenByLigaJugador,
            Random rng,
            TeamFormation formation,
            boolean permitirCedidosParaCompletarConvocatoriaMinima
    ) throws SQLException {
        if (!permitirCedidosParaCompletarConvocatoriaMinima) {
            return;
        }
        while (starters.size() + bench.size() < MATCH_MIN_CONVOCATORIA_PLAYERS) {
            String benchPos = benchLoanPositionHint(bench.size(), formation);
            LoanPickResult pick = tryPickLoanPlayer(
                    conn,
                    header,
                    idLigaEquipoDestino,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    benchPos,
                    rng
            );
            if (pick == null) {
                throw new IllegalArgumentException("No hay jugadores cedibles para completar el banquillo mínimo");
            }
            reservedPlayerIds.add(pick.player().idLigaJugador());
            bench.add(pick.player());
            if (pick.idLigaEquipoOrigen() != null) {
                loanOrigenByLigaJugador.put(pick.player().idLigaJugador(), pick.idLigaEquipoOrigen());
            }
        }
        sortBenchForSubstitutions(bench);
    }

    private List<PartidoCesionRow> reconcilePartidoCesionRows(
            PreparedLineup built,
            long idLigaEquipoDestino,
            Map<Long, Long> loanOrigenByLigaJugador
    ) {
        List<PartidoCesionRow> rows = new ArrayList<>();

        for (TeamPlayerData p : built.starters()) {
            if (p.loanedForMatch()) {
                if (isExclusiveLoanPlayer(p)) {
                    rows.add(new PartidoCesionRow(
                            null,
                            null,
                            p.idEquipoCedidosTemporadaOrigen(),
                            p.idJugadorCedidoTemporada(),
                            PLAYER_ORIGIN_EXCLUSIVE_LOAN,
                            idLigaEquipoDestino,
                            "TITULAR",
                            p.posicion()
                    ));
                    continue;
                }
                Long origen = loanOrigenByLigaJugador.get(p.idLigaJugador());
                if (origen != null) {
                    rows.add(new PartidoCesionRow(
                            p.idLigaJugador(),
                            origen,
                            null,
                            null,
                            PLAYER_ORIGIN_LEAGUE,
                            idLigaEquipoDestino,
                            "TITULAR",
                            p.posicion()
                    ));
                }
            }
        }

        for (TeamPlayerData p : built.bench()) {
            if (p.loanedForMatch()) {
                if (isExclusiveLoanPlayer(p)) {
                    rows.add(new PartidoCesionRow(
                            null,
                            null,
                            p.idEquipoCedidosTemporadaOrigen(),
                            p.idJugadorCedidoTemporada(),
                            PLAYER_ORIGIN_EXCLUSIVE_LOAN,
                            idLigaEquipoDestino,
                            "SUPLENTE",
                            p.posicion()
                    ));
                    continue;
                }
                Long origen = loanOrigenByLigaJugador.get(p.idLigaJugador());
                if (origen != null) {
                    rows.add(new PartidoCesionRow(
                            p.idLigaJugador(),
                            origen,
                            null,
                            null,
                            PLAYER_ORIGIN_LEAGUE,
                            idLigaEquipoDestino,
                            "SUPLENTE",
                            p.posicion()
                    ));
                }
            }
        }

        return rows;
    }

    private static String benchLoanPositionHint(int benchSizeSoFar, TeamFormation formation) {
        List<String> priority = new ArrayList<>();
        if (formation.med() > 0) priority.add("MED");
        if (formation.def() > 0) priority.add("DEF");
        if (formation.del() > 0) priority.add("DEL");
        if (priority.isEmpty()) {
            priority.add("MED");
            priority.add("DEF");
            priority.add("DEL");
        }
        return priority.get(Math.min(benchSizeSoFar, priority.size() - 1));
    }

    private static String starterLoanPositionHint(List<TeamPlayerData> pool) {
        long por = pool.stream().filter(p -> "POR".equals(p.posicion())).count();
        long def = pool.stream().filter(p -> "DEF".equals(p.posicion())).count();
        long med = pool.stream().filter(p -> "MED".equals(p.posicion())).count();
        long del = pool.stream().filter(p -> "DEL".equals(p.posicion())).count();
        if (por < 1) {
            return "POR";
        }
        if (def < 4) {
            return "DEF";
        }
        if (med < 3) {
            return "MED";
        }
        if (del < 3) {
            return "DEL";
        }
        return null;
    }

    private LoanPickResult tryPickLoanPlayer(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            String preferredPosition,
            Random rng
    ) throws SQLException {
        return tryPickLoanPlayer(
                conn,
                header,
                idLigaEquipoDestino,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                rng,
                false
        );
    }

    private LoanPickResult tryPickLoanPlayer(
            Connection conn,
            MatchHeader header,
            long idLigaEquipoDestino,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            String preferredPosition,
            Random rng,
            boolean strictPreferredPosition
    ) throws SQLException {
        return tryPickLoanPlayer(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                rng,
                strictPreferredPosition
        );
    }

    /**
     * @param strictPreferredPosition si true (titulares), no se reintenta sin filtro de posición
     */
    private LoanPickResult tryPickLoanPlayer(
            Connection conn,
            MatchHeader header,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            String preferredPosition,
            Random rng,
            boolean strictPreferredPosition
    ) throws SQLException {
        boolean allowAnyPositionFallback = !strictPreferredPosition
                || preferredPosition == null
                || preferredPosition.isBlank();

        // 1) Preferimos jugadores que no estén ya en alineaciones de otros partidos de la jornada.
        LoanPickResult neutral = queryLoanCandidates(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                true,
                true,
                rng,
                allowAnyPositionFallback
        );
        if (neutral != null) {
            return neutral;
        }
        LoanPickResult anyClubButFreeRound = queryLoanCandidates(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                false,
                true,
                rng,
                allowAnyPositionFallback
        );
        if (anyClubButFreeRound != null) {
            return anyClubButFreeRound;
        }

        // 2) Fallback: permitimos jugadores ocupados en otros partidos de la jornada.
        LoanPickResult neutralEvenIfBusy = queryLoanCandidates(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                true,
                false,
                rng,
                allowAnyPositionFallback
        );
        if (neutralEvenIfBusy != null) {
            return neutralEvenIfBusy;
        }

        LoanPickResult finalFallback = queryLoanCandidates(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                false,
                false,
                rng,
                allowAnyPositionFallback
        );
        if (finalFallback == null) {
            log.warn(
                    "Sin candidatos de cesión para partido={}, pos={}, destinoEquipo={}, reservados={}, ocupadosJornada={}, estricto={}",
                    header.idPartido(),
                    preferredPosition,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds.size(),
                    busyThisRound.size(),
                    strictPreferredPosition
            );
        }
        return finalFallback;
    }

    private LoanPickResult queryLoanCandidates(
            Connection conn,
            MatchHeader header,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            String preferredPosition,
            boolean restrictToNeutralClubs,
            boolean avoidBusyThisRound,
            Random rng
    ) throws SQLException {
        return queryLoanCandidates(
                conn,
                header,
                idEquipoDestinoCatalog,
                reservedPlayerIds,
                busyThisRound,
                preferredPosition,
                restrictToNeutralClubs,
                avoidBusyThisRound,
                rng,
                true
        );
    }

    private LoanPickResult queryLoanCandidates(
            Connection conn,
            MatchHeader header,
            long idEquipoDestinoCatalog,
            Set<Long> reservedPlayerIds,
            Set<Long> busyThisRound,
            String preferredPosition,
            boolean restrictToNeutralClubs,
            boolean avoidBusyThisRound,
            Random rng,
            boolean allowAnyPositionFallback
    ) throws SQLException {
        Set<Long> exclude = new HashSet<>(reservedPlayerIds);
        if (avoidBusyThisRound) {
            exclude.addAll(busyThisRound);
        }

        Long idTemporada = loadLeagueSeasonId(conn, header.idLiga());
        if (idTemporada == null) {
            return null;
        }

        StringBuilder sql = new StringBuilder(
                """
                SELECT jct.id AS id_jugador_cedido_temporada,
                       jct.id_equipo_cedidos_temporada,
                       jct.nombre,
                       jct.pila,
                       jct.posicion,
                       jct.valoracion,
                       jct.foto
                FROM jugadores_cedidos_temporada jct
                INNER JOIN equipos_cedidos_temporada ect ON ect.id = jct.id_equipo_cedidos_temporada
                WHERE ect.id_temporada = ?
                  AND ect.activo = 1
                  AND jct.activo = 1
                """
        );

        if (preferredPosition != null && !preferredPosition.isBlank()) {
            sql.append(" AND jct.posicion = ? ");
        }

        if (!exclude.isEmpty()) {
            sql.append(" AND (-jct.id) NOT IN (");
            for (int i = 0; i < exclude.size(); i++) {
                if (i > 0) {
                    sql.append(", ");
                }
                sql.append("?");
            }
            sql.append(") ");
        }

        sql.append(
                """
                ORDER BY jct.valoracion DESC, jct.nombre ASC, jct.id ASC
                LIMIT 40
                """
        );

        List<LoanPickResult> buffer = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            ps.setLong(idx++, idTemporada);
            if (preferredPosition != null && !preferredPosition.isBlank()) {
                ps.setString(idx++, preferredPosition);
            }
            for (Long ex : exclude) {
                ps.setLong(idx++, ex);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idCed = rs.getLong("id_jugador_cedido_temporada");
                    long syntheticLeaguePlayerId = -idCed;
                    double currentRating = rs.getDouble("valoracion");
                    double recentAverage = 0.0;
                    double seasonAverage = 0.0;
                    int cansancio = 0;
                    String estado = "DISPONIBLE";
                    double selectionScore = calculateSelectionScore(
                            currentRating,
                            recentAverage,
                            seasonAverage,
                            cansancio,
                            estado
                    );

                    TeamPlayerData player = new TeamPlayerData(
                            syntheticLeaguePlayerId,
                            null,
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            rs.getString("posicion"),
                            currentRating,
                            estado,
                            cansancio,
                            0L,
                            recentAverage,
                            seasonAverage,
                            selectionScore,
                            true,
                            PLAYER_ORIGIN_EXCLUSIVE_LOAN,
                            rs.getInt("id_jugador_cedido_temporada"),
                            rs.getInt("id_equipo_cedidos_temporada"),
                            rs.getString("foto")
                    );

                    buffer.add(new LoanPickResult(
                            player,
                            null,
                            rs.getInt("id_equipo_cedidos_temporada")
                    ));
                }
            }
        }

        if (allowAnyPositionFallback
                && buffer.isEmpty()
                && preferredPosition != null
                && !preferredPosition.isBlank()) {
            return queryLoanCandidates(
                    conn,
                    header,
                    idEquipoDestinoCatalog,
                    reservedPlayerIds,
                    busyThisRound,
                    null,
                    restrictToNeutralClubs,
                    avoidBusyThisRound,
                    rng,
                    false
            );
        }

        if (buffer.isEmpty()) {
            return null;
        }

        return buffer.get(rng.nextInt(buffer.size()));
    }

    private List<SimulatedEvent> buildLoanChronologyPrefixEvents(Connection conn, MatchHeader header)
            throws SQLException {
        String sql = """
                SELECT led.id AS id_liga_equipo_destino,
                       ed.nombre AS nombre_equipo_destino,
                       pc.id_liga_jugador,
                       pc.id_jugador_cedido_temporada,
                       COALESCE(
                           NULLIF(jct.pila, ''),
                           jct.nombre,
                           NULLIF(j.pila, ''),
                           j.nombre
                       ) AS nombre_jugador
                FROM partido_cesiones pc
                INNER JOIN liga_equipos led ON led.id = pc.id_liga_equipo_destino
                INNER JOIN equipos ed ON ed.id = led.id_equipo
                LEFT JOIN liga_jugadores lj ON lj.id = pc.id_liga_jugador
                LEFT JOIN jugadores j ON j.id = lj.id_jugador
                LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = pc.id_jugador_cedido_temporada
                WHERE pc.id_partido_jornada = ?
                ORDER BY led.id ASC, nombre_jugador ASC, pc.id ASC
                """;

        List<SimulatedEvent> events = new ArrayList<>();
        LinkedHashMap<Long, LoanChronologyTeamGroup> groups = new LinkedHashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, header.idPartido());

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long teamId = rs.getLong("id_liga_equipo_destino");
                    LoanChronologyTeamGroup group = groups.get(teamId);
                    if (group == null) {
                        group = new LoanChronologyTeamGroup(
                                teamId,
                                rs.getString("nombre_equipo_destino"),
                                new ArrayList<>()
                        );
                        groups.put(teamId, group);
                    }
                    group.players().add(new LoanChronologyPlayerRow(
                            rs.getObject("id_liga_jugador", Long.class),
                            rs.getObject("id_jugador_cedido_temporada", Integer.class),
                            rs.getString("nombre_jugador")
                    ));
                }
            }
        }

        int segundo = 0;
        for (LoanChronologyTeamGroup group : groups.values()) {
            if (group.players().isEmpty()) {
                continue;
            }
            String jugadores = group.players().stream()
                    .map(LoanChronologyPlayerRow::nombreJugador)
                    .collect(Collectors.joining(", "));

            String generalText = group.nombreEquipoDestino()
                    + " recibe "
                    + group.players().size()
                    + " jugadores cedidos para este partido: "
                    + jugadores
                    + ". Estos jugadores no acumularán cansancio, no contarán para los puntos de esta jornada "
                    + "y no podrán lesionarse. Si reciben roja, solo serán expulsados de este partido y no "
                    + "afectará a su equipo original.";

            events.add(new SimulatedEvent(
                    0,
                    segundo++,
                    "CESIONES_PARTIDO",
                    0,
                    null,
                    null,
                    generalText
            ));

            for (LoanChronologyPlayerRow player : group.players()) {
                String individualText = player.nombreJugador()
                        + " ha sido cedido a "
                        + group.nombreEquipoDestino()
                        + " para este partido";
                events.add(new SimulatedEvent(
                        0,
                        segundo++,
                        "CESION_PARTIDO",
                        0,
                        player.idLigaJugador(),
                        null,
                        player.idJugadorCedidoTemporada(),
                        null,
                        individualText
                ));
            }
        }

        return events;
    }

    private static String buildPlayerDisplayNameFromParts(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        return nombre == null ? "" : nombre;
    }

    public int finalizeDueMatches() throws SQLException {
    List<DueMatchRef> dueMatches = loadMatchesReadyToFinalize();
    int finalized = 0;

    for (DueMatchRef dueMatch : dueMatches) {
        if (!leagueAutomationProperties.isLeagueAllowed(dueMatch.idLiga())) {
            continue;
        }
        try {
            finalizeMatchInternal(dueMatch.idLiga(), dueMatch.idPartido(), false);
            finalized++;
        } catch (IllegalArgumentException ignored) {
        }
    }

    return finalized;
}

    private List<DueMatchRef> loadMatchesReadyToFinalize() throws SQLException {
    try (Connection conn = DBConnection.getConnection()) {
        String sql = """
                SELECT j.id_liga,
                       pj.id AS id_partido
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE pj.estado = 'EN_JUEGO'
                  AND pj.inicio_en IS NOT NULL
                  AND pj.inicio_en <= DATE_SUB(NOW(), INTERVAL 90 MINUTE)
                ORDER BY pj.inicio_en ASC, pj.id ASC
                """;

        List<DueMatchRef> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                rows.add(new DueMatchRef(
                        rs.getLong("id_liga"),
                        rs.getLong("id_partido")
                ));
            }
        }

        return rows;
    }
}

/**
 * Tras una simulación que ya persistió {@code equipos_partido}, eventos y efectos pendientes:
 * actualiza {@code partidos_jornada}, aplica fatiga/lesiones, clasificación, valoraciones y fantasy.
 */
private void applyFullMatchFinalization(
        Connection conn,
        MatchHeader header,
        int golesLocal,
        int golesVisitante
) throws SQLException {
    Long idEquipoGanador = null;
    boolean empate = false;
    if (golesLocal > golesVisitante) {
        idEquipoGanador = header.idEquipoLocal();
    } else if (golesVisitante > golesLocal) {
        idEquipoGanador = header.idEquipoVisitante();
    } else {
        empate = true;
    }

    finalizeMatch(conn, header.idPartido(), golesLocal, golesVisitante, idEquipoGanador, empate);
    applyPendingPlayerEffects(conn, header.idPartido());
    updateLeagueTable(conn, header, golesLocal, golesVisitante, empate);
    updateDynamicRatingsAndValuesForMatch(conn, header.idPartido());
    leagueLineupService.recalculateParticipantPoints(conn, header.idLiga());
    updateRoundStatus(conn, header.idJornada());
}

private void finalizeMatchInternal(Long idLiga, Long idPartido, boolean bypassKickoffWindow) throws SQLException {
    if (idLiga == null || idPartido == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);

        try {
            MatchHeader header = lockMatchHeader(conn, idLiga, idPartido);

            if (header == null) {
                throw new IllegalArgumentException("Partido no encontrado");
            }

            if (!"EN_JUEGO".equals(header.estado())) {
                throw new IllegalArgumentException("El partido no está pendiente de finalización");
            }

            ScoreRow finalScore = loadFinalScoreFromTeamRows(conn, header.idPartido());
            if (finalScore == null) {
                throw new IllegalArgumentException("No existen artefactos simulados para finalizar el partido");
            }

            Instant now = Instant.now();

            if (!bypassKickoffWindow
                    && header.inicioEn() != null
                    && header.inicioEn().isAfter(now.minus(90, ChronoUnit.MINUTES))) {
                throw new IllegalArgumentException("El partido todavía no ha terminado visualmente");
            }

            applyFullMatchFinalization(conn, header, finalScore.golesLocal(), finalScore.golesVisitante());

            conn.commit();

            try {
                leagueStarterProbabilityService.recalculateForMatch(idLiga, idPartido);
            } catch (SQLException ex) {
                log.warn(
                        "No se pudieron recalcular probabilidades de titular tras finalizar partido {}: {}",
                        idPartido,
                        ex.getMessage());
            }

            postCommitRoundFantasyRewards(header.idLiga(), header.idJornada());
        } catch (Exception e) {
            conn.rollback();

            if (e instanceof IllegalArgumentException illegalArgumentException) {
                throw illegalArgumentException;
            }

            if (e instanceof SQLException sqlException) {
                throw sqlException;
            }

            throw new SQLException("Error finalizando partido: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }
}

/**
 * Reintento manual de premios de jornada (fichas + dinero) cuando la jornada ya quedó cerrada pero el pago
 * post-commit falló (idempotente).
 */
public void payoutFinalizedRoundRewardsIfDue(Long idLiga, Long idJornada) {
    postCommitRoundFantasyRewards(idLiga, idJornada);
}

private void postCommitRoundFantasyRewards(Long idLiga, Long idJornada) {
    if (idLiga == null || idJornada == null) {
        return;
    }
    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);
        try {
            List<LeagueRewardService.PendingRoundRewardPush> pendingRewards =
                    leagueRewardService.rewardFinalizedRound(conn, idLiga, idJornada);
            conn.commit();
            leagueRewardService.deliverRoundRewardPushNotifications(pendingRewards);
        } catch (Exception e) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                log.warn("Rollback de premios de jornada falló: {}", ex.getMessage());
            }
            log.warn(
                    "Premios de jornada no aplicados (se reintentará al cerrar otra vez la jornada). liga={}, jornada={}",
                    idLiga,
                    idJornada,
                    e
            );
        } finally {
            conn.setAutoCommit(true);
        }
    } catch (SQLException e) {
        log.warn("No se pudo abrir conexión para premios de jornada. liga={}, jornada={}: {}", idLiga, idJornada, e.getMessage());
    }
}

private void upsertPendingPlayerEffects(
        Connection conn,
        Long idPartido,
        List<PlayerAvailabilityChange> availabilityChanges,
        RuntimeTeamState localState,
        RuntimeTeamState awayState
) throws SQLException {
    Map<Long, PendingPlayerEffect> effects = new HashMap<>();

    collectPendingFatigueEffects(effects, localState);
    collectPendingFatigueEffects(effects, awayState);

    for (PlayerAvailabilityChange change : availabilityChanges) {
        if (localState.loanedPlayerIds.contains(change.idLigaJugador())
                || awayState.loanedPlayerIds.contains(change.idLigaJugador())) {
            continue;
        }
        PendingPlayerEffect current = effects.get(change.idLigaJugador());

        Integer cansancioFinal = current == null ? null : current.cansancioFinal();
        effects.put(
                change.idLigaJugador(),
                new PendingPlayerEffect(
                        change.idLigaJugador(),
                        cansancioFinal,
                        change.estado(),
                        change.lesionadoHasta(),
                        change.sancionadoHasta()
                )
        );
    }

    if (effects.isEmpty()) {
        return;
    }

    String sql = """
            INSERT INTO partido_efectos_jugador (
                id_partido_jornada,
                id_liga_jugador,
                cansancio_final,
                estado_final,
                lesionado_hasta,
                sancionado_hasta
            )
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                cansancio_final = VALUES(cansancio_final),
                estado_final = VALUES(estado_final),
                lesionado_hasta = VALUES(lesionado_hasta),
                sancionado_hasta = VALUES(sancionado_hasta)
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        for (PendingPlayerEffect effect : effects.values()) {
            ps.setLong(1, idPartido);
            ps.setLong(2, effect.idLigaJugador());

            if (effect.cansancioFinal() == null) {
                ps.setNull(3, Types.INTEGER);
            } else {
                ps.setInt(3, effect.cansancioFinal());
            }

            if (effect.estadoFinal() == null) {
                ps.setNull(4, Types.VARCHAR);
            } else {
                ps.setString(4, effect.estadoFinal());
            }

            if (effect.lesionadoHasta() == null) {
                ps.setNull(5, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, Timestamp.from(effect.lesionadoHasta()));
            }

            if (effect.sancionadoHasta() == null) {
                ps.setNull(6, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(6, Timestamp.from(effect.sancionadoHasta()));
            }

            ps.addBatch();
        }

        ps.executeBatch();
    }
}

private void collectPendingFatigueEffects(Map<Long, PendingPlayerEffect> effects, RuntimeTeamState state) {
    for (PlayerMatchAccumulator acc : state.accumulators.values()) {
        if (state.loanedPlayerIds.contains(acc.idLigaJugador)) {
            continue;
        }
        int fatigueIncrease = calculateFatigueIncrease(acc);
        int finalFatigue = Math.min(100, acc.initialCansancio + fatigueIncrease);

        PendingPlayerEffect current = effects.get(acc.idLigaJugador);

        effects.put(
                acc.idLigaJugador,
                new PendingPlayerEffect(
                        acc.idLigaJugador,
                        finalFatigue,
                        current == null ? null : current.estadoFinal(),
                        current == null ? null : current.lesionadoHasta(),
                        current == null ? null : current.sancionadoHasta()
                )
        );
    }
}

private void applyPendingPlayerEffects(Connection conn, Long idPartido) throws SQLException {
    Long idLiga = loadLeagueIdForMatch(conn, idPartido);

    String sql = """
            SELECT id_liga_jugador,
                   cansancio_final,
                   estado_final,
                   lesionado_hasta,
                   sancionado_hasta
            FROM partido_efectos_jugador
            WHERE id_partido_jornada = ?
            ORDER BY id_liga_jugador ASC
            """;

    List<PendingPlayerEffect> effects = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Integer cansancioFinal = rs.getInt("cansancio_final");
                if (rs.wasNull()) {
                    cansancioFinal = null;
                }

                Timestamp lesionTs = rs.getTimestamp("lesionado_hasta");
                Instant lesionadoHasta = lesionTs == null ? null : lesionTs.toInstant();

                Timestamp sanctionTs = rs.getTimestamp("sancionado_hasta");
                Instant sancionadoHasta = sanctionTs == null ? null : sanctionTs.toInstant();

                effects.add(new PendingPlayerEffect(
                        rs.getLong("id_liga_jugador"),
                        cansancioFinal,
                        rs.getString("estado_final"),
                        lesionadoHasta,
                        sancionadoHasta
                ));
            }
        }
    }

    if (effects.isEmpty()) {
        return;
    }

    String fatigueOnlySql = """
            UPDATE liga_jugadores
            SET cansancio = LEAST(100, ?)
            WHERE id = ?
            """;

    String fullSql = """
            UPDATE liga_jugadores
            SET cansancio = LEAST(100, ?),
                estado = ?,
                lesionado_hasta = ?,
                sancionado_hasta = ?
            WHERE id = ?
            """;

    for (PendingPlayerEffect effect : effects) {
        if (effect.estadoFinal() == null) {
            try (PreparedStatement ps = conn.prepareStatement(fatigueOnlySql)) {
                ps.setInt(1, effect.cansancioFinal() == null ? 0 : effect.cansancioFinal());
                ps.setLong(2, effect.idLigaJugador());
                ps.executeUpdate();
            }
        } else {
            try (PreparedStatement ps = conn.prepareStatement(fullSql)) {
                ps.setInt(1, effect.cansancioFinal() == null ? 0 : effect.cansancioFinal());
                ps.setString(2, effect.estadoFinal());

                if (effect.lesionadoHasta() == null) {
                    ps.setNull(3, Types.TIMESTAMP);
                } else {
                    ps.setTimestamp(3, Timestamp.from(effect.lesionadoHasta()));
                }

                if (effect.sancionadoHasta() == null) {
                    ps.setNull(4, Types.TIMESTAMP);
                } else {
                    ps.setTimestamp(4, Timestamp.from(effect.sancionadoHasta()));
                }

                ps.setLong(5, effect.idLigaJugador());
                ps.executeUpdate();
            }
            if (idLiga != null && lineupAvailabilityNotificationService != null) {
                lineupAvailabilityNotificationService.notifyLineupOwnersAfterFinalization(
                        conn,
                        idLiga,
                        idPartido,
                        effect.idLigaJugador(),
                        effect.estadoFinal()
                );
            }
        }
    }

    deletePendingPlayerEffects(conn, idPartido);
}

private Long loadLeagueIdForMatch(Connection conn, Long idPartido) throws SQLException {
    String sql = """
            SELECT jo.id_liga
            FROM partidos_jornada pj
            INNER JOIN jornadas jo ON jo.id = pj.id_jornada
            WHERE pj.id = ?
            LIMIT 1
            """;
    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);
        try (ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong("id_liga") : null;
        }
    }
}

private void deletePendingPlayerEffects(Connection conn, Long idPartido) throws SQLException {
    String sql = """
            DELETE FROM partido_efectos_jugador
            WHERE id_partido_jornada = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);
        ps.executeUpdate();
    }
}

private record PendingPlayerEffect(
        Long idLigaJugador,
        Integer cansancioFinal,
        String estadoFinal,
        Instant lesionadoHasta,
        Instant sancionadoHasta
) {}    

public int finalizeDueMatchesNow() throws SQLException {
    return finalizeDueMatches();
}

public void finalizeMatchNow(Long idLiga, Long idPartido) throws SQLException {
    finalizeMatchInternal(idLiga, idPartido, true);
}

/**
 * Repara partidos en {@code EN_JUEGO} con simulación ya escrita (evento FINAL, cronología hasta el 90 y
 * {@code jugadores_puntos_jornada} de la jornada). Reconcilia goles en {@code equipos_partido} desde {@code goles}
 * cuando hay discrepancias y vuelve a ejecutar la finalización administrativa (clasificación, cierre de jornada,
 * premios idempotentes).
 */
public LeagueSimulationRepairResponse repairStuckMatchesSimulatedWithFinalEvent() throws SQLException {
    List<DueMatchRef> targets = loadStuckMatchesSimulatedWithFinalEvent();
    int finalizados = 0;
    int errores = 0;

    for (DueMatchRef target : targets) {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                reconcileEquiposPartidoScoresFromGolesTable(conn, target.idLiga(), target.idPartido());
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                log.warn("Repair: reconciliación de marcador omitida partido={}: {}", target.idPartido(), e.getMessage());
            } finally {
                conn.setAutoCommit(true);
            }
        }

        try {
            finalizeMatchInternal(target.idLiga(), target.idPartido(), true);
            finalizados++;
        } catch (Exception e) {
            errores++;
            log.warn("Repair: finalización fallida partido={}: {}", target.idPartido(), e.getMessage());
        }
    }

    return new LeagueSimulationRepairResponse(targets.size(), finalizados, errores);
}

private List<DueMatchRef> loadStuckMatchesSimulatedWithFinalEvent() throws SQLException {
    try (Connection conn = DBConnection.getConnection()) {
        String sql = """
                SELECT j.id_liga,
                       pj.id AS id_partido
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE pj.estado = 'EN_JUEGO'
                  AND EXISTS (
                      SELECT 1
                      FROM partido_eventos e
                      WHERE e.id_partido_jornada = pj.id
                        AND e.tipo = 'FINAL'
                  )
                  AND COALESCE(
                      (SELECT MAX(e2.minuto) FROM partido_eventos e2 WHERE e2.id_partido_jornada = pj.id),
                      0
                  ) >= 90
                  AND EXISTS (
                      SELECT 1
                      FROM jugadores_puntos_jornada jpj
                      WHERE jpj.id_jornada = pj.id_jornada
                  )
                ORDER BY pj.id ASC
                """;

        List<DueMatchRef> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                rows.add(new DueMatchRef(
                        rs.getLong("id_liga"),
                        rs.getLong("id_partido")
                ));
            }
        }

        return rows;
    }
}

private void reconcileEquiposPartidoScoresFromGolesTable(Connection conn, Long idLiga, Long idPartido)
        throws SQLException {
    String countSql = """
            SELECT le.id AS id_liga_equipo, COUNT(*) AS goles
            FROM goles g
            INNER JOIN liga_jugadores lj ON lj.id = g.id_liga_jugador
            INNER JOIN liga_equipos le ON le.id_liga = lj.id_liga AND le.id_equipo = lj.id_equipo
            WHERE g.id_partido_jornada = ?
              AND lj.id_liga = ?
            GROUP BY le.id
            """;

    Map<Long, Integer> goalsByTeam = new HashMap<>();
    try (PreparedStatement ps = conn.prepareStatement(countSql)) {
        ps.setLong(1, idPartido);
        ps.setLong(2, idLiga);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                goalsByTeam.put(rs.getLong("id_liga_equipo"), rs.getInt("goles"));
            }
        }
    }

    if (goalsByTeam.isEmpty()) {
        return;
    }

    String updateSql = """
            UPDATE equipos_partido
            SET goles = ?
            WHERE id_partido_jornada = ?
              AND id_liga_equipo = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
        for (Map.Entry<Long, Integer> entry : goalsByTeam.entrySet()) {
            ps.setInt(1, entry.getValue());
            ps.setLong(2, idPartido);
            ps.setLong(3, entry.getKey());
            ps.addBatch();
        }
        ps.executeBatch();
    }
}

private ScoreRow loadFinalScoreFromTeamRows(Connection conn, Long idPartido) throws SQLException {
    String sql = """
            SELECT es_local, goles
            FROM equipos_partido
            WHERE id_partido_jornada = ?
            ORDER BY es_local DESC
            """;

    Integer golesLocal = null;
    Integer golesVisitante = null;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                boolean esLocal = rs.getBoolean("es_local");
                int goles = rs.getInt("goles");

                if (esLocal) {
                    golesLocal = goles;
                } else {
                    golesVisitante = goles;
                }
            }
        }
    }

    if (golesLocal == null || golesVisitante == null) {
        return null;
    }

    return new ScoreRow(golesLocal, golesVisitante);
}

/** Por encima del par, cada punto extra influye más que el anterior (no es lineal en puntos). */
private static final double FANTASY_PERF_RATIO_EXPONENT_ABOVE_PAR = 1.30;
/** Por debajo del par, ligera penalización algo más suave que exponencial fuerte. */
private static final double FANTASY_PERF_RATIO_EXPONENT_BELOW_PAR = 1.06;
private static final double FANTASY_PERF_INDEX_CAP = 20.0;

/**
 * Índice de rendimiento solo por fantasy: media de los últimos hasta 3 partidos del jugador en la liga
 * ({@link ProgressionSnapshot#recentAverage()}, AVG sobre las últimas jornadas con registro) frente al
 * par de puntos esperado por su precio actual ({@link LeagueDynamicValuePolicy#fantasyParMeanPointsFromMarket}). Escala ~10 = neutro.
 * Si la media iguala el par, ratio=1 → índice 10; por encima del par el índice sube en curva convexa respecto a los puntos.
 */
private double computeBasePerformanceIndex(ProgressionSnapshot snapshot) {
    double avgPts = snapshot.recentAverage();
    double par = LeagueDynamicValuePolicy.fantasyParMeanPointsFromMarket(snapshot.currentValue());
    if (par < 0.5) {
        par = 5.0;
    }
    double ratio = avgPts / par;
    double index;
    if (ratio >= 1.0) {
        index = 10.0 * Math.pow(ratio, FANTASY_PERF_RATIO_EXPONENT_ABOVE_PAR);
    } else {
        index = 10.0 * Math.pow(ratio, FANTASY_PERF_RATIO_EXPONENT_BELOW_PAR);
    }
    return clamp(index, 0.0, FANTASY_PERF_INDEX_CAP);
}

/**
 * Misma fórmula que al cerrar partido: índice por media fantasy reciente vs par de mercado y movimiento acotado del valor.
 *
 * @param latestPoints / latestMinutes referencia del último partido relevante (en finalize viene del JP del partido cerrado).
 */
private void applyDynamicRatingCore(
        Connection conn,
        ProgressionSnapshot snapshot,
        int latestPoints,
        int latestMinutes
) throws SQLException {
    applyDynamicRatingCoreWithPerformanceIndex(
            conn,
            snapshot,
            latestPoints,
            latestMinutes,
            computeBasePerformanceIndex(snapshot),
            false);
}

/**
 * @param gateUntilTeamHasFinalizedMatch Si es true (solo batch nocturno): no modifica {@code valor} mientras el
 *                                       equipo de catálogo del jugador en esa liga no haya disputado ningún
 *                                       partido {@code FINALIZADO}. Al cerrar partido se pasa false para no
 *                                       bloquear titulares/suplentes con minutos (incl. cesiones).
 * @return {@code true} si se ejecutó la actualización en BD; {@code false} si el gate evitó tocar el jugador.
 */
private boolean applyDynamicRatingCoreWithPerformanceIndex(
        Connection conn,
        ProgressionSnapshot snapshot,
        int latestPoints,
        int latestMinutes,
        double performanceIndex,
        boolean gateUntilTeamHasFinalizedMatch
) throws SQLException {
    Long idLigaJugador = snapshot.idLigaJugador();

    if (gateUntilTeamHasFinalizedMatch) {
        LigaJugadorLigaEquipoRow metaGate = loadLigaJugadorLigaEquipoRow(conn, idLigaJugador);
        if (metaGate == null
                || !teamHasAtLeastOneFinalizedMatch(conn, metaGate.idLiga(), metaGate.idCatalogEquipo())) {
            return false;
        }
    }

    long persistedPreviousValue = snapshot.currentValue();
    double persistedPreviousRating = snapshot.currentRating();

    performanceIndex = clampAvailabilityPerformanceIndex(performanceIndex, snapshot.estadoLiga());

    double expectedIndex = 10.0;
    double sensitivity = LeagueDynamicValuePolicy.sensitivityByMarketProfile(
            snapshot.currentValue(),
            snapshot.currentRating()
    );
    double maxUp = LeagueDynamicValuePolicy.maxPositiveDeltaRatingByOvr(
            snapshot.currentRating(),
            snapshot.currentValue()
    );

    double deltaRating =
            clamp((performanceIndex - expectedIndex) * sensitivity, -0.40, maxUp);
    deltaRating = LeagueDynamicValuePolicy.boostPositiveDeltaRating(
            deltaRating,
            maxUp,
            snapshot.currentValue()
    );
    double fantasyRating = round2(clamp(snapshot.currentRating() + deltaRating, 60.0, 99.0));

    long theoreticalValue = pricingService.calculateValueFromDynamicRating(fantasyRating, snapshot.position());
    long targetValue = Math.round(
            theoreticalValue * LeagueDynamicValuePolicy.formMultiplier(performanceIndex, snapshot.currentValue())
    );

    boolean valueRising = targetValue > persistedPreviousValue;
    long newValue = LeagueDynamicValuePolicy.moveTowards(
            persistedPreviousValue,
            targetValue,
            LeagueDynamicValuePolicy.movementLimitPercentage(persistedPreviousValue, valueRising)
    );

    boolean skipProtectiveGuards = skipValueProtectiveGuards(snapshot, latestPoints, latestMinutes);

    if (!skipProtectiveGuards && latestPoints >= 10 && latestMinutes >= 60) {
        if (newValue < snapshot.currentValue()) {
            newValue = snapshot.currentValue();
        }
    } else if (!skipProtectiveGuards
            && latestPoints >= 7
            && latestMinutes >= 60
            && newValue < snapshot.currentValue()) {
        long maxDropByPercent = Math.round(snapshot.currentValue() * 0.0025);
        long maxDrop = Math.min(maxDropByPercent, 150_000L);
        long minAllowedValue = snapshot.currentValue() - maxDrop;
        if (newValue < minAllowedValue) {
            newValue = minAllowedValue;
        }
    }

    if (!skipProtectiveGuards
            && persistedPreviousValue < 2_000_000L
            && latestMinutes >= 60
            && latestPoints >= 3) {
        if (newValue < persistedPreviousValue) {
            newValue = persistedPreviousValue;
        }
    } else if (!skipProtectiveGuards
            && persistedPreviousValue < 5_000_000L
            && latestMinutes >= 60
            && latestPoints >= 3) {
        if (newValue < persistedPreviousValue) {
            newValue = persistedPreviousValue;
        }
    } else if (!skipProtectiveGuards
            && persistedPreviousValue < 5_000_000L
            && latestMinutes >= 60
            && latestPoints == 2) {
        long minAllowedValue = Math.round(persistedPreviousValue * 0.9975);
        if (newValue < minAllowedValue) {
            newValue = minAllowedValue;
        }
    }

    if (!skipProtectiveGuards && latestPoints >= 10 && latestMinutes >= 60) {
        if (newValue < persistedPreviousValue) {
            newValue = persistedPreviousValue;
        }
    }
    if (!skipProtectiveGuards && latestPoints >= 7 && latestMinutes >= 60 && newValue < persistedPreviousValue) {
        long maxDropByPercent = Math.round(persistedPreviousValue * 0.0025);
        long maxDrop = Math.min(maxDropByPercent, 150_000L);
        long minAllowedValue = persistedPreviousValue - maxDrop;
        if (newValue < minAllowedValue) {
            newValue = minAllowedValue;
        }
    }

    if (isInjuredOrSanctionedLeagueState(snapshot.estadoLiga())) {
        long minDrop = Math.min(550_000L, Math.max(40_000L, Math.round(persistedPreviousValue * 0.0085)));
        long cappedValue = persistedPreviousValue - minDrop;
        newValue = Math.min(newValue, cappedValue);
    }

    long negPenalty =
            extraMarketLossFromNegativeFantasyPoints(persistedPreviousValue, latestPoints, latestMinutes);
    if (negPenalty > 0) {
        newValue = Math.max(LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE, newValue - negPenalty);
    }

    updatePlayerDynamicRow(
            conn,
            idLigaJugador,
            persistedPreviousValue,
            persistedPreviousRating,
            latestPoints,
            latestMinutes,
            newValue,
            snapshot.position());
    return true;
}

private void updateDynamicRatingsAndValuesForMatch(Connection conn, Long idPartido) throws SQLException {
    String sql = """
            SELECT DISTINCT ap.id_liga_jugador,
                            jp.puntos AS puntos_partido,
                            jp.minutos_jugados AS minutos_partido
            FROM alineacion_partido ap
            INNER JOIN partidos_jornada pj ON pj.id = ap.id_partido_jornada
            INNER JOIN jugadores_puntos_jornada jp
                ON jp.id_liga_jugador = ap.id_liga_jugador
               AND jp.id_jornada = pj.id_jornada
            LEFT JOIN partido_cesiones pc
                ON pc.id_partido_jornada = ap.id_partido_jornada
               AND pc.id_liga_jugador = ap.id_liga_jugador
               AND pc.id_liga_equipo_destino = ap.id_liga_equipo
            WHERE ap.id_partido_jornada = ?
              AND pc.id IS NULL
              AND jp.minutos_jugados > 0
            ORDER BY ap.id_liga_jugador ASC
            """;

    List<DynamicUpdateRow> rows = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idPartido);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new DynamicUpdateRow(
                        rs.getLong("id_liga_jugador"),
                        rs.getInt("puntos_partido"),
                        rs.getInt("minutos_partido")
                ));
            }
        }
    }

    for (DynamicUpdateRow row : rows) {
            ProgressionSnapshot snapshot = loadProgressionSnapshot(conn, row.idLigaJugador());

            if (snapshot == null) {
                continue;
            }

            applyDynamicRatingCore(conn, snapshot, row.latestPoints(), row.latestMinutes());
        }
}

    private PreparedRuntimeStates loadPreparedRuntimeStates(Connection conn, MatchHeader header) throws SQLException {
        String sql = """
                SELECT ap.id_liga_equipo,
                       ap.titular,
                       ap.tipo_origen_jugador,
                       ap.id_jugador_cedido_temporada,
                       ap.id_liga_jugador,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN NULL
                           ELSE j.id
                       END AS id_jugador,
                       COALESCE(jct.nombre, j.nombre) AS nombre,
                       COALESCE(jct.pila, j.pila) AS pila,
                       COALESCE(jct.posicion, j.posicion) AS posicion,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                               THEN jct.valoracion
                           ELSE COALESCE(lj.valoracion_actual, j.valoracion)
                       END AS valoracion_actual,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                               THEN 'DISPONIBLE'
                           ELSE lj.estado
                       END AS estado,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                               THEN 0
                           ELSE lj.cansancio
                       END AS cansancio,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                               THEN 0
                           ELSE lj.valor
                       END AS valor,
                       jct.foto AS foto_cedido,
                       pc.id_equipo_cedidos_temporada_origen,
                       COALESCE((
                           SELECT AVG(t.puntos)
                           FROM (
                               SELECT jp.puntos
                               FROM jugadores_puntos_jornada jp
                               WHERE jp.id_liga_jugador = ap.id_liga_jugador
                               ORDER BY jp.id_jornada DESC
                               LIMIT 3
                           ) t
                       ), 0) AS media_ultimos_3,
                       COALESCE((
                           SELECT AVG(jp2.puntos)
                           FROM jugadores_puntos_jornada jp2
                           WHERE jp2.id_liga_jugador = ap.id_liga_jugador
                       ), 0) AS media_temporada,
                       CASE WHEN pc.id IS NOT NULL THEN 1 ELSE 0 END AS es_cedido
                FROM alineacion_partido ap
                LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
                LEFT JOIN jugadores j ON j.id = lj.id_jugador
                LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
                LEFT JOIN partido_cesiones pc
                    ON pc.id_partido_jornada = ap.id_partido_jornada
                   AND pc.id_liga_equipo_destino = ap.id_liga_equipo
                   AND (
                         (ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' AND pc.id_jugador_cedido_temporada = ap.id_jugador_cedido_temporada)
                      OR (ap.tipo_origen_jugador <> 'CEDIDO_EXCLUSIVO' AND pc.id_liga_jugador = ap.id_liga_jugador)
                   )
                WHERE ap.id_partido_jornada = ?
                ORDER BY ap.id_liga_equipo ASC,
                         ap.titular DESC,
                         CASE COALESCE(jct.posicion, j.posicion)
                             WHEN 'POR' THEN 1
                             WHEN 'DEF' THEN 2
                             WHEN 'MED' THEN 3
                             WHEN 'DEL' THEN 4
                             ELSE 5
                         END,
                         CASE
                             WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                                 THEN jct.valoracion
                             ELSE COALESCE(lj.valoracion_actual, j.valoracion)
                         END DESC,
                         COALESCE(jct.nombre, j.nombre) ASC
                """;

        Set<Long> matchLoanedPlayerIds = new HashSet<>();

        RuntimeTeamState localState = new RuntimeTeamState(
                header.idLigaEquipoLocal(),
                header.idEquipoLocal(),
                header.nombreEquipoLocal(),
                true,
                matchLoanedPlayerIds
        );

        RuntimeTeamState awayState = new RuntimeTeamState(
                header.idLigaEquipoVisitante(),
                header.idEquipoVisitante(),
                header.nombreEquipoVisitante(),
                false,
                matchLoanedPlayerIds
        );

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, header.idPartido());

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    double currentRating = rs.getDouble("valoracion_actual");
                    double recentAverage = rs.getDouble("media_ultimos_3");
                    double seasonAverage = rs.getDouble("media_temporada");
                    int cansancio = rs.getInt("cansancio");
                    String estado = rs.getString("estado");

                    double selectionScore = calculateSelectionScore(
                            currentRating,
                            recentAverage,
                            seasonAverage,
                            cansancio,
                            estado
                    );

                    boolean esCedido = rs.getInt("es_cedido") == 1;
                    Integer idCed = rs.getObject("id_jugador_cedido_temporada", Integer.class);
                    Long idLigaJugador = rs.getObject("id_liga_jugador", Long.class);
                    if (idLigaJugador == null && PLAYER_ORIGIN_EXCLUSIVE_LOAN.equals(rs.getString("tipo_origen_jugador")) && idCed != null) {
                        idLigaJugador = -idCed.longValue();
                    }

                    TeamPlayerData player = new TeamPlayerData(
                            idLigaJugador,
                            rs.getObject("id_jugador", Long.class),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            rs.getString("posicion"),
                            currentRating,
                            estado,
                            cansancio,
                            rs.getLong("valor"),
                            recentAverage,
                            seasonAverage,
                            selectionScore,
                            esCedido,
                            rs.getString("tipo_origen_jugador"),
                            idCed,
                            rs.getObject("id_equipo_cedidos_temporada_origen", Integer.class),
                            rs.getString("foto_cedido")
                    );

                    long idLigaEquipo = rs.getLong("id_liga_equipo");
                    boolean titular = rs.getBoolean("titular");

                    RuntimeTeamState target = idLigaEquipo == header.idLigaEquipoLocal()
                            ? localState
                            : awayState;

                    if (esCedido) {
                        matchLoanedPlayerIds.add(player.idLigaJugador());
                    }

                    if (titular) {
                        target.starters.add(player);
                        target.activePlayers.add(player);

                        PlayerMatchAccumulator acc = target.ensureAccumulator(player);
                        acc.startMinute = 0;
                        acc.active = true;
                    } else {
                        target.bench.add(player);
                    }
                }
            }
        }

        if (localState.starters.size() < 11 || awayState.starters.size() < 11) {
            throw new IllegalArgumentException("Faltan alineaciones preparadas válidas para el partido");
        }

        return new PreparedRuntimeStates(localState, awayState);
    }

    private void markMatchInProgress(Connection conn, Long idJornada, Long idPartido) throws SQLException {
        String sqlMatch = """
                UPDATE partidos_jornada
                SET estado = 'EN_JUEGO'
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlMatch)) {
            ps.setLong(1, idPartido);
            ps.executeUpdate();
        }

        String sqlRound = """
                UPDATE jornadas
                SET estado = 'EN_CURSO'
                WHERE id = ?
                  AND estado = 'PENDIENTE'
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlRound)) {
            ps.setLong(1, idJornada);
            ps.executeUpdate();
        }
    }

    private MatchSimulationOutput simulateMatch(
            MatchHeader header,
            RuntimeTeamState localState,
            RuntimeTeamState awayState,
            Random rng,
            List<SimulatedEvent> loanChronologyPrefix
    ) {
        List<SimulatedEvent> events = new ArrayList<>();
        List<GoalRow> goals = new ArrayList<>();
        List<PlayerAvailabilityChange> availabilityChanges = new ArrayList<>();

        if (loanChronologyPrefix != null && !loanChronologyPrefix.isEmpty()) {
            events.addAll(loanChronologyPrefix);
        }

        events.add(new SimulatedEvent(0, 59, "INICIO", 0, null, null, "Comienza el partido"));

        Integer localInjuryMinute = rollChance(rng, 0.18) ? randomBetween(rng, 18, 78) : null;
        Integer awayInjuryMinute = rollChance(rng, 0.18) ? randomBetween(rng, 18, 78) : null;

        List<Integer> localTacticalSubMinutes = buildTacticalSubstitutionMinutes(localState, rng);
        List<Integer> awayTacticalSubMinutes = buildTacticalSubstitutionMinutes(awayState, rng);

        for (int minute = 1; minute <= FULL_MATCH_MINUTES; minute++) {
            if (minute == 45) {
                events.add(new SimulatedEvent(45, 0, "DESCANSO", 0, null, null, "Descanso"));
            }

            if (minute == 46) {
                events.add(new SimulatedEvent(46, 0, "INICIO_SEGUNDA_PARTE", 0, null, null, "Empieza la segunda parte"));
            }

            if (localInjuryMinute != null && localInjuryMinute == minute) {
                processInjury(minute, localState, availabilityChanges, events, header.inicioEn(), rng);
            }

            if (awayInjuryMinute != null && awayInjuryMinute == minute) {
                processInjury(minute, awayState, availabilityChanges, events, header.inicioEn(), rng);
            }

            if (localTacticalSubMinutes.contains(minute)) {
                processTacticalSubstitution(minute, localState, events, rng);
            }

            if (awayTacticalSubMinutes.contains(minute)) {
                processTacticalSubstitution(minute, awayState, events, rng);
            }

            if (rollChance(rng, RECOVERY_EVENT_CHANCE)) {
                processRecoveryEvent(minute, localState, awayState, events, rng);
            }

            if (rollChance(rng, ATTACK_SEQUENCE_CHANCE)) {
                processAttackSequence(minute, header, localState, awayState, availabilityChanges, events, goals, rng);
            }
        }

        finalizeMinutes(localState);
        finalizeMinutes(awayState);

        events.add(new SimulatedEvent(90, 0, "FINAL", 0, null, null, "Final del partido"));

        events.sort(Comparator
                .comparingInt(SimulatedEvent::minuto)
                .thenComparingInt(SimulatedEvent::segundo));

        return new MatchSimulationOutput(events, goals, availabilityChanges);
    }

    private void processRecoveryEvent(
            int minute,
            RuntimeTeamState localState,
            RuntimeTeamState awayState,
            List<SimulatedEvent> events,
            Random rng
    ) {
        RuntimeTeamState team = rollChance(rng, 0.5) ? localState : awayState;
        TeamPlayerData recoverer = pickWeightedRecoverer(team, rng);

        if (recoverer == null) {
            return;
        }

        PlayerMatchAccumulator acc = team.ensureAccumulator(recoverer);
        acc.recoveries++;

        events.add(new SimulatedEvent(
                minute,
                randomSecond(rng),
                "RECUPERACION",
                0,
                recoverer.idLigaJugador(),
                null,
                MatchEventCommentary.recovery(rng, buildPlayerName(recoverer))
        ));
    }

    private void processAttackSequence(
            int minute,
            MatchHeader header,
            RuntimeTeamState localState,
            RuntimeTeamState awayState,
            List<PlayerAvailabilityChange> availabilityChanges,
            List<SimulatedEvent> events,
            List<GoalRow> goals,
            Random rng
    ) {
        RuntimeTeamState attacking = pickAttackingTeam(localState, awayState, rng);
        RuntimeTeamState defending = attacking == localState ? awayState : localState;

        int roll = rng.nextInt(100);

        if (roll < 19) {
            TeamPlayerData dribbler = pickWeightedAttacker(attacking, rng);

            if (dribbler == null) {
                return;
            }

            PlayerMatchAccumulator acc = attacking.ensureAccumulator(dribbler);
            acc.dribbles++;

            events.add(new SimulatedEvent(
                    minute,
                    randomSecond(rng),
                    "REGATE",
                    0,
                    dribbler.idLigaJugador(),
                    null,
                    MatchEventCommentary.dribble(rng, buildPlayerName(dribbler))
            ));
            return;
        }

        if (roll < 34) {
            TeamPlayerData fouler = pickWeightedDefender(defending, rng);
            TeamPlayerData victim = pickWeightedAttacker(attacking, rng);

            if (fouler == null || victim == null) {
                return;
            }

            events.add(new SimulatedEvent(
                    minute,
                    randomSecond(rng),
                    "FALTA",
                    0,
                    fouler.idLigaJugador(),
                    victim.idLigaJugador(),
                    MatchEventCommentary.foul(rng, buildPlayerName(fouler), buildPlayerName(victim))
            ));

            if (rollChance(rng, 0.12)) {
                processRedCard(minute, defending, fouler, availabilityChanges, events, header.inicioEn(), rng);
            }

            return;
        }

        TeamPlayerData shooter = pickWeightedAttacker(attacking, rng);
        TeamPlayerData goalkeeper = defending.findCurrentGoalkeeper();

        if (shooter == null) {
            return;
        }

        PlayerMatchAccumulator shooterAcc = attacking.ensureAccumulator(shooter);
        shooterAcc.shots++;

        int second = randomSecond(rng);

        if (rollChance(rng, 0.35)) {
            events.add(new SimulatedEvent(
                    minute,
                    second,
                    "OCASION",
                    0,
                    shooter.idLigaJugador(),
                    null,
                    MatchEventCommentary.occasion(rng, buildPlayerName(shooter))
            ));
            second = Math.min(59, second + 3);
        }

        if (rollChance(rng, ATTACK_DUEL_EVENT_CHANCE)) {
            TeamPlayerData duelDribbler = pickWeightedAttacker(attacking, rng);
            if (duelDribbler != null) {
                PlayerMatchAccumulator duelAcc = attacking.ensureAccumulator(duelDribbler);
                duelAcc.dribbles++;
                events.add(new SimulatedEvent(
                        minute,
                        Math.max(0, second - 1),
                        "REGATE",
                        0,
                        duelDribbler.idLigaJugador(),
                        null,
                        MatchEventCommentary.dribble(rng, buildPlayerName(duelDribbler))
                ));
            }
        }

        double goalProbability = calculateGoalProbability(attacking, defending, shooter, goalkeeper);
        boolean isGoal = rollChance(rng, goalProbability);

        if (isGoal) {
            TeamPlayerData assistant = pickAssistant(attacking, shooter, rng);

            shooterAcc.goals++;
            attacking.goals++;

            applyConcededGoalToDefenders(defending);

            events.add(new SimulatedEvent(
                    minute,
                    Math.min(59, second + 1),
                    "GOL",
                    0,
                    shooter.idLigaJugador(),
                    assistant == null ? null : assistant.idLigaJugador(),
                    MatchEventCommentary.goal(rng, buildPlayerName(shooter), attacking.nombreEquipo)
            ));

            if (assistant != null) {
                PlayerMatchAccumulator assistAcc = attacking.ensureAccumulator(assistant);
                assistAcc.assists++;

                events.add(new SimulatedEvent(
                        minute,
                        Math.min(59, second + 2),
                        "ASISTENCIA",
                        0,
                        assistant.idLigaJugador(),
                        shooter.idLigaJugador(),
                        MatchEventCommentary.assist(rng, buildPlayerName(assistant), buildPlayerName(shooter))
                ));
            }

            goals.add(new GoalRow(shooter.idLigaJugador(), minute, false));
        } else {
            events.add(new SimulatedEvent(
                    minute,
                    second,
                    "DISPARO",
                    0,
                    shooter.idLigaJugador(),
                    null,
                    MatchEventCommentary.shot(rng, buildPlayerName(shooter))
            ));

            if (goalkeeper != null && rollChance(rng, saveEventChance(goalkeeper))) {
                PlayerMatchAccumulator gkAcc = defending.ensureAccumulator(goalkeeper);
                gkAcc.saves++;

                events.add(new SimulatedEvent(
                        minute,
                        Math.min(59, second + 2),
                        "PARADA",
                        0,
                        goalkeeper.idLigaJugador(),
                        shooter.idLigaJugador(),
                        MatchEventCommentary.save(rng, buildPlayerName(goalkeeper), buildPlayerName(shooter))
                ));
            }

            if (rollChance(rng, 0.47)) {
                TeamPlayerData recoverer = pickWeightedRecoverer(defending, rng);
                if (recoverer != null) {
                    PlayerMatchAccumulator recoverAcc = defending.ensureAccumulator(recoverer);
                    recoverAcc.recoveries++;
                    events.add(new SimulatedEvent(
                            minute,
                            Math.min(59, second + 1),
                            "RECUPERACION",
                            0,
                            recoverer.idLigaJugador(),
                            shooter.idLigaJugador(),
                            MatchEventCommentary.recoveryAfterShot(rng, buildPlayerName(recoverer))
                    ));
                }
            }
        }
    }

    private void processRedCard(
            int minute,
            RuntimeTeamState defending,
            TeamPlayerData fouler,
            List<PlayerAvailabilityChange> availabilityChanges,
            List<SimulatedEvent> events,
            Instant kickoff,
            Random rng
    ) {
        PlayerMatchAccumulator acc = defending.ensureAccumulator(fouler);
        acc.redCards++;
        acc.endMinute = minute;
        acc.active = false;

        defending.activePlayers.removeIf(p -> p.idLigaJugador().equals(fouler.idLigaJugador()));

        if (!fouler.loanedForMatch()) {
            Instant baseInstant = kickoff == null ? Instant.now() : kickoff;
            Instant until = baseInstant.plus(8, ChronoUnit.DAYS);

            availabilityChanges.add(new PlayerAvailabilityChange(
                    fouler.idLigaJugador(),
                    "SANCIONADO",
                    null,
                    until
            ));
        }

        events.add(new SimulatedEvent(
                minute,
                Math.min(59, randomSecond(rng) + 1),
                "TARJETA_ROJA",
                0,
                fouler.idLigaJugador(),
                null,
                MatchEventCommentary.redCard(rng, buildPlayerName(fouler))
        ));

        if ("POR".equals(fouler.posicion())) {
            reorganizeAfterGoalkeeperRedCard(minute, defending, fouler, events, rng);
        }
    }

    /**
     * Portero expulsado: intentar sustituir por suplente POR si hay cambios; si no, portero de emergencia en campo.
     * Jugadores de campo expulsados no tienen sustitución aquí (sigue igual).
     */
    private void reorganizeAfterGoalkeeperRedCard(
            int minute,
            RuntimeTeamState defending,
            TeamPlayerData expelledGoalkeeper,
            List<SimulatedEvent> events,
            Random rng
    ) {
        defending.clearActingGoalkeeper();

        int segundoReordenacion = Math.min(59, randomSecond(rng) + 2);

        TeamPlayerData benchGk = null;
        if (defending.substitutionsUsed < MAX_SUBSTITUTIONS) {
            List<TeamPlayerData> gksOnBench = collectBenchPlayersWithPosition(defending, "POR");
            benchGk = pickBestAmongBenchCandidates(gksOnBench, "POR");
        }

        if (benchGk != null) {
            TeamPlayerData sacrifice = pickOutfieldToSacrificeForGoalkeeperSwap(defending, minute);
            if (sacrifice != null) {
                defending.substitutionsUsed++;

                removePlayerFromBench(defending, benchGk);

                PlayerMatchAccumulator sacrificeAcc = defending.ensureAccumulator(sacrifice);
                sacrificeAcc.endMinute = minute;
                sacrificeAcc.active = false;
                defending.activePlayers.removeIf(p -> Objects.equals(p.idLigaJugador(), sacrifice.idLigaJugador()));

                defending.activePlayers.add(benchGk);

                PlayerMatchAccumulator incomingGkAcc = defending.ensureAccumulator(benchGk);
                incomingGkAcc.startMinute = minute;
                incomingGkAcc.active = true;

                events.add(new SimulatedEvent(
                        minute,
                        segundoReordenacion,
                        "CAMBIO",
                        0,
                        benchGk.idLigaJugador(),
                        sacrifice.idLigaJugador(),
                        MatchEventCommentary.goalkeeperSubAfterRed(
                                rng,
                                buildPlayerName(benchGk),
                                buildPlayerName(sacrifice),
                                defending.nombreEquipo
                        )
                ));
                return;
            }
        }

        List<TeamPlayerData> outfieldActive = collectActiveOutfieldPlayers(defending);
        TeamPlayerData emergencyGk = pickEmergencyOutfieldGoalkeeper(outfieldActive);
        if (emergencyGk != null) {
            defending.setActingGoalkeeper(emergencyGk.idLigaJugador());

            events.add(new SimulatedEvent(
                    minute,
                    segundoReordenacion,
                    "CAMBIO",
                    0,
                    emergencyGk.idLigaJugador(),
                    expelledGoalkeeper.idLigaJugador(),
                    MatchEventCommentary.emergencyGoalkeeper(
                            rng,
                            buildPlayerName(emergencyGk),
                            buildPlayerName(expelledGoalkeeper),
                            defending.nombreEquipo
                    )
            ));
        }
    }

    private List<TeamPlayerData> collectBenchPlayersWithPosition(RuntimeTeamState state, String posicion) {
        List<TeamPlayerData> out = new ArrayList<>();
        for (TeamPlayerData p : state.bench) {
            if (Objects.equals(posicion, p.posicion())) {
                out.add(p);
            }
        }
        return out;
    }

    private List<TeamPlayerData> collectActiveOutfieldPlayers(RuntimeTeamState state) {
        List<TeamPlayerData> out = new ArrayList<>();
        for (TeamPlayerData p : state.activePlayers) {
            if (!"POR".equals(p.posicion())) {
                out.add(p);
            }
        }
        return out;
    }

    /**
     * Peor jugador de campo en uso como víctima del cambio (entra el portero suplente), mismo espíritu que sustituir a los más necesitados.
     */
    private TeamPlayerData pickOutfieldToSacrificeForGoalkeeperSwap(RuntimeTeamState state, int minute) {
        List<TeamPlayerData> outfield = collectActiveOutfieldPlayers(state);
        if (outfield.isEmpty()) {
            return null;
        }

        TeamPlayerData worst = outfield.get(0);
        double worstNeed = substitutionNeedScoreLive(state, worst, minute);

        for (int i = 1; i < outfield.size(); i++) {
            TeamPlayerData p = outfield.get(i);
            double need = substitutionNeedScoreLive(state, p, minute);
            int cmp = Double.compare(need, worstNeed);
            if (cmp > 0) {
                worst = p;
                worstNeed = need;
            } else if (cmp == 0) {
                if (Double.compare(p.selectionScore(), worst.selectionScore()) < 0) {
                    worst = p;
                    worstNeed = need;
                } else if (Objects.equals(p.selectionScore(), worst.selectionScore())) {
                    int fc = Integer.compare(
                            liveEffectiveFatigue(state, p, minute),
                            liveEffectiveFatigue(state, worst, minute));
                    if (fc > 0) {
                        worst = p;
                        worstNeed = need;
                    }
                }
            }
        }

        return worst;
    }

    private void processInjury(
        int minute,
        RuntimeTeamState state,
        List<PlayerAvailabilityChange> availabilityChanges,
        List<SimulatedEvent> events,
        Instant kickoff,
        Random rng
) {
    TeamPlayerData injured = pickRandomFromActive(state, rng, state.substitutionsUsed < MAX_SUBSTITUTIONS);

    if (injured == null) {
        return;
    }

    if (injured.loanedForMatch()) {
        return;
    }

    PlayerMatchAccumulator injuredAcc = state.ensureAccumulator(injured);
    injuredAcc.injuredInMatch = true;
    injuredAcc.endMinute = minute;
    injuredAcc.active = false;

    state.activePlayers.removeIf(p -> p.idLigaJugador().equals(injured.idLigaJugador()));

    int injuryDays = rollInjuryDays(rng);
    Instant baseInstant = kickoff == null ? Instant.now() : kickoff;
    Instant until = baseInstant.plus(injuryDays, ChronoUnit.DAYS);

    availabilityChanges.add(new PlayerAvailabilityChange(
            injured.idLigaJugador(),
            "LESIONADO",
            until,
            null
    ));

    events.add(new SimulatedEvent(
            minute,
            randomSecond(rng),
            "LESION",
            0,
            injured.idLigaJugador(),
            null,
            MatchEventCommentary.injury(rng, buildPlayerName(injured))
    ));

    if (state.substitutionsUsed >= MAX_SUBSTITUTIONS) {
        return;
    }

    TeamPlayerData incoming = pickBenchReplacement(state, injured.posicion());
    if (incoming == null) {
        return;
    }

    state.substitutionsUsed++;

    PlayerMatchAccumulator incomingAcc = state.ensureAccumulator(incoming);
    incomingAcc.startMinute = minute;
    incomingAcc.active = true;

    state.activePlayers.add(incoming);

    if ("POR".equals(injured.posicion())) {
        if ("POR".equals(incoming.posicion())) {
            state.clearActingGoalkeeper();
        } else {
            state.setActingGoalkeeper(incoming.idLigaJugador());
        }
    }

    events.add(new SimulatedEvent(
            minute,
            Math.min(59, randomSecond(rng) + 1),
            "CAMBIO",
            0,
            incoming.idLigaJugador(),
            injured.idLigaJugador(),
            MatchEventCommentary.substitution(
                    rng,
                    state.nombreEquipo,
                    buildPlayerName(incoming),
                    buildPlayerName(injured)
            )
    ));
}

    private void processTacticalSubstitution(
        int minute,
        RuntimeTeamState state,
        List<SimulatedEvent> events,
        Random rng
) {
    if (state.substitutionsUsed >= MAX_SUBSTITUTIONS || state.bench.isEmpty()) {
        return;
    }

    TeamPlayerData outgoing = pickOutgoingForSubstitution(state, minute);
    if (outgoing == null) {
        return;
    }

    TeamPlayerData incoming = pickBenchReplacement(state, outgoing.posicion());
    if (incoming == null) {
        return;
    }
    if (!shouldExecuteTacticalSubstitution(state, outgoing, incoming, minute)) {
        return;
    }

    state.substitutionsUsed++;

    PlayerMatchAccumulator outgoingAcc = state.ensureAccumulator(outgoing);
    outgoingAcc.endMinute = minute;
    outgoingAcc.active = false;

    state.clearActingGoalkeeperIfOutgoingWasEmergency(outgoing);

    state.activePlayers.removeIf(p -> p.idLigaJugador().equals(outgoing.idLigaJugador()));
    state.activePlayers.add(incoming);

    PlayerMatchAccumulator incomingAcc = state.ensureAccumulator(incoming);
    incomingAcc.startMinute = minute;
    incomingAcc.active = true;

    events.add(new SimulatedEvent(
            minute,
            randomSecond(rng),
            "CAMBIO",
            0,
            incoming.idLigaJugador(),
            outgoing.idLigaJugador(),
            MatchEventCommentary.substitution(
                    rng,
                    state.nombreEquipo,
                    buildPlayerName(incoming),
                    buildPlayerName(outgoing)
            )
    ));
}

    private List<Integer> buildTacticalSubstitutionMinutes(RuntimeTeamState state, Random rng) {
        List<Integer> minutes = new ArrayList<>();

        if (state == null || state.bench == null || state.bench.isEmpty()) {
            return minutes;
        }

        int maxSubsByResources = Math.min(MAX_SUBSTITUTIONS, state.bench.size());
        if (maxSubsByResources <= 0) {
            return minutes;
        }
        int minSubs = Math.min(MIN_TACTICAL_SUBSTITUTIONS, maxSubsByResources);
        int desiredSubs = minSubs;
        if (maxSubsByResources > minSubs) {
            desiredSubs = randomBetween(rng, minSubs, maxSubsByResources);
        }

        if (desiredSubs <= 0) {
            return minutes;
        }

        int first = randomBetween(rng, 55, 62);
        int second = randomBetween(rng, 63, 74);
        int third = randomBetween(rng, 75, 84);

        minutes.add(first);

        if (desiredSubs >= 2) {
            minutes.add(second);
        }

        if (desiredSubs >= 3) {
            minutes.add(third);
        }

        for (int i = 3; i < desiredSubs; i++) {
            minutes.add(randomBetween(rng, 70, 86));
        }

        minutes.sort(Integer::compareTo);
        return minutes;
    }

    private RuntimeTeamState pickAttackingTeam(RuntimeTeamState localState, RuntimeTeamState awayState, Random rng) {
        double localAttack = computeAttackStrength(localState) + HOME_ATTACK_ADVANTAGE;
        double awayAttack = computeAttackStrength(awayState);

        double total = Math.max(1.0, localAttack + awayAttack);
        double roll = rng.nextDouble() * total;

        return roll < localAttack ? localState : awayState;
    }

    private double computeAttackStrength(RuntimeTeamState state) {
        if (state.activePlayers.isEmpty()) return 1.0;

        double total = 0.0;

        for (TeamPlayerData player : state.activePlayers) {
            double weightedScore = player.selectionScore() * QUALITY_IMPACT_MULTIPLIER;

            double weight = switch (player.posicion()) {
                case "DEL" -> 1.45;
                case "MED" -> 1.18;
                case "DEF" -> 0.82;
                case "POR" -> 0.55;
                default -> 1.0;
            };

            total += weightedScore * weight;
        }

        double averageQuality = total / state.activePlayers.size();
        double manpowerFactor = clamp(state.activePlayers.size() / 11.0, 0.65, 1.05);
        return averageQuality * manpowerFactor;
    }

    private double computeDefenseStrength(RuntimeTeamState state) {
        if (state.activePlayers.isEmpty()) return 1.0;

        double total = 0.0;

        for (TeamPlayerData player : state.activePlayers) {
            double weightedScore = player.selectionScore() * QUALITY_IMPACT_MULTIPLIER;

            double weight = switch (player.posicion()) {
                case "POR" -> 1.45;
                case "DEF" -> 1.28;
                case "MED" -> 0.92;
                case "DEL" -> 0.62;
                default -> 1.0;
            };

            total += weightedScore * weight;
        }

        double averageQuality = total / state.activePlayers.size();
        double manpowerFactor = clamp(state.activePlayers.size() / 11.0, 0.60, 1.05);
        return averageQuality * manpowerFactor;
    }

    private double calculateGoalProbability(
            RuntimeTeamState attacking,
            RuntimeTeamState defending,
            TeamPlayerData shooter,
            TeamPlayerData goalkeeper
    ) {
        double attack = computeAttackStrength(attacking);
        double defense = computeDefenseStrength(defending);
        double attackVsDefense = (attack - defense) * 0.0065;
        double shooterBonus = ((eventQualityScore(shooter) * QUALITY_IMPACT_MULTIPLIER) - 75.0) * 0.0060;
        double goalkeeperPenalty = goalkeeper == null
                ? 0.0
                : (((eventQualityScore(goalkeeper) * QUALITY_IMPACT_MULTIPLIER) - 75.0) * 0.0042);
        int playerDiff = attacking.activePlayers.size() - defending.activePlayers.size();

        double probability = 0.095
                + attackVsDefense
                + shooterBonus
                - goalkeeperPenalty
                + (playerDiff * 0.015);

        if (attacking.local) {
            probability += 0.018;
        }

        return clamp(probability, 0.05, 0.36);
    }

    private TeamPlayerData pickWeightedAttacker(RuntimeTeamState state, Random rng) {
        List<TeamPlayerData> candidates = new ArrayList<>();

        for (TeamPlayerData player : state.activePlayers) {
            if (!"POR".equals(player.posicion())) {
                candidates.add(player);
            }
        }

        return pickWeightedPlayer(candidates, rng, true);
    }

    private TeamPlayerData pickWeightedRecoverer(RuntimeTeamState state, Random rng) {
        return pickWeightedPlayer(state.activePlayers, rng, false);
    }

    private TeamPlayerData pickWeightedDefender(RuntimeTeamState state, Random rng) {
        return pickWeightedPlayer(state.activePlayers, rng, false);
    }

    /**
     * Puntuación para sortear quién protagoniza el evento: prioriza valoración (OVR) con un empujón suave.
     */
    private double eventQualityScore(TeamPlayerData player) {
        return MatchEventWeighting.eventQualityScore(player.selectionScore(), player.valoracionActual());
    }

    private double saveEventChance(TeamPlayerData goalkeeper) {
        return MatchEventWeighting.saveEventChance(goalkeeper.valoracionActual(), MISSED_SHOT_SAVE_EVENT_CHANCE);
    }

    private TeamPlayerData pickWeightedPlayer(List<TeamPlayerData> players, Random rng, boolean attackerProfile) {
        if (players == null || players.isEmpty()) {
            return null;
        }

        double totalWeight = 0.0;
        List<Double> weights = new ArrayList<>();

        for (TeamPlayerData player : players) {
            double weight = MatchEventWeighting.pickWeight(
                    player.selectionScore(),
                    player.valoracionActual(),
                    player.posicion(),
                    attackerProfile
            );
            totalWeight += weight;
            weights.add(weight);
        }

        double roll = rng.nextDouble() * totalWeight;
        double current = 0.0;

        for (int i = 0; i < players.size(); i++) {
            current += weights.get(i);

            if (roll < current) {
                return players.get(i);
            }
        }

        return players.get(players.size() - 1);
    }

    private TeamPlayerData pickAssistant(RuntimeTeamState state, TeamPlayerData scorer, Random rng) {
        if (!rollChance(rng, 0.80)) {
            return null;
        }

        List<TeamPlayerData> candidates = new ArrayList<>();

        for (TeamPlayerData player : state.activePlayers) {
            if (!player.idLigaJugador().equals(scorer.idLigaJugador()) && !"POR".equals(player.posicion())) {
                candidates.add(player);
            }
        }

        return pickWeightedPlayer(candidates, rng, true);
    }

    private TeamPlayerData pickRandomFromActive(RuntimeTeamState state, Random rng, boolean allowGoalkeeper) {
        if (state.activePlayers.isEmpty()) {
            return null;
        }

        List<TeamPlayerData> eligible = new ArrayList<>();
        for (TeamPlayerData player : state.activePlayers) {
            if (!player.loanedForMatch()) {
                eligible.add(player);
            }
        }

        if (eligible.isEmpty()) {
            return null;
        }

        List<TeamPlayerData> candidates = new ArrayList<>();

        for (TeamPlayerData player : eligible) {
            if (!"POR".equals(player.posicion())) {
                candidates.add(player);
            }
        }

        if (!allowGoalkeeper && candidates.isEmpty()) {
            return null;
        }
        List<TeamPlayerData> pool = allowGoalkeeper
                ? (candidates.isEmpty() ? eligible : candidates)
                : candidates;
        return pool.get(rng.nextInt(pool.size()));
    }

    /**
     * No forzar cambios si el banquillo no mejora realmente el contexto del partido.
     */
    private boolean shouldExecuteTacticalSubstitution(
            RuntimeTeamState state,
            TeamPlayerData outgoing,
            TeamPlayerData incoming,
            int minute
    ) {
        if (outgoing == null || incoming == null) {
            return false;
        }
        if ("POR".equals(outgoing.posicion()) && !"POR".equals(incoming.posicion())) {
            return false;
        }
        double outgoingNeed = substitutionNeedScoreLive(state, outgoing, minute);
        double incomingNeed = substitutionNeedScoreLive(state, incoming, minute);
        int outgoingFatigue = liveEffectiveFatigue(state, outgoing, minute);
        int incomingFatigue = incoming.cansancio() == null ? 0 : incoming.cansancio();

        double positionalBonus = Objects.equals(outgoing.posicion(), incoming.posicion()) ? 1.8 : 0.5;
        double gainScore = (incoming.selectionScore() - outgoing.selectionScore()) * 0.70
                + (outgoingFatigue - incomingFatigue) * 0.50
                + positionalBonus;

        return gainScore > 0.75 || (outgoingNeed - incomingNeed) > 1.5;
    }

    /**
     * Elige quien sale en un cambio táctico: prioriza cansancio acumulado en el partido + bajo rendimiento.
     * El portero solo es candidato si hay otro portero en banquillo (si no, aguanta aunque esté cansado).
     */
    private TeamPlayerData pickOutgoingForSubstitution(RuntimeTeamState state, int minute) {
        boolean benchHasGk = false;
        for (TeamPlayerData b : state.bench) {
            if ("POR".equals(b.posicion())) {
                benchHasGk = true;
                break;
            }
        }

        List<TeamPlayerData> candidates = new ArrayList<>();
        for (TeamPlayerData player : state.activePlayers) {
            if ("POR".equals(player.posicion())) {
                if (benchHasGk) {
                    candidates.add(player);
                }
                continue;
            }
            candidates.add(player);
        }

        if (candidates.isEmpty()) {
            return null;
        }

        candidates.sort(
                Comparator.comparingDouble((TeamPlayerData p) -> substitutionNeedScoreLive(state, p, minute))
                        .reversed()
                        .thenComparingDouble(TeamPlayerData::selectionScore)
                        .thenComparing((TeamPlayerData p) -> liveEffectiveFatigue(state, p, minute), Comparator.reverseOrder())
                        .thenComparing(TeamPlayerData::nombre)
        );

        return candidates.get(0);
    }

    /**
     * Sustituto desde banquillo (incluye cedidos en {@code state.bench}).
     * <ul>
     *     <li>Sale un jugador de campo → solo puede entrar DEF/MED/DEL; nunca un POR salvo casos imposibles aquí.</li>
     *     <li>Sale un POR → solo entra otro POR; si no hay ningún POR en banquillo, portero de emergencia con jugador de campo.</li>
     * </ul>
     */
    private TeamPlayerData pickBenchReplacement(RuntimeTeamState state, String outgoingPosition) {
        if (state.bench.isEmpty() || outgoingPosition == null) {
            return null;
        }

        if ("POR".equals(outgoingPosition)) {
            List<TeamPlayerData> gksOnBench = new ArrayList<>();
            List<TeamPlayerData> outfieldOnBench = new ArrayList<>();
            for (TeamPlayerData p : state.bench) {
                if ("POR".equals(p.posicion())) {
                    gksOnBench.add(p);
                } else {
                    outfieldOnBench.add(p);
                }
            }

            TeamPlayerData incoming = pickBestAmongBenchCandidates(gksOnBench, "POR");
            if (incoming != null) {
                removePlayerFromBench(state, incoming);
                return incoming;
            }

            incoming = pickEmergencyOutfieldGoalkeeper(outfieldOnBench);
            if (incoming != null) {
                removePlayerFromBench(state, incoming);
            }
            return incoming;
        }

        List<TeamPlayerData> outfieldOnly = new ArrayList<>();
        for (TeamPlayerData p : state.bench) {
            if (!"POR".equals(p.posicion())) {
                outfieldOnly.add(p);
            }
        }

        TeamPlayerData incoming = pickBestAmongBenchCandidates(outfieldOnly, outgoingPosition);
        if (incoming != null) {
            removePlayerFromBench(state, incoming);
        }
        return incoming;
    }

    private void removePlayerFromBench(RuntimeTeamState state, TeamPlayerData player) {
        state.bench.removeIf(p -> Objects.equals(p.idLigaJugador(), player.idLigaJugador()));
    }

    /**
     * Portero de emergencia cuando no queda ningún POR en banquillo (lesión/expulsión del titular).
     * Elige jugador de campo con mejor valoración y menos cansancio.
     */
    private TeamPlayerData pickEmergencyOutfieldGoalkeeper(List<TeamPlayerData> outfieldBench) {
        if (outfieldBench.isEmpty()) {
            return null;
        }

        TeamPlayerData best = outfieldBench.get(0);
        for (int i = 1; i < outfieldBench.size(); i++) {
            TeamPlayerData p = outfieldBench.get(i);
            int cmp = Double.compare(p.selectionScore(), best.selectionScore());
            if (cmp > 0) {
                best = p;
                continue;
            }
            if (cmp == 0 && fatigueLessForSubstitution(p, best)) {
                best = p;
            }
        }
        return best;
    }

    private boolean fatigueLessForSubstitution(TeamPlayerData a, TeamPlayerData b) {
        int fa = a.cansancio() == null ? 0 : a.cansancio();
        int fb = b.cansancio() == null ? 0 : b.cansancio();
        return fa < fb;
    }

    private TeamPlayerData pickBestAmongBenchCandidates(List<TeamPlayerData> candidates, String preferredPosition) {
        if (candidates.isEmpty()) {
            return null;
        }

        TeamPlayerData best = null;
        int bestDistance = Integer.MAX_VALUE;

        for (TeamPlayerData candidate : candidates) {
            int distance = roleDistance(preferredPosition, candidate.posicion());

            if (best == null) {
                best = candidate;
                bestDistance = distance;
                continue;
            }

            if (distance < bestDistance) {
                best = candidate;
                bestDistance = distance;
                continue;
            }

            if (distance == bestDistance) {
                if (candidate.selectionScore() > best.selectionScore()) {
                    best = candidate;
                    bestDistance = distance;
                } else if (Objects.equals(candidate.selectionScore(), best.selectionScore())
                        && fatigueLessForSubstitution(candidate, best)) {
                    best = candidate;
                    bestDistance = distance;
                }
            }
        }

        return best;
    }

    private int roleDistance(String preferredPosition, String candidatePosition) {
    if (Objects.equals(preferredPosition, candidatePosition)) {
        return 0;
    }

    int preferredGroup = positionGroup(preferredPosition);
    int candidateGroup = positionGroup(candidatePosition);

    if (preferredGroup == 0 || candidateGroup == 0) {
        return 100;
    }

    return Math.abs(preferredGroup - candidateGroup);
}

private int positionGroup(String position) {
    return switch (position) {
        case "POR" -> 0;
        case "DEF" -> 1;
        case "MED" -> 2;
        case "DEL" -> 3;
        default -> 99;
    };
}

    private void applyConcededGoalToDefenders(RuntimeTeamState defending) {
        for (TeamPlayerData player : defending.activePlayers) {
            if ("POR".equals(player.posicion()) || "DEF".equals(player.posicion())) {
                PlayerMatchAccumulator acc = defending.ensureAccumulator(player);
                acc.goalsConceded++;
            }
        }
    }

    private void finalizeMinutes(RuntimeTeamState state) {
        for (PlayerMatchAccumulator acc : state.accumulators.values()) {
            int endMinute = acc.endMinute == null ? FULL_MATCH_MINUTES : acc.endMinute;
            acc.minutesPlayed = Math.max(0, endMinute - acc.startMinute);
        }
    }

    private void insertMatchEvents(Connection conn, Long idPartido, List<SimulatedEvent> events) throws SQLException {
        String sql = """
                INSERT INTO partido_eventos (
                    id_partido_jornada,
                    segundo,
                    minuto,
                    tipo,
                    replay_offset_sec,
                    id_liga_jugador,
                    id_liga_jugador_sec,
                    id_jugador_cedido_temporada,
                    id_jugador_cedido_temporada_sec,
                    texto
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (SimulatedEvent event : events) {
                Long ligaPrincipal = normalizeLeaguePlayerIdForPersistence(event.idLigaJugadorPrincipal());
                Long ligaSecundario = normalizeLeaguePlayerIdForPersistence(event.idLigaJugadorSecundario());
                Integer cedPrincipal = event.idJugadorCedidoTemporadaPrincipal() != null
                        ? event.idJugadorCedidoTemporadaPrincipal()
                        : deriveExclusiveLoanId(event.idLigaJugadorPrincipal());
                Integer cedSecundario = event.idJugadorCedidoTemporadaSecundario() != null
                        ? event.idJugadorCedidoTemporadaSecundario()
                        : deriveExclusiveLoanId(event.idLigaJugadorSecundario());
                ps.setLong(1, idPartido);
                ps.setInt(2, event.segundo());
                ps.setInt(3, event.minuto());
                ps.setString(4, event.tipo());
                ps.setInt(5, event.replayOffsetSec());
                setNullableLong(ps, 6, ligaPrincipal);
                setNullableLong(ps, 7, ligaSecundario);
                setNullableInteger(ps, 8, cedPrincipal);
                setNullableInteger(ps, 9, cedSecundario);
                ps.setString(10, event.texto());
                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    private void insertGoals(Connection conn, Long idPartido, List<GoalRow> goals) throws SQLException {
    if (goals.isEmpty()) {
        return;
    }

    String sql = """
            INSERT INTO goles (id_partido_jornada, id_liga_jugador, id_jugador_cedido_temporada, minuto, es_penalti)
            VALUES (?, ?, ?, ?, ?)
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        for (GoalRow goal : goals) {
            Long idLigaJugador = normalizeLeaguePlayerIdForPersistence(goal.idLigaJugador());
            Integer idJugadorCedido = goal.idJugadorCedidoTemporada() != null
                    ? goal.idJugadorCedidoTemporada()
                    : deriveExclusiveLoanId(goal.idLigaJugador());
            ps.setLong(1, idPartido);
            setNullableLong(ps, 2, idLigaJugador);
            setNullableInteger(ps, 3, idJugadorCedido);
            ps.setInt(4, goal.minuto());
            ps.setBoolean(5, goal.penalti());
            ps.addBatch();
        }

        ps.executeBatch();
    }
}

    private void insertTeamMatchRows(
        Connection conn,
        Long idPartido,
        RuntimeTeamState localState,
        RuntimeTeamState awayState
) throws SQLException {
    String sql = """
            INSERT INTO equipos_partido (id_liga_equipo, id_partido_jornada, goles, es_local)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                goles = VALUES(goles),
                es_local = VALUES(es_local)
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, localState.idLigaEquipo);
        ps.setLong(2, idPartido);
        ps.setInt(3, localState.goals);
        ps.setBoolean(4, true);
        ps.addBatch();

        ps.setLong(1, awayState.idLigaEquipo);
        ps.setLong(2, idPartido);
        ps.setInt(3, awayState.goals);
        ps.setBoolean(4, false);
        ps.addBatch();

        ps.executeBatch();
    }
}

    private void finalizeMatch(
        Connection conn,
        Long idPartido,
        int golesLocal,
        int golesVisitante,
        Long idLigaEquipoGanador,
        boolean empate
) throws SQLException {
    String sql = """
            UPDATE partidos_jornada
            SET goles_local = ?,
                goles_visitante = ?,
                id_liga_equipo_ganador = ?,
                empate = ?,
                estado = 'FINALIZADO'
            WHERE id = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setInt(1, golesLocal);
        ps.setInt(2, golesVisitante);

        if (idLigaEquipoGanador == null) {
            ps.setNull(3, Types.BIGINT);
        } else {
            ps.setLong(3, idLigaEquipoGanador);
        }

        ps.setBoolean(4, empate);
        ps.setLong(5, idPartido);
        ps.executeUpdate();
    }

}

    private void upsertPlayerRoundStats(Connection conn, Long idJornada, RuntimeTeamState localState, RuntimeTeamState awayState) throws SQLException {
    String sql = """
            INSERT INTO jugadores_puntos_jornada (
                id_liga_jugador,
                id_jornada,
                puntos,
                nota_periodico,
                goles,
                disparos,
                regates,
                balones_recuperados,
                paradas,
                supertecnicas_usadas,
                minutos_jugados,
                asistencias,
                tarjetas_amarillas,
                tarjetas_rojas,
                goles_encajados,
                porteria_cero,
                autogoles,
                penaltis_parados,
                penaltis_fallados,
                lesionado_en_partido
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, 0, 0, 0, ?)
            ON DUPLICATE KEY UPDATE
                puntos = VALUES(puntos),
                nota_periodico = VALUES(nota_periodico),
                goles = VALUES(goles),
                disparos = VALUES(disparos),
                regates = VALUES(regates),
                balones_recuperados = VALUES(balones_recuperados),
                paradas = VALUES(paradas),
                supertecnicas_usadas = VALUES(supertecnicas_usadas),
                minutos_jugados = VALUES(minutos_jugados),
                asistencias = VALUES(asistencias),
                tarjetas_amarillas = VALUES(tarjetas_amarillas),
                tarjetas_rojas = VALUES(tarjetas_rojas),
                goles_encajados = VALUES(goles_encajados),
                porteria_cero = VALUES(porteria_cero),
                lesionado_en_partido = VALUES(lesionado_en_partido)
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        bindPlayerStatsBatch(ps, idJornada, localState);
        bindPlayerStatsBatch(ps, idJornada, awayState);
        ps.executeBatch();
    }
}

    public void recalculateLeaguePointsNow(Long idLiga) throws SQLException {
    if (idLiga == null) {
        throw new IllegalArgumentException("El idLiga es obligatorio");
    }

    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);

        try {
            leagueLineupService.recalculateParticipantPoints(conn, idLiga);
            conn.commit();
        } catch (Exception e) {
            conn.rollback();

            if (e instanceof IllegalArgumentException illegalArgumentException) {
                throw illegalArgumentException;
            }

            if (e instanceof SQLException sqlException) {
                throw sqlException;
            }

            throw new SQLException("Error recalculando puntos de la liga: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }
}

    /**
     * Repaso diario (fantasy): mismo núcleo que al cerrar partido, más presión si lleva jornadas
     * finalizadas sin minutos y si el último partido fue muy flojo; amortiguado si la forma reciente es buena.
     * <p>El toque de mercado queda anulado ({@link #applyDynamicRatingCoreWithPerformanceIndex} con gate) mientras el
     * <em>equipo de catálogo</em> del jugador en esa liga no haya disputado ningún partido {@code FINALIZADO};
     * no depende de si el jugador entró en campo. Cuando su equipo ya ha jugado y él lleva jornadas sin minutos,
     * sí entra la penalización habitual {@link #loadInactiveRoundsContext}.
     */
    public int applyDailyDynamicRatingsAndValuesForAllLeaguePlayers() throws SQLException {
        Set<Long> ligasConPartidoFinalizado = loadLigaIdsWithAtLeastOneFinalizedMatch();
        List<Long> ids = loadAllLigaJugadorIds();
        int ok = 0;
        for (Long idLj : ids) {
            try (Connection conn = DBConnection.getConnection()) {
                conn.setAutoCommit(false);
                try {
                    LigaJugadorLigaEquipoRow meta = loadLigaJugadorLigaEquipoRow(conn, idLj);
                    if (meta == null) {
                        conn.commit();
                        continue;
                    }
                    if (!ligasConPartidoFinalizado.contains(meta.idLiga())) {
                        conn.commit();
                        continue;
                    }
                    ProgressionSnapshot snapshot = loadProgressionSnapshot(conn, idLj);
                    if (snapshot == null) {
                        conn.commit();
                        continue;
                    }
                    InactiveRoundsContext inactive =
                            loadInactiveRoundsContext(conn, idLj, meta.idLiga(), meta.idCatalogEquipo());
                    double baseIndex = computeBasePerformanceIndex(snapshot);
                    double penalty =
                            computeDailyFantasyDecayPenalty(snapshot, inactive.effectiveInactiveRounds());
                    double adjustedIndex = Math.max(4.0, baseIndex - penalty);
                    if (applyDynamicRatingCoreWithPerformanceIndex(
                            conn,
                            snapshot,
                            snapshot.latestPoints(),
                            snapshot.latestMinutes(),
                            adjustedIndex,
                            true)) {
                        ok++;
                    }
                    conn.commit();
                } catch (Exception e) {
                    conn.rollback();
                    log.warn("Valor dinámico diario omitido id_liga_jugador={}: {}", idLj, e.getMessage());
                } finally {
                    conn.setAutoCommit(true);
                }
            }
        }
        log.info("Valor dinámico diario: {} jugadores actualizados de {}", ok, ids.size());
        return ok;
    }

    /**
     * Alinea {@code valoracion_actual} con el precio ({@code valor}) usando la curva de mercado.
     * Conviene ejecutarlo tras jobs nocturnos de valor o de probabilidades de titular.
     */
    public int syncValoracionActualFromValorForAllLeaguePlayers() throws SQLException {
        String sqlSelect = """
                SELECT lj.id, lj.valor, j.posicion
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                ORDER BY lj.id ASC
                """;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement sel = conn.prepareStatement(sqlSelect);
                 ResultSet rs = sel.executeQuery();
                 PreparedStatement upd = conn.prepareStatement(
                         """
                                 UPDATE liga_jugadores
                                 SET valoracion_actual = ?
                                 WHERE id = ?
                                 """)) {
                int n = 0;
                while (rs.next()) {
                    long id = rs.getLong(1);
                    long valor = rs.getLong(2);
                    String posicion = rs.getString(3);
                    double vr = pricingService.estimateRatingFromMarketValue(valor, posicion);
                    upd.setDouble(1, Math.round(vr * 100.0) / 100.0);
                    upd.setLong(2, id);
                    upd.addBatch();
                    n++;
                }
                upd.executeBatch();
                conn.commit();
                log.info("Sincronización valoración←valor: {} jugadores de liga", n);
                return n;
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }
                throw new SQLException("syncValoracionActualFromValor: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private List<Long> loadAllLigaJugadorIds() throws SQLException {
        String sql = """
                SELECT lj.id
                FROM liga_jugadores lj
                ORDER BY lj.id ASC
                """;
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

    /** Ligas donde existe al menos un partido cerrado (evita consultas por equipo si la liga sigue en pretemporada). */
    private Set<Long> loadLigaIdsWithAtLeastOneFinalizedMatch() throws SQLException {
        String sql = """
                SELECT DISTINCT j.id_liga
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE pj.estado = 'FINALIZADO'
                """;
        Set<Long> ids = new HashSet<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ids.add(rs.getLong("id_liga"));
            }
        }
        return ids;
    }

    /**
     * {@code true} si el equipo de catálogo ya ha sido local o visitante en algún partido finalizado de esa liga.
     */
    private boolean teamHasAtLeastOneFinalizedMatch(Connection conn, long idLiga, long catalogEquipoId)
            throws SQLException {
        String sql = """
                SELECT 1
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                INNER JOIN liga_equipos le_loc ON le_loc.id = pj.id_liga_equipo_local
                INNER JOIN liga_equipos le_vis ON le_vis.id = pj.id_liga_equipo_visitante
                WHERE j.id_liga = ?
                  AND pj.estado = 'FINALIZADO'
                  AND le_loc.id_liga = j.id_liga
                  AND le_vis.id_liga = j.id_liga
                  AND (le_loc.id_equipo = ? OR le_vis.id_equipo = ?)
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, catalogEquipoId);
            ps.setLong(3, catalogEquipoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private LigaJugadorLigaEquipoRow loadLigaJugadorLigaEquipoRow(Connection conn, Long idLigaJugador)
            throws SQLException {
        String sql = """
                SELECT id_liga, id_equipo
                FROM liga_jugadores
                WHERE id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new LigaJugadorLigaEquipoRow(rs.getLong("id_liga"), rs.getLong("id_equipo"));
            }
        }
    }

    private InactiveRoundsContext loadInactiveRoundsContext(
            Connection conn,
            Long idLigaJugador,
            Long idLiga,
            Long catalogEquipoId
    ) throws SQLException {
        int lastNumeroConMinutos = loadLastJornadaNumeroWithPlayedMinutes(conn, idLigaJugador);
        int finalizedAfterLastContribution =
                countFinalizedJornadasAfterNumero(conn, idLiga, lastNumeroConMinutos);
        boolean satOutFinishedMatchThisOpenRound =
                teamFinishedMatchThisOpenRoundWithoutMinutes(conn, idLiga, catalogEquipoId, idLigaJugador);
        return new InactiveRoundsContext(finalizedAfterLastContribution, satOutFinishedMatchThisOpenRound);
    }

    private int loadLastJornadaNumeroWithPlayedMinutes(Connection conn, Long idLigaJugador) throws SQLException {
        String sql = """
                SELECT COALESCE(MAX(j.numero), 0)
                FROM jugadores_puntos_jornada jp
                INNER JOIN jornadas j ON j.id = jp.id_jornada
                WHERE jp.id_liga_jugador = ?
                  AND jp.minutos_jugados > 0
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private int countFinalizedJornadasAfterNumero(Connection conn, Long idLiga, int numeroLowerBoundExclusive)
            throws SQLException {
        String sql = """
                SELECT COUNT(*)
                FROM jornadas jo
                WHERE jo.id_liga = ?
                  AND jo.estado = 'FINALIZADO'
                  AND jo.numero > ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setInt(2, numeroLowerBoundExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private boolean teamFinishedMatchThisOpenRoundWithoutMinutes(
            Connection conn,
            Long idLiga,
            Long catalogEquipoId,
            Long idLigaJugador
    ) throws SQLException {
        Long idJornadaAbierta = loadFirstEnCursoJornadaId(conn, idLiga);
        if (idJornadaAbierta == null) {
            return false;
        }
        boolean hayFinalizado =
                existsFinishedTeamMatchInJornada(conn, idLiga, idJornadaAbierta, catalogEquipoId);
        if (!hayFinalizado) {
            return false;
        }
        int minutos = loadJpMinutesForJornada(conn, idLigaJugador, idJornadaAbierta);
        return minutos <= 0;
    }

    private Long loadFirstEnCursoJornadaId(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                WHERE j.id_liga = ?
                  AND j.estado = 'EN_CURSO'
                ORDER BY j.numero ASC, j.id ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private boolean existsFinishedTeamMatchInJornada(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long catalogEquipoId
    ) throws SQLException {
        String sql = """
                SELECT 1
                FROM partidos_jornada pj
                INNER JOIN jornadas jo ON jo.id = pj.id_jornada
                WHERE jo.id = ?
                  AND jo.id_liga = ?
                  AND pj.estado = 'FINALIZADO'
                  AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            ps.setLong(3, catalogEquipoId);
            ps.setLong(4, catalogEquipoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private int loadJpMinutesForJornada(Connection conn, Long idLigaJugador, Long idJornada) throws SQLException {
        String sql = """
                SELECT COALESCE(minutos_jugados, 0)
                FROM jugadores_puntos_jornada
                WHERE id_liga_jugador = ?
                  AND id_jornada = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            ps.setLong(2, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return 0;
                }
                return rs.getInt(1);
            }
        }
    }

    /**
     * Penalización extra solo en el batch nocturno: “fantasma” de no jugar jornadas ya cerradas + mal último partido.
     */
    private double computeDailyFantasyDecayPenalty(ProgressionSnapshot snapshot, int effectiveInactiveRounds) {
        if (effectiveInactiveRounds <= 0) {
            return 0.0;
        }
        double penalty = 0.048 * Math.sqrt(Math.min(effectiveInactiveRounds, 14));

        int lp = snapshot.latestPoints();
        int lm = snapshot.latestMinutes();
        if (lm >= 45 && lp <= 3) {
            penalty += 0.032 * Math.min(effectiveInactiveRounds, 10);
        }

        double formaUltimos = snapshot.recentAverage();
        if (formaUltimos >= 7.0 && lm >= 60) {
            penalty *= 0.22;
        } else if (formaUltimos >= 5.5) {
            penalty *= 0.50;
        }

        return Math.min(penalty, 2.15);
    }

    private record LigaJugadorLigaEquipoRow(Long idLiga, Long idCatalogEquipo) {}

    private record InactiveRoundsContext(int finalizedRoundsAfterLastContribution, boolean extraInactiveThisOpenRound) {
        int effectiveInactiveRounds() {
            return finalizedRoundsAfterLastContribution + (extraInactiveThisOpenRound ? 1 : 0);
        }
    }


private int calculateNewspaperNote(PlayerMatchAccumulator acc, int porteriaCero) {
    if (acc.minutesPlayed <= 0) {
        return 1;
    }

    double note = 3.0;

    if (acc.minutesPlayed < 30) {
        note -= 0.7;
    } else if (acc.minutesPlayed < 60) {
        note -= 0.2;
    } else {
        note += 0.3;
    }

    switch (acc.posicion) {
        case "POR" -> {
            note += acc.goals * 1.2;
            note += acc.assists * 0.8;
            note += acc.saves * 0.18;
            note += porteriaCero > 0 ? 0.8 : 0.0;
            note -= acc.goalsConceded * 0.30;
        }
        case "DEF" -> {
            note += acc.goals * 1.1;
            note += acc.assists * 0.7;
            note += acc.recoveries * 0.08;
            note += porteriaCero > 0 ? 0.7 : 0.0;
            note -= acc.goalsConceded * 0.15;
        }
        case "MED" -> {
            note += acc.goals * 0.9;
            note += acc.assists * 0.7;
            note += acc.dribbles * 0.06;
            note += acc.recoveries * 0.04;
            note += acc.shots * 0.03;
        }
        case "DEL" -> {
            note += acc.goals * 1.0;
            note += acc.assists * 0.6;
            note += acc.shots * 0.05;
            note += acc.dribbles * 0.05;
        }
        default -> {
            note += acc.goals * 0.8;
            note += acc.assists * 0.5;
        }
    }

    note -= acc.redCards * 1.5;

    if (acc.injuredInMatch) {
        note -= 0.4;
    }

    int rounded = (int) Math.round(note);
    return Math.max(1, Math.min(5, rounded));
}

private int calculateFantasyPoints(PlayerMatchAccumulator acc, int newspaperNote) {
    // Todavía no generamos amarillas en simulación; se deja explícito para cuando se añada el evento.
    int yellowCards = 0;
    return FantasyPointsBreakdownCalculator.totalPoints(new FantasyPointsBreakdownCalculator.Input(
            acc.posicion,
            acc.minutesPlayed,
            acc.goals,
            acc.assists,
            acc.dribbles,
            acc.recoveries,
            acc.saves,
            acc.goalsConceded,
            yellowCards,
            acc.redCards,
            acc.injuredInMatch,
            newspaperNote
    ));
}

    private void bindPlayerStatsBatch(PreparedStatement ps, Long idJornada, RuntimeTeamState state) throws SQLException {
    for (PlayerMatchAccumulator acc : state.accumulators.values()) {
        if (state.loanedPlayerIds.contains(acc.idLigaJugador)) {
            continue;
        }
        int porteriaCero = 0;

        if (acc.minutesPlayed >= 60
                && ("POR".equals(acc.posicion) || "DEF".equals(acc.posicion))
                && acc.goalsConceded == 0) {
            porteriaCero = 1;
        }

        int newspaperNote = calculateNewspaperNote(acc, porteriaCero);
        int points = calculateFantasyPoints(acc, newspaperNote);

        ps.setLong(1, acc.idLigaJugador);
        ps.setLong(2, idJornada);
        ps.setInt(3, points);
        ps.setInt(4, newspaperNote);
        ps.setInt(5, acc.goals);
        ps.setInt(6, acc.shots);
        ps.setInt(7, acc.dribbles);
        ps.setInt(8, acc.recoveries);
        ps.setInt(9, acc.saves);
        ps.setInt(10, 0);
        ps.setInt(11, acc.minutesPlayed);
        ps.setInt(12, acc.assists);
        ps.setInt(13, acc.redCards);
        ps.setInt(14, acc.goalsConceded);
        ps.setInt(15, porteriaCero);
        ps.setInt(16, acc.injuredInMatch ? 1 : 0);
        ps.addBatch();
    }
}

    private int calculateFantasyPoints(PlayerMatchAccumulator acc) {
        return calculateFantasyPoints(acc, 3);
    }

    private ProgressionSnapshot loadProgressionSnapshot(Connection conn, Long idLigaJugador) throws SQLException {
    String sql = """
        SELECT lj.id,
               COALESCE(lj.valoracion_actual, j.valoracion) AS valoracion_actual,
               lj.valor,
               j.posicion,
               COALESCE((
                   SELECT AVG(t.puntos)
                   FROM (
                       SELECT jp.puntos
                       FROM jugadores_puntos_jornada jp
                       WHERE jp.id_liga_jugador = lj.id
                       ORDER BY jp.id_jornada DESC
                       LIMIT 3
                   ) t
               ), 0) AS media_ultimos_3,
               COALESCE((
                   SELECT AVG(jp2.puntos)
                   FROM jugadores_puntos_jornada jp2
                   WHERE jp2.id_liga_jugador = lj.id
               ), 0) AS media_temporada,
               COALESCE((
                   SELECT AVG(t.nota_periodico)
                   FROM (
                       SELECT jp.nota_periodico
                       FROM jugadores_puntos_jornada jp
                       WHERE jp.id_liga_jugador = lj.id
                       ORDER BY jp.id_jornada DESC
                       LIMIT 3
                   ) t
               ), 3) AS media_nota_ultimos_3,
               COALESCE((
                   SELECT AVG(jp2.nota_periodico)
                   FROM jugadores_puntos_jornada jp2
                   WHERE jp2.id_liga_jugador = lj.id
               ), 3) AS media_nota_temporada,
               COALESCE((
                   SELECT jp3.puntos
                   FROM jugadores_puntos_jornada jp3
                   WHERE jp3.id_liga_jugador = lj.id
                   ORDER BY jp3.id_jornada DESC
                   LIMIT 1
               ), 0) AS puntos_ultimo_partido,
               COALESCE((
                   SELECT jp3.minutos_jugados
                   FROM jugadores_puntos_jornada jp3
                   WHERE jp3.id_liga_jugador = lj.id
                   ORDER BY jp3.id_jornada DESC
                   LIMIT 1
               ), 0) AS minutos_ultimo_partido,
               COALESCE(NULLIF(TRIM(lj.estado), ''), 'DISPONIBLE') AS estado_liga
        FROM liga_jugadores lj
        INNER JOIN jugadores j ON j.id = lj.id_jugador
        WHERE lj.id = ?
        """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLigaJugador);

        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }

            return new ProgressionSnapshot(
                    rs.getLong("id"),
                    rs.getDouble("valoracion_actual"),
                    rs.getLong("valor"),
                    rs.getString("posicion"),
                    rs.getDouble("media_ultimos_3"),
                    rs.getDouble("media_temporada"),
                    rs.getDouble("media_nota_ultimos_3"),
                    rs.getDouble("media_nota_temporada"),
                    rs.getInt("puntos_ultimo_partido"),
                    rs.getInt("minutos_ultimo_partido"),
                    rs.getString("estado_liga"));
        }
    }
}

    private void updatePlayerDynamicRow(
            Connection conn,
            Long idLigaJugador,
            long previousValue,
            double previousRating,
            int latestPoints,
            int latestMinutes,
            long newValue,
            String position
    ) throws SQLException {
        newValue = Math.max(LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE, newValue);

        double newRating = pricingService.estimateRatingFromMarketValue(newValue, position);
        newRating = round2(clamp(newRating, 60.0, 99.0));

        long tierFloor = pricingService.getFloorValueForRating(newRating);
        if (newValue < tierFloor) {
            newValue = tierFloor;
            newRating = round2(clamp(pricingService.estimateRatingFromMarketValue(newValue, position), 60.0, 99.0));
        }

        if (latestPoints >= 7) {
            long delta = newValue - previousValue;
            log.info(
                    "Dynamic value guardrail | idLigaJugador={} latestPoints={} latestMinutes={} previousValue={} newValue={} delta={} previousRating={} newRating={}",
                    idLigaJugador,
                    latestPoints,
                    latestMinutes,
                    previousValue,
                    newValue,
                    delta,
                    previousRating,
                    newRating
            );
        }

        String sql = """
                UPDATE liga_jugadores
                SET valor_anterior = ?,
                    valor = ?,
                    valoracion_actual = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, previousValue);
            ps.setLong(2, newValue);
            ps.setDouble(3, newRating);
            ps.setLong(4, idLigaJugador);
            ps.executeUpdate();
        }
    }

    private CurrentRoundOutcome loadCurrentRoundOutcome(Connection conn, Long idJornada, Long idLigaJugador) throws SQLException {
    String sql = """
            SELECT puntos, minutos_jugados
            FROM jugadores_puntos_jornada
            WHERE id_jornada = ?
              AND id_liga_jugador = ?
            LIMIT 1
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idJornada);
        ps.setLong(2, idLigaJugador);

        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }

            return new CurrentRoundOutcome(
                    rs.getObject("puntos", Integer.class),
                    rs.getObject("minutos_jugados", Integer.class)
            );
        }
    }
}

    private record CurrentRoundOutcome(
        Integer puntos,
        Integer minutosJugados
) {}

    private boolean isInjuredOrSanctionedLeagueState(String estadoLiga) {
        if (estadoLiga == null || estadoLiga.isBlank()) {
            return false;
        }
        String e = estadoLiga.trim().toUpperCase(Locale.ROOT);
        return "LESIONADO".equals(e) || "SANCIONADO".equals(e);
    }

    /**
     * Lesión/sanción: presión bajista aunque las medias de fantasy sigan altas por el último partido jugado.
     */
    private double clampAvailabilityPerformanceIndex(double performanceIndex, String estadoLiga) {
        if (!isInjuredOrSanctionedLeagueState(estadoLiga)) {
            return performanceIndex;
        }
        return Math.min(performanceIndex, 7.65);
    }

    private boolean skipValueProtectiveGuards(
            ProgressionSnapshot snapshot, int latestPoints, int latestMinutes) {
        if (isInjuredOrSanctionedLeagueState(snapshot.estadoLiga())) {
            return true;
        }
        return latestPoints < 0 && latestMinutes >= 20;
    }

    /**
     * Mal partido con puntos fantasy negativos: recorte extra acotado (máx. ~1M/día en fichas caras),
     * proporcional a la magnitud negativa y al valor del jugador.
     */
    private long extraMarketLossFromNegativeFantasyPoints(
            long previousValue, int latestPoints, int latestMinutes) {
        if (latestPoints >= 0 || latestMinutes < 22) {
            return 0;
        }
        double magnitude = Math.min(36, -latestPoints);
        double severity = clamp(magnitude / 9.0, 0.22, 1.12);
        long dailyCap = Math.min(1_000_000L, Math.max(125_000L, Math.round(previousValue * 0.019)));
        return Math.round(dailyCap * severity);
    }

    private void applyAvailabilityChanges(Connection conn, List<PlayerAvailabilityChange> changes) throws SQLException {
        if (changes.isEmpty()) return;

        String sql = """
                UPDATE liga_jugadores
                SET estado = ?,
                    lesionado_hasta = ?,
                    sancionado_hasta = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (PlayerAvailabilityChange change : changes) {
                ps.setString(1, change.estado());

                if (change.lesionadoHasta() == null) {
                    ps.setNull(2, Types.TIMESTAMP);
                } else {
                    ps.setTimestamp(2, Timestamp.from(change.lesionadoHasta()));
                }

                if (change.sancionadoHasta() == null) {
                    ps.setNull(3, Types.TIMESTAMP);
                } else {
                    ps.setTimestamp(3, Timestamp.from(change.sancionadoHasta()));
                }

                ps.setLong(4, change.idLigaJugador());
                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    private void applyFatigueChanges(Connection conn, RuntimeTeamState localState, RuntimeTeamState awayState) throws SQLException {
    String sql = """
            UPDATE liga_jugadores
            SET cansancio = LEAST(100, ?)
            WHERE id = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        bindFatigueBatch(ps, localState);
        bindFatigueBatch(ps, awayState);
        ps.executeBatch();
    }
}

    private void bindFatigueBatch(PreparedStatement ps, RuntimeTeamState state) throws SQLException {
    for (PlayerMatchAccumulator acc : state.accumulators.values()) {
        int fatigueIncrease = calculateFatigueIncrease(acc);
        int finalFatigue = Math.min(100, acc.initialCansancio + fatigueIncrease);

        ps.setInt(1, finalFatigue);
        ps.setLong(2, acc.idLigaJugador);
        ps.addBatch();
    }
}
private int calculateFatigueIncrease(PlayerMatchAccumulator acc) {
        return fatigueIncreaseForMinutesPlayed(acc, acc.minutesPlayed);
    }

    /** Incremento de cansancío por minutos jugados (misma lógica que al cerrar el partido). */
    private int fatigueIncreaseForMinutesPlayed(PlayerMatchAccumulator acc, int minutesPlayed) {
        if (minutesPlayed <= 0) {
            return 0;
        }

        double base = minutesPlayed * 0.20;
        double bonus = 0.0;

        if (minutesPlayed >= 80) {
            bonus += 2.0;
        } else if (minutesPlayed >= 60) {
            bonus += 1.0;
        }

        if ("POR".equals(acc.posicion)) {
            base *= 0.78;
            bonus *= 0.5;
        }

        if (acc.injuredInMatch) {
            bonus += 5.0;
        }

        if (acc.redCards > 0) {
            bonus += 3.0;
        }

        int result = (int) Math.round(base + bonus);
        return Math.max(0, result);
    }

    /**
     * Cansancio efectivo en un instante del partido (previo + acumulado por minutos llevados en campo).
     */
    private int liveEffectiveFatigue(RuntimeTeamState state, TeamPlayerData player, int minute) {
        PlayerMatchAccumulator acc = state.accumulators.get(player.idLigaJugador());
        int baseline = player.cansancio() != null ? player.cansancio() : 0;
        if (acc == null) {
            return Math.min(100, baseline);
        }
        baseline = acc.initialCansancio;
        if (!acc.active) {
            return Math.min(100, baseline);
        }
        int effectiveEnd = minute;
        if (acc.endMinute != null) {
            effectiveEnd = Math.min(minute, acc.endMinute);
        }
        int mins = Math.max(0, effectiveEnd - acc.startMinute);
        int increase = fatigueIncreaseForMinutesPlayed(acc, mins);
        return Math.min(100, baseline + increase);
    }

    /** Prioridad de sustitución en tiempo real (fatigue en campo tiene más peso que el roster inicial). */
    private double substitutionNeedScoreLive(RuntimeTeamState state, TeamPlayerData player, int minute) {
        double fatigue = liveEffectiveFatigue(state, player, minute);
        double score = (100.0 - player.selectionScore()) * 0.45;
        score += fatigue * 0.55;
        switch (player.posicion()) {
            case "DEL" -> score += 1.5;
            case "MED" -> score += 1.0;
            case "DEF" -> score += 0.4;
            default -> {
            }
        }
        return score;
    }

    private void updateLeagueTable(Connection conn, MatchHeader header, int golesLocal, int golesVisitante, boolean empate) throws SQLException {
        if (empate) {
            updateLeagueTeamRow(conn, header.idLigaEquipoLocal(), 1, 0, 1, 0, golesLocal, golesVisitante);
            updateLeagueTeamRow(conn, header.idLigaEquipoVisitante(), 1, 0, 1, 0, golesVisitante, golesLocal);
            return;
        }

        if (golesLocal > golesVisitante) {
            updateLeagueTeamRow(conn, header.idLigaEquipoLocal(), 3, 1, 0, 0, golesLocal, golesVisitante);
            updateLeagueTeamRow(conn, header.idLigaEquipoVisitante(), 0, 0, 0, 1, golesVisitante, golesLocal);
        } else {
            updateLeagueTeamRow(conn, header.idLigaEquipoLocal(), 0, 0, 0, 1, golesLocal, golesVisitante);
            updateLeagueTeamRow(conn, header.idLigaEquipoVisitante(), 3, 1, 0, 0, golesVisitante, golesLocal);
        }
    }

    private void updateLeagueTeamRow(
            Connection conn,
            Long idLigaEquipo,
            int puntos,
            int victorias,
            int empates,
            int derrotas,
            int golesFavor,
            int golesContra
    ) throws SQLException {
        String sql = """
                UPDATE liga_equipos
                SET puntos = puntos + ?,
                    victorias = victorias + ?,
                    empates = empates + ?,
                    derrotas = derrotas + ?,
                    goles_favor = goles_favor + ?,
                    goles_contra = goles_contra + ?,
                    diferencia_goles = diferencia_goles + ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, puntos);
            ps.setInt(2, victorias);
            ps.setInt(3, empates);
            ps.setInt(4, derrotas);
            ps.setInt(5, golesFavor);
            ps.setInt(6, golesContra);
            ps.setInt(7, golesFavor - golesContra);
            ps.setLong(8, idLigaEquipo);
            ps.executeUpdate();
        }
    }

    private void updateRoundStatus(Connection conn, Long idJornada) throws SQLException {
        String sqlCheck = """
                SELECT COUNT(*) AS total,
                       COALESCE(SUM(CASE WHEN estado = 'FINALIZADO' THEN 1 ELSE 0 END), 0) AS finalizados
                FROM partidos_jornada
                WHERE id_jornada = ?
                """;

        int total;
        int finalizados;

        try (PreparedStatement ps = conn.prepareStatement(sqlCheck)) {
            ps.setLong(1, idJornada);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                total = rs.getInt("total");
                finalizados = rs.getInt("finalizados");
            }
        }

        String newState = total > 0 && total == finalizados ? "FINALIZADA" : "EN_CURSO";

        String sqlUpdate = """
                UPDATE jornadas
                SET estado = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlUpdate)) {
            ps.setString(1, newState);
            ps.setLong(2, idJornada);
            ps.executeUpdate();
        }
    }

    private void setNullableLong(PreparedStatement ps, int index, Long value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.BIGINT);
        } else {
            ps.setLong(index, value);
        }
    }

    private void setNullableInteger(PreparedStatement ps, int index, Integer value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.INTEGER);
        } else {
            ps.setInt(index, value);
        }
    }

    private Long normalizeLeaguePlayerIdForPersistence(Long idLigaJugador) {
        if (idLigaJugador == null || idLigaJugador < 0) {
            return null;
        }
        return idLigaJugador;
    }

    private Integer deriveExclusiveLoanId(Long idLigaJugador) {
        if (idLigaJugador == null || idLigaJugador >= 0) {
            return null;
        }
        return Math.toIntExact(Math.abs(idLigaJugador));
    }

    private int randomSecond(Random rng) {
        return rng.nextInt(60);
    }

    private int randomBetween(Random rng, int min, int max) {
        return min + rng.nextInt((max - min) + 1);
    }

    private boolean rollChance(Random rng, double probability) {
        return rng.nextDouble() < probability;
    }

    private int rollInjuryDays(Random rng) {
        int roll = rng.nextInt(100);
        if (roll < 55) return randomBetween(rng, 3, 7);
        if (roll < 85) return randomBetween(rng, 8, 14);
        return randomBetween(rng, 15, 30);
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private String buildPlayerName(TeamPlayerData player) {
        if (player.pila() != null && !player.pila().isBlank()) return player.pila();
        return player.nombre();
    }

    private record DueMatchRef(Long idLiga, Long idPartido) {}
    private record MatchHeader(
            Long idPartido,
            Long idJornada,
            Long idLiga,
            String estado,
            Instant inicioEn,
            Long idLigaEquipoLocal,
            Long idEquipoLocal,
            String nombreEquipoLocal,
            Long idLigaEquipoVisitante,
            Long idEquipoVisitante,
            String nombreEquipoVisitante,
            String alineacionEquipoLocal,
            String alineacionEquipoVisitante
    ) {}
    private record TeamFormation(int def, int med, int del) {}

    private record TeamPlayerData(
            Long idLigaJugador,
            Long idJugador,
            String nombre,
            String pila,
            String posicion,
            Double valoracionActual,
            String estado,
            Integer cansancio,
            Long valor,
            Double mediaUltimos3,
            Double mediaTemporada,
            Double selectionScore,
            boolean loanedForMatch,
            String tipoOrigenJugador,
            Integer idJugadorCedidoTemporada,
            Integer idEquipoCedidosTemporadaOrigen,
            String foto
    ) {}

    private record ScoreRow(Integer golesLocal, Integer golesVisitante) {}

    private record PreparedLineup(List<TeamPlayerData> starters, List<TeamPlayerData> bench) {}
    private record OwnSelectionResult(List<TeamPlayerData> starters, List<TeamPlayerData> remainingOwn) {}

    private record PreparedLineupWithLoans(PreparedLineup lineup, List<PartidoCesionRow> loanRows) {}

    private record PartidoCesionRow(
            Long idLigaJugador,
            Long idLigaEquipoOrigen,
            Integer idEquipoCedidosTemporadaOrigen,
            Integer idJugadorCedidoTemporada,
            String tipoOrigenJugador,
            Long idLigaEquipoDestino,
            String rol,
            String posicion
    ) {}

    private record LoanPickResult(TeamPlayerData player, Long idLigaEquipoOrigen, Integer idEquipoCedidosTemporadaOrigen) {}
    private record LoanChronologyPlayerRow(Long idLigaJugador, Integer idJugadorCedidoTemporada, String nombreJugador) {}
    private record LoanChronologyTeamGroup(Long idLigaEquipoDestino, String nombreEquipoDestino, List<LoanChronologyPlayerRow> players) {}
    private record PreparedRuntimeStates(RuntimeTeamState localState, RuntimeTeamState awayState) {}
    private record SimulatedEvent(
            Integer minuto,
            Integer segundo,
            String tipo,
            Integer replayOffsetSec,
            Long idLigaJugadorPrincipal,
            Long idLigaJugadorSecundario,
            Integer idJugadorCedidoTemporadaPrincipal,
            Integer idJugadorCedidoTemporadaSecundario,
            String texto
    ) {
        private SimulatedEvent(
                Integer minuto,
                Integer segundo,
                String tipo,
                Integer replayOffsetSec,
                Long idLigaJugadorPrincipal,
                Long idLigaJugadorSecundario,
                String texto
        ) {
            this(minuto, segundo, tipo, replayOffsetSec, idLigaJugadorPrincipal, idLigaJugadorSecundario, null, null, texto);
        }
    }
    private record GoalRow(Long idLigaJugador, Integer idJugadorCedidoTemporada, Integer minuto, Boolean penalti) {
        private GoalRow(Long idLigaJugador, Integer minuto, Boolean penalti) {
            this(idLigaJugador, null, minuto, penalti);
        }
    }
    private record PlayerAvailabilityChange(Long idLigaJugador, String estado, Instant lesionadoHasta, Instant sancionadoHasta) {}
    private record MatchSimulationOutput(List<SimulatedEvent> events, List<GoalRow> goalRows, List<PlayerAvailabilityChange> availabilityChanges) {}
    private record DynamicUpdateRow(Long idLigaJugador, int latestPoints, int latestMinutes) {}
private record ProgressionSnapshot(
        Long idLigaJugador,
        double currentRating,
        long currentValue,
        String position,
        double recentAverage,
        double seasonAverage,
        double recentNoteAverage,
        double seasonNoteAverage,
        int latestPoints,
        int latestMinutes,
        String estadoLiga
) {}
    private static class RuntimeTeamState {
        private final Long idLigaEquipo;
        private final Long idEquipo;
        private final String nombreEquipo;
        private final boolean local;
        private final Set<Long> loanedPlayerIds;
        private final List<TeamPlayerData> starters;
        private final List<TeamPlayerData> bench;
        private final List<TeamPlayerData> activePlayers;
        private final Map<Long, PlayerMatchAccumulator> accumulators;
        private int substitutionsUsed;
        private int goals;
        /** Portero improvisado en campo (no cambia {@link TeamPlayerData#posicion}); null si hay titular/suplente POR real activo. */
        private Long actingGoalkeeperId;

        private RuntimeTeamState(
                Long idLigaEquipo,
                Long idEquipo,
                String nombreEquipo,
                boolean local,
                Set<Long> loanedPlayerIds
        ) {
            this.idLigaEquipo = idLigaEquipo;
            this.idEquipo = idEquipo;
            this.nombreEquipo = nombreEquipo;
            this.local = local;
            this.loanedPlayerIds = loanedPlayerIds;
            this.starters = new ArrayList<>();
            this.bench = new ArrayList<>();
            this.activePlayers = new ArrayList<>();
            this.accumulators = new HashMap<>();
            this.substitutionsUsed = 0;
            this.goals = 0;
            this.actingGoalkeeperId = null;
        }

        private void clearActingGoalkeeper() {
            this.actingGoalkeeperId = null;
        }

        private void setActingGoalkeeper(Long idLigaJugador) {
            this.actingGoalkeeperId = idLigaJugador;
        }

        private void clearActingGoalkeeperIfOutgoingWasEmergency(TeamPlayerData outgoing) {
            if (outgoing != null && Objects.equals(actingGoalkeeperId, outgoing.idLigaJugador())) {
                this.actingGoalkeeperId = null;
            }
        }

        private PlayerMatchAccumulator ensureAccumulator(TeamPlayerData player) {
            PlayerMatchAccumulator existing = this.accumulators.get(player.idLigaJugador());

            if (existing != null) {
                return existing;
            }

            PlayerMatchAccumulator created = new PlayerMatchAccumulator(
                    player.idLigaJugador(),
                    player.idJugador(),
                    player.posicion(),
                    player.cansancio()
            );

            this.accumulators.put(player.idLigaJugador(), created);
            return created;
        }

        private TeamPlayerData findCurrentGoalkeeper() {
            for (TeamPlayerData player : activePlayers) {
                if ("POR".equals(player.posicion())) {
                    return player;
                }
            }

            if (actingGoalkeeperId != null) {
                for (TeamPlayerData player : activePlayers) {
                    if (Objects.equals(player.idLigaJugador(), actingGoalkeeperId)) {
                        return player;
                    }
                }
            }

            return null;
        }
    }

    private static class PlayerMatchAccumulator {
        private final Long idLigaJugador;
        private final Long idJugador;
        private final String posicion;
        private final int initialCansancio;

        private int startMinute;
        private Integer endMinute;
        private boolean active;

        private int minutesPlayed;
        private int goals;
        private int assists;
        private int shots;
        private int dribbles;
        private int recoveries;
        private int saves;
        private int redCards;
        private int goalsConceded;
        private boolean injuredInMatch;

        private PlayerMatchAccumulator(Long idLigaJugador, Long idJugador, String posicion, int initialCansancio) {
            this.idLigaJugador = idLigaJugador;
            this.idJugador = idJugador;
            this.posicion = posicion;
            this.initialCansancio = initialCansancio;
            this.startMinute = 0;
            this.endMinute = null;
            this.active = false;
            this.minutesPlayed = 0;
            this.goals = 0;
            this.assists = 0;
            this.shots = 0;
            this.dribbles = 0;
            this.recoveries = 0;
            this.saves = 0;
            this.redCards = 0;
            this.goalsConceded = 0;
            this.injuredInMatch = false;
        }
    }
}
