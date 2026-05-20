package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueMarketPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchEventResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchLineupPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchRealCoachResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupHistoryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupHistoryRoundResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueAssignedCoachResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupRoundDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueParticipantLineupRoundPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.ParticipantRoundFantasyBreakdown;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundMatchResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueRoundSummaryResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueTeamStandingRowResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueUnavailablePlayerResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import com.eternalxi.eternalxi_api.dto.league.LeagueLiveMatchResponse;
import java.util.Objects;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerDetailResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerRoundStatsResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueHomeFeedResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueHomeNewsItemResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueHomeTopPlayerResponse;
import com.eternalxi.eternalxi_api.dto.league.StarterProbabilityLite;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class LeagueDataService {

    private static final Logger log = LoggerFactory.getLogger(LeagueDataService.class);

    private static final long FULL_MATCH_VISIBLE_SECONDS = 90L * 60L;

    private static final long MERCADO_USER_ID = 1L;
    private static final String DEFAULT_MATCH_FORMATION = "4-3-3";
    private final LeagueLineupService leagueLineupService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeaguePlayerMarketValueService leaguePlayerMarketValueService;

    public LeagueDataService(
            LeagueLineupService leagueLineupService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeaguePlayerMarketValueService leaguePlayerMarketValueService
    ) {
        this.leagueLineupService = leagueLineupService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leaguePlayerMarketValueService = leaguePlayerMarketValueService;
    }

    public LeaguePlayerDetailResponse getLeaguePlayerDetail(
            Long idLiga,
            Long idLigaJugador,
            Long idUsuario,
            Long idJornadaContext
    ) throws SQLException {
    if (idLiga == null || idLigaJugador == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        String playerSql = """
        SELECT lj.id AS id_liga_jugador,
               lj.id_jugador,
               j.nombre,
               j.pila,
               j.posicion,
               CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
               lj.id_equipo,
               e.nombre AS nombre_equipo,
               CASE
                   WHEN lj.estado IN ('LESIONADO', 'SANCIONADO')
                    AND EXISTS (
                       SELECT 1
                       FROM jornadas jo_estado
                       INNER JOIN partidos_jornada pj_estado ON pj_estado.id_jornada = jo_estado.id
                       WHERE jo_estado.id_liga = lj.id_liga
                         AND (pj_estado.id_liga_equipo_local = lj.id_equipo OR pj_estado.id_liga_equipo_visitante = lj.id_equipo)
                         AND pj_estado.estado IN ('EN_JUEGO', 'FINALIZADO')
                         AND pj_estado.inicio_en IS NOT NULL
                         AND pj_estado.inicio_en > NOW()
                   ) THEN 'DISPONIBLE'
                   ELSE lj.estado
               END AS estado,
               lj.cansancio,
               lj.valor,
               COALESCE(lj.valor_anterior, 0) AS valor_anterior,
               lj.id_usuario_dueno AS id_usuario_dueno,
               CASE
                   WHEN lj.id_usuario_dueno = ? THEN TRUE
                   ELSE FALSE
               END AS es_mercado,
               CASE
                   WHEN lj.id_usuario_dueno = ? THEN TRUE
                   ELSE FALSE
               END AS en_pool_mercado,
               CASE
                   WHEN EXISTS (
                       SELECT 1
                       FROM mercado_diario md
                       WHERE md.id_liga = lj.id_liga
                         AND md.id_liga_jugador = lj.id
                         AND md.fecha = CURDATE()
                   ) THEN TRUE
                   ELSE FALSE
               END AS en_mercado_hoy,
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
               END AS tiene_oferta_pendiente,
               j.foto AS foto_jugador,
               0 AS puntos_fantasy_totales
        FROM liga_jugadores lj
        INNER JOIN jugadores j ON j.id = lj.id_jugador
        INNER JOIN equipos e ON e.id = lj.id_equipo
        WHERE lj.id = ?
          AND lj.id_liga = ?
        LIMIT 1
        """;

        Long playerId;
String nombre;
String pila;
String posicion;
Integer valoracion;
Long idEquipo;
String nombreEquipo;
String estado;
Integer cansancio;
Long valor;
Long valorAnterior;
Long idUsuarioDueno;
Boolean esMercado;
Boolean enPoolMercado;
Boolean enMercadoHoy;
Boolean tieneOfertaPendiente;
String fotoJugador;
Integer puntosFantasyTotales;

        try (PreparedStatement ps = conn.prepareStatement(playerSql)) {
            ps.setLong(1, MERCADO_USER_ID);
            ps.setLong(2, MERCADO_USER_ID);
            ps.setLong(3, idUsuario);
            ps.setLong(4, idLigaJugador);
            ps.setLong(5, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Jugador no encontrado en la liga");
                }

                playerId = rs.getLong("id_jugador");
                nombre = rs.getString("nombre");
                pila = rs.getString("pila");
                posicion = rs.getString("posicion");
                valoracion = rs.getInt("valoracion");
                idEquipo = rs.getLong("id_equipo");
                nombreEquipo = rs.getString("nombre_equipo");
                estado = rs.getString("estado");
                cansancio = rs.getInt("cansancio");
                valor = rs.getLong("valor");
                valorAnterior = rs.getLong("valor_anterior");
                idUsuarioDueno = rs.getLong("id_usuario_dueno");
                esMercado = rs.getBoolean("es_mercado");
                enPoolMercado = rs.getBoolean("en_pool_mercado");
                enMercadoHoy = rs.getBoolean("en_mercado_hoy");
                tieneOfertaPendiente = rs.getBoolean("tiene_oferta_pendiente");
                fotoJugador = LeagueAssetUrls.player(playerId);
                puntosFantasyTotales = rs.getInt("puntos_fantasy_totales");
            }
        }

        List<LeaguePlayerRoundStatsResponse> estadisticasJornadas =
                loadFantasyRoundStatsVisibleForPlayer(conn, idLiga, idLigaJugador, idEquipo, posicion);

        puntosFantasyTotales = estadisticasJornadas.stream().mapToInt(s -> s.puntos() == null ? 0 : s.puntos()).sum();

        Integer probabilidadTitular = null;
        String motivoTitularidad = null;
        Long idPartidoProbabilidad = null;
        Instant calculadoEnProbabilidad = null;
        Long idJornadaProb = leagueStarterProbabilityService.resolveDisplayJornadaForTeamStarterProbability(
                conn, idLiga, idJornadaContext, idEquipo);
        if (idJornadaProb != null) {
            Map<Long, StarterProbabilityLite> probMap = leagueStarterProbabilityService.loadProbabilityMapForLeaguePlayers(
                    conn,
                    idLiga,
                    idJornadaProb,
                    List.of(idLigaJugador)
            );
            StarterProbabilityLite lite = probMap.get(idLigaJugador);
            if (lite == null) {
                leagueStarterProbabilityService.ensureProbabilitiesForCatalogTeamRounds(
                        idLiga,
                        Set.of(new LeagueStarterProbabilityService.CatalogTeamRound(idJornadaProb, idEquipo)));
                probMap = leagueStarterProbabilityService.loadProbabilityMapForLeaguePlayers(
                        conn,
                        idLiga,
                        idJornadaProb,
                        List.of(idLigaJugador));
                lite = probMap.get(idLigaJugador);
            }
            if (lite != null) {
                probabilidadTitular = lite.probabilidadTitular();
                motivoTitularidad = lite.motivoTitularidad();
                idPartidoProbabilidad = lite.idPartidoProbabilidad();
                calculadoEnProbabilidad = lite.calculadoEnProbabilidad();
            }
        }

        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        double pctMod = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLigaJugador);
        long valorMercadoEfectivo = leaguePlayerMarketValueService.effectiveValueFromBase(valor, pctMod);
        LeaguePlayerMarketValueService.PlayerProtectionState ps =
                leaguePlayerMarketValueService.loadProtectionState(conn, idLigaJugador);

        return new LeaguePlayerDetailResponse(
                idLigaJugador,
                playerId,
                nombre,
                pila,
                posicion,
                valoracion,
                idEquipo,
                nombreEquipo,
                estado,
                cansancio,
                valor,
                valorAnterior,
                idUsuarioDueno,
                esMercado,
                enPoolMercado,
                enMercadoHoy,
                tieneOfertaPendiente,
                fotoJugador,
                puntosFantasyTotales,
                estadisticasJornadas,
                probabilidadTitular,
                motivoTitularidad,
                idPartidoProbabilidad,
                calculadoEnProbabilidad,
                valorMercadoEfectivo,
                pctMod > 0d,
                pctMod > 0d ? pctMod : null,
                ps.protegido(),
                ps.proteccionHastaFinTemporada(),
                ps.proteccionJornadaFin()
        );
    }
    }

    /**
     * Misma lógica que {@link #getLeaguePlayerDetail}: stats solo cuando el equipo ya “publicó” partido,
     * puntos desde rubrica si en BD van a 0 con minutos, y escalado lineal mientras EN_JUEGO.
     */
    private List<LeaguePlayerRoundStatsResponse> loadFantasyRoundStatsVisibleForPlayer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idEquipo,
            String posicion
    ) throws SQLException {
        String statsSql = """
        SELECT jo.id AS id_jornada,
               jo.numero AS numero_jornada,
               jo.estado AS estado_jornada,
               (SELECT pj.estado FROM partidos_jornada pj
                 INNER JOIN jornadas jj ON jj.id = pj.id_jornada
                 WHERE pj.id_jornada = jo.id
                   AND jj.id_liga = jo.id_liga
                   AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                 ORDER BY pj.inicio_en ASC, pj.id ASC LIMIT 1) AS equipo_match_estado,
               (SELECT pj.inicio_en FROM partidos_jornada pj
                 INNER JOIN jornadas jj ON jj.id = pj.id_jornada
                 WHERE pj.id_jornada = jo.id
                   AND jj.id_liga = jo.id_liga
                   AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                 ORDER BY pj.inicio_en ASC, pj.id ASC LIMIT 1) AS equipo_match_inicio,
               (SELECT pj.id FROM partidos_jornada pj
                 INNER JOIN jornadas jj ON jj.id = pj.id_jornada
                 WHERE pj.id_jornada = jo.id
                   AND jj.id_liga = jo.id_liga
                   AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                 ORDER BY pj.inicio_en ASC, pj.id ASC LIMIT 1) AS id_partido_equipo,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.minutos_jugados, 0) ELSE 0 END AS minutos_jugados,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.goles, 0) ELSE 0 END AS goles,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.asistencias, 0) ELSE 0 END AS asistencias,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.regates, 0) ELSE 0 END AS regates,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.balones_recuperados, 0) ELSE 0 END AS balones_recuperados,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.tarjetas_amarillas, 0) ELSE 0 END AS tarjetas_amarillas,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.tarjetas_rojas, 0) ELSE 0 END AS tarjetas_rojas,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.lesionado_en_partido, 0) ELSE 0 END AS lesionado_en_partido,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.puntos, 0) ELSE 0 END AS puntos,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN jp.nota_periodico ELSE NULL END AS nota_periodico,
               CASE WHEN COALESCE(vis.mostrar_stats, 0) = 1 THEN COALESCE(jp.goles_encajados, 0) ELSE 0 END AS goles_encajados,
               COALESCE(jp.paradas, 0) AS _paradas_raw,
               COALESCE(vis.mostrar_stats, 0) AS _stats_visibles
        FROM jornadas jo
        LEFT JOIN jugadores_puntos_jornada jp
               ON jp.id_jornada = jo.id
              AND jp.id_liga_jugador = ?
        LEFT JOIN (
            SELECT pj.id_jornada,
                   MAX(
                       CASE
                           WHEN pj.estado IN ('EN_JUEGO', 'FINALIZADO')
                            AND (pj.inicio_en IS NULL OR pj.inicio_en <= NOW())
                           THEN 1 ELSE 0 END
                   ) AS mostrar_stats
            FROM partidos_jornada pj
            INNER JOIN jornadas jj ON jj.id = pj.id_jornada
            WHERE jj.id_liga = ?
              AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
            GROUP BY pj.id_jornada
        ) vis ON vis.id_jornada = jo.id
        WHERE jo.id_liga = ?
        ORDER BY jo.numero ASC
        """;

        List<LeaguePlayerRoundStatsResponse> estadisticasJornadas = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(statsSql)) {
            int ix = 1;
            for (int r = 0; r < 3; r++) {
                ps.setLong(ix++, idEquipo);
                ps.setLong(ix++, idEquipo);
            }
            ps.setLong(ix++, idLigaJugador);
            ps.setLong(ix++, idLiga);
            ps.setLong(ix++, idEquipo);
            ps.setLong(ix++, idEquipo);
            ps.setLong(ix++, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int statsFlag = rs.getInt("_stats_visibles");
                    boolean statsVisibles = statsFlag == 1;

                    int minutos = rs.getInt("minutos_jugados");
                    int goles = rs.getInt("goles");
                    int asistencias = rs.getInt("asistencias");
                    int regates = rs.getInt("regates");
                    int recuperaciones = rs.getInt("balones_recuperados");
                    int amarillas = rs.getInt("tarjetas_amarillas");
                    int rojas = rs.getInt("tarjetas_rojas");
                    boolean lesionadoPartido = rs.getInt("lesionado_en_partido") > 0;
                    int puntosRow = rs.getInt("puntos");
                    Integer notaPeriodico = rs.getObject("nota_periodico", Integer.class);
                    int golesEnc = rs.getInt("goles_encajados");
                    int paradasRaw = rs.getInt("_paradas_raw");

                    int paradas = statsVisibles ? paradasRaw : 0;

                    int jpMinOrig = minutos;
                    int jpGcOrigDb = golesEnc;

                    String equipoMatchEstado = rs.getString("equipo_match_estado");
                    Timestamp equipoKickTs = rs.getTimestamp("equipo_match_inicio");
                    Instant equipoKickoff = equipoKickTs == null ? null : equipoKickTs.toInstant();
                    Long idPartidoEquipo = rs.getObject("id_partido_equipo", Long.class);

                    if (statsVisibles
                            && "EN_JUEGO".equals(equipoMatchEstado)
                            && equipoKickoff != null
                            && idPartidoEquipo != null) {
                        long elapsed = LeagueMatchLiveFantasyMask.elapsedVisibleSeconds(equipoKickoff);
                        List<LeagueMatchEventResponse> allEv =
                                LeagueMatchLiveFantasyMask.loadMatchEvents(conn, idPartidoEquipo);
                        List<LeagueMatchEventResponse> visEv =
                                LeagueMatchLiveFantasyMask.filterEventsVisibleNow(allEv, elapsed, false);

                        LeagueMatchLiveFantasyMask.LiveVisibleDerivedCounts d =
                                LeagueMatchLiveFantasyMask.deriveVisibleCounts(idLigaJugador, visEv);
                        goles = d.goals();
                        asistencias = d.assists();
                        regates = d.regates();
                        recuperaciones = d.recoveries();
                        paradas = d.saves();
                        rojas = d.reds();
                        lesionadoPartido = d.injuredInMatch();
                        amarillas = 0;

                        Map<Long, Long> ljCatProbe = new HashMap<>();
                        ljCatProbe.put(idLigaJugador, idEquipo);
                        int oppVis = LeagueMatchLiveFantasyMask.countVisibleOppositionGoals(conn, visEv, idEquipo, ljCatProbe);
                        golesEnc = LeagueMatchLiveFantasyMask.visibleConcededGoalsCap(posicion, jpGcOrigDb, oppVis);

                        LeagueMatchLiveFantasyMask.JpPersistentStats jpForMin = new LeagueMatchLiveFantasyMask.JpPersistentStats(
                                0,
                                jpMinOrig,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                false,
                                null
                        );
                        minutos = LeagueMatchLiveFantasyMask.visibleMinutesCap(jpForMin, equipoKickoff, equipoMatchEstado);
                        notaPeriodico = null;
                    }

                    FantasyPointsBreakdownCalculator.Breakdown desglose = statsVisibles
                            ? fantasyBreakdownLikeSimulation(
                                    posicion,
                                    minutos,
                                    goles,
                                    asistencias,
                                    regates,
                                    recuperaciones,
                                    paradas,
                                    golesEnc,
                                    amarillas,
                                    rojas,
                                    lesionadoPartido,
                                    notaPeriodico
                            )
                            : new FantasyPointsBreakdownCalculator.Breakdown(
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

                    if (statsVisibles) {
                        puntosRow = desglose.total();
                    }

                    estadisticasJornadas.add(new LeaguePlayerRoundStatsResponse(
                            rs.getLong("id_jornada"),
                            rs.getInt("numero_jornada"),
                            rs.getString("estado_jornada"),
                            minutos,
                            goles,
                            asistencias,
                            regates,
                            recuperaciones,
                            amarillas,
                            rojas,
                            lesionadoPartido,
                            puntosRow,
                            FantasyPointsBreakdownCalculator.toResponse(desglose),
                            notaPeriodico,
                            golesEnc,
                            statsVisibles ? paradas : 0
                    ));
                }
            }
        }

        return estadisticasJornadas;
    }

    /** Total fantasy alineado con la suma de jornadas del perfil (GET …/players/{id}). */
    public int sumFantasyPointsVisibleForPlayer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idEquipo,
            String posicion
    ) throws SQLException {
        return loadFantasyRoundStatsVisibleForPlayer(conn, idLiga, idLigaJugador, idEquipo, posicion).stream()
                .mapToInt(s -> s.puntos() == null ? 0 : s.puntos())
                .sum();
    }

    public List<LeagueUnavailablePlayerResponse> getUnavailablePlayers(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
            normalizeExpiredUnavailablePlayersForLeague(conn, idLiga);

            String sql = """
                    SELECT
                      lj.id AS id_liga_jugador,
                      lj.id_jugador,
                      j.nombre,
                      j.pila,
                      j.foto AS foto_jugador,
                      j.posicion,
                      lj.id_equipo,
                      e.nombre AS nombre_equipo,
                      lj.estado,
                      lj.lesionado_hasta,
                      lj.sancionado_hasta,
                      CASE
                        WHEN lj.estado = 'LESIONADO' THEN lj.lesionado_hasta
                        WHEN lj.estado = 'SANCIONADO' THEN lj.sancionado_hasta
                        ELSE NULL
                      END AS disponible_desde
                    FROM liga_jugadores lj
                    JOIN jugadores j ON j.id = lj.id_jugador
                    JOIN equipos e ON e.id = lj.id_equipo
                    WHERE lj.id_liga = ?
                      AND lj.estado IN ('LESIONADO', 'SANCIONADO')
                      AND (
                        (lj.estado = 'LESIONADO' AND lj.lesionado_hasta IS NOT NULL AND lj.lesionado_hasta > NOW())
                        OR
                        (lj.estado = 'SANCIONADO' AND lj.sancionado_hasta IS NOT NULL AND lj.sancionado_hasta > NOW())
                      )
                    ORDER BY disponible_desde ASC, e.nombre ASC, j.nombre ASC
                    """;

            List<LeagueUnavailablePlayerResponse> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp lesionadoHastaTs = rs.getTimestamp("lesionado_hasta");
                        Instant lesionadoHasta = lesionadoHastaTs == null ? null : lesionadoHastaTs.toInstant();

                        Timestamp sancionadoHastaTs = rs.getTimestamp("sancionado_hasta");
                        Instant sancionadoHasta = sancionadoHastaTs == null ? null : sancionadoHastaTs.toInstant();

                        Timestamp disponibleDesdeTs = rs.getTimestamp("disponible_desde");
                        Instant disponibleDesde = disponibleDesdeTs == null ? null : disponibleDesdeTs.toInstant();

                        UpcomingRoundRef upcoming = loadUpcomingRoundForTeam(conn, idLiga, rs.getLong("id_equipo"), disponibleDesde);
                        String textoDisponibilidad = upcoming == null
                                ? "Sin jornada disponible"
                                : "Disponible para la jornada " + upcoming.numeroJornada();

                        rows.add(new LeagueUnavailablePlayerResponse(
                                rs.getLong("id_liga_jugador"),
                                rs.getLong("id_jugador"),
                                rs.getString("nombre"),
                                rs.getString("pila"),
                                LeagueAssetUrls.player(rs.getLong("id_jugador")),
                                rs.getString("posicion"),
                                rs.getLong("id_equipo"),
                                rs.getString("nombre_equipo"),
                                rs.getString("estado"),
                                lesionadoHasta,
                                sancionadoHasta,
                                disponibleDesde,
                                upcoming == null ? null : upcoming.idJornada(),
                                upcoming == null ? null : upcoming.numeroJornada(),
                                textoDisponibilidad
                        ));
                    }
                }
            }

            Set<Long> seenLigaJugadorIds = new HashSet<>();
            for (LeagueUnavailablePlayerResponse r : rows) {
                seenLigaJugadorIds.add(r.idLigaJugador());
            }

            /*
             * partido_efectos_jugador se escribe con el resultado completo del simulador aunque el partido
             * siga EN_JUEGO en pantalla; solo mostramos baja si ya “salió” el evento (minuto ≤ tiempo visible).
             */
            String pendSql = """
                    SELECT pe.id_liga_jugador,
                           pe.estado_final,
                           pe.lesionado_hasta,
                           pe.sancionado_hasta,
                           lj.id_jugador,
                           j.nombre,
                           j.pila,
                           j.foto AS foto_jugador,
                           j.posicion,
                           lj.id_equipo,
                           e.nombre AS nombre_equipo
                    FROM partido_efectos_jugador pe
                    INNER JOIN partidos_jornada pj ON pj.id = pe.id_partido_jornada
                    INNER JOIN jornadas jo ON jo.id = pj.id_jornada
                    INNER JOIN liga_jugadores lj ON lj.id = pe.id_liga_jugador AND lj.id_liga = jo.id_liga
                    INNER JOIN jugadores j ON j.id = lj.id_jugador
                    INNER JOIN equipos e ON e.id = lj.id_equipo
                    WHERE jo.id_liga = ?
                      AND pj.estado = 'EN_JUEGO'
                      AND pe.estado_final IN ('LESIONADO', 'SANCIONADO')
                      AND pj.inicio_en IS NOT NULL
                      AND EXISTS (
                          SELECT 1
                          FROM partido_eventos pev
                          WHERE pev.id_partido_jornada = pj.id
                            AND pev.id_liga_jugador = pe.id_liga_jugador
                            AND (
                                 (pe.estado_final = 'LESIONADO' AND pev.tipo = 'LESION')
                              OR (pe.estado_final = 'SANCIONADO' AND pev.tipo = 'TARJETA_ROJA')
                            )
                            AND (COALESCE(pev.minuto, 0) * 60 + COALESCE(pev.segundo, 0))
                                <= LEAST(
                                      GREATEST(TIMESTAMPDIFF(SECOND, pj.inicio_en, NOW()), 0),
                                      90 * 60
                                   )
                      )
                    """;

            try (PreparedStatement psPend = conn.prepareStatement(pendSql)) {
                psPend.setLong(1, idLiga);
                try (ResultSet rsPend = psPend.executeQuery()) {
                    while (rsPend.next()) {
                        long idLj = rsPend.getLong("id_liga_jugador");
                        if (seenLigaJugadorIds.contains(idLj)) {
                            continue;
                        }
                        seenLigaJugadorIds.add(idLj);

                        String estadoFinal = rsPend.getString("estado_final");
                        Timestamp lesionTs = rsPend.getTimestamp("lesionado_hasta");
                        Timestamp sancTs = rsPend.getTimestamp("sancionado_hasta");
                        Instant lesionadoHasta = lesionTs == null ? null : lesionTs.toInstant();
                        Instant sancionadoHasta = sancTs == null ? null : sancTs.toInstant();
                        Instant disponibleDesde =
                                "LESIONADO".equals(estadoFinal) ? lesionadoHasta : sancionadoHasta;

                        long idEquipoRow = rsPend.getLong("id_equipo");
                        UpcomingRoundRef upcoming =
                                loadUpcomingRoundForTeam(conn, idLiga, idEquipoRow, disponibleDesde);
                        String textoDisponibilidad = upcoming == null
                                ? "Sin jornada disponible"
                                : "Disponible para la jornada " + upcoming.numeroJornada();

                        rows.add(
                                new LeagueUnavailablePlayerResponse(
                                        idLj,
                                        rsPend.getLong("id_jugador"),
                                        rsPend.getString("nombre"),
                                        rsPend.getString("pila"),
                                        LeagueAssetUrls.player(rsPend.getLong("id_jugador")),
                                        rsPend.getString("posicion"),
                                        idEquipoRow,
                                        rsPend.getString("nombre_equipo"),
                                        estadoFinal,
                                        lesionadoHasta,
                                        sancionadoHasta,
                                        disponibleDesde,
                                        upcoming == null ? null : upcoming.idJornada(),
                                        upcoming == null ? null : upcoming.numeroJornada(),
                                        textoDisponibilidad));
                    }
                }
            }

            rows.sort(
                    Comparator.comparing(
                                    LeagueUnavailablePlayerResponse::disponibleDesde,
                                    Comparator.nullsLast(Comparator.naturalOrder()))
                            .thenComparing(LeagueUnavailablePlayerResponse::nombreEquipo)
                            .thenComparing(LeagueUnavailablePlayerResponse::nombre));

            return rows;
        }
    }

    public LeagueHomeFeedResponse getLeagueHomeFeed(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            List<LeagueHomeTopPlayerResponse> goleadores = loadTopScorers(conn, idLiga, 10);
            List<LeagueHomeTopPlayerResponse> asistidores = loadTopAssisters(conn, idLiga, 10);
            List<LeagueHomeTopPlayerResponse> porteriasCero = loadTopCleanSheetGoalkeepers(conn, idLiga, 10);

            Long idJornadaProb = leagueStarterProbabilityService.resolveTargetJornadaForProbabilities(conn, idLiga, null);
            if (idJornadaProb != null) {
                Set<Long> topIds = new HashSet<>();
                goleadores.forEach(r -> topIds.add(r.idLigaJugador()));
                asistidores.forEach(r -> topIds.add(r.idLigaJugador()));
                porteriasCero.forEach(r -> topIds.add(r.idLigaJugador()));
                if (!topIds.isEmpty()) {
                    Map<Long, StarterProbabilityLite> pm = leagueStarterProbabilityService.loadProbabilityMapForLeaguePlayers(
                            conn,
                            idLiga,
                            idJornadaProb,
                            topIds
                    );
                    goleadores = applyStarterProbToHomeTopPlayers(goleadores, pm);
                    asistidores = applyStarterProbToHomeTopPlayers(asistidores, pm);
                    porteriasCero = applyStarterProbToHomeTopPlayers(porteriasCero, pm);
                }
            }

            return new LeagueHomeFeedResponse(
                    idLiga,
                    loadLatestInjuryNews(conn, idLiga, 10),
                    goleadores,
                    asistidores,
                    porteriasCero
            );
        }
    }

    private List<LeagueHomeTopPlayerResponse> applyStarterProbToHomeTopPlayers(
            List<LeagueHomeTopPlayerResponse> rows,
            Map<Long, StarterProbabilityLite> prob
    ) {
        List<LeagueHomeTopPlayerResponse> out = new ArrayList<>();
        for (LeagueHomeTopPlayerResponse r : rows) {
            StarterProbabilityLite l = prob.get(r.idLigaJugador());
            out.add(
                    new LeagueHomeTopPlayerResponse(
                            r.idLigaJugador(),
                            r.idJugador(),
                            r.nombre(),
                            r.pila(),
                            r.nombreMostrado(),
                            r.posicion(),
                            r.valoracion(),
                            r.idEquipo(),
                            r.nombreEquipo(),
                            r.fotoJugador(),
                            r.fotoEquipo(),
                            r.total(),
                            l == null ? null : l.probabilidadTitular(),
                            l == null ? null : l.motivoTitularidad(),
                            l == null ? null : l.idPartidoProbabilidad(),
                            l == null ? null : l.calculadoEnProbabilidad()
                    )
            );
        }
        return out;
    }

    public List<LeagueTeamStandingRowResponse> getLeagueTeamStandings(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT le.id_equipo,
                           e.nombre AS nombre_equipo,
                           e.foto AS foto_equipo,
                           le.puntos,
                           le.victorias,
                           le.empates,
                           le.derrotas,
                           le.goles_favor,
                           le.goles_contra,
                           le.diferencia_goles
                    FROM liga_equipos le
                    INNER JOIN equipos e ON e.id = le.id_equipo
                    WHERE le.id_liga = ?
                    ORDER BY le.puntos DESC,
                             le.diferencia_goles DESC,
                             le.goles_favor DESC,
                             e.nombre ASC
                    """;

            List<LeagueTeamStandingRowResponse> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    int posicion = 1;

                    while (rs.next()) {
                        int victorias = rs.getInt("victorias");
                        int empates = rs.getInt("empates");
                        int derrotas = rs.getInt("derrotas");
                        int partidosJugados = victorias + empates + derrotas;

                        rows.add(new LeagueTeamStandingRowResponse(
                                posicion,
                                rs.getInt("id_equipo"),
                                rs.getString("nombre_equipo"),
                                LeagueAssetUrls.team(rs.getInt("id_equipo")),
                                partidosJugados,
                                victorias,
                                empates,
                                derrotas,
                                rs.getInt("goles_favor"),
                                rs.getInt("goles_contra"),
                                rs.getInt("diferencia_goles"),
                                rs.getInt("puntos")
                        ));
                        posicion++;
                    }
                }
            }

            return rows;
        }
    }

    public LeagueParticipantLineupHistoryResponse getParticipantLineupHistory(
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuarioSolicitante
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || idUsuarioSolicitante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuarioSolicitante);

            ParticipantTargetData participant = loadParticipantTarget(conn, idLiga, idLigaParticipante);
            if (participant == null) {
                throw new IllegalArgumentException("Participante no encontrado en la liga");
            }

            List<RoundHeaderDataLite> rounds = loadLeagueRoundsForHistory(conn, idLiga);
            Set<Long> savedRoundIds = loadSavedRoundIdsForParticipant(conn, idLigaParticipante);

            List<LeagueParticipantLineupHistoryRoundResponse> jornadas = new ArrayList<>();

            for (RoundHeaderDataLite round : rounds) {
                boolean alineacionDisponible = savedRoundIds.contains(round.idJornada());
                int puntosTotales = leagueLineupService.fantasyPointsForRoundHistoryAligned(
                        conn,
                        idLiga,
                        idLigaParticipante,
                        round.idJornada(),
                        round.estadoJornada(),
                        alineacionDisponible
                );

                jornadas.add(new LeagueParticipantLineupHistoryRoundResponse(
                        round.idJornada(),
                        round.numeroJornada(),
                        round.estadoJornada(),
                        round.inicioJornada(),
                        alineacionDisponible,
                        puntosTotales
                ));
            }

            return new LeagueParticipantLineupHistoryResponse(
                    idLiga,
                    idLigaParticipante,
                    participant.idUsuarioParticipante(),
                    participant.nickname(),
                    jornadas
            );
        }
    }

    public LeagueParticipantLineupRoundDetailResponse getParticipantLineupHistoryRoundDetail(
            Long idLiga,
            Long idLigaParticipante,
            Long idJornada,
            Long idUsuarioSolicitante
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || idJornada == null || idUsuarioSolicitante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuarioSolicitante);

            ParticipantTargetData participant = loadParticipantTarget(conn, idLiga, idLigaParticipante);
            if (participant == null) {
                throw new IllegalArgumentException("Participante no encontrado en la liga");
            }

            RoundHeaderDataLite round = loadRoundHeaderForHistory(conn, idLiga, idJornada);
            if (round == null) {
                throw new IllegalArgumentException("Jornada no encontrada");
            }

            LeagueLineupService.ParticipantRoundFrozenLineup frozenLineup =
                    leagueLineupService.getParticipantFrozenLineupForRound(conn, idLiga, idLigaParticipante, idJornada);
            if (frozenLineup == null) {
                throw new IllegalArgumentException("No hay alineación guardada para esa jornada");
            }

            List<Long> allIds = new ArrayList<>();
            allIds.addAll(frozenLineup.titularesIds());
            allIds.addAll(frozenLineup.reservasIds());

            Map<Long, PlayerLineupData> playerData = loadPlayerLineupDataByLeaguePlayerIds(conn, allIds);
            Map<Long, Integer> pointsByPlayer;
            Map<Long, FantasyPointsBreakdownCalculator.Breakdown> breakdownByPlayer;
            Map<Long, Integer> minutesByPlayer;
            Map<Long, Integer> concededGoalsByPlayer;
            Map<Long, Integer> paradasByPlayer;

            if ("PENDIENTE".equals(round.estadoJornada())) {
                pointsByPlayer = Collections.emptyMap();
                breakdownByPlayer = Collections.emptyMap();
                minutesByPlayer = Collections.emptyMap();
                concededGoalsByPlayer = Collections.emptyMap();
                paradasByPlayer = Collections.emptyMap();
            } else {
                pointsByPlayer = leagueLineupService.calculateRoundPointsByLeaguePlayer(conn, idJornada, allIds);
                breakdownByPlayer = leagueLineupService.calculateRoundBreakdownByLeaguePlayer(conn, idJornada, allIds);
                Map<Long, String> posicionesPorLj = leagueLineupService.loadPosicionesByLigaJugadorIds(conn, allIds);
                minutesByPlayer = loadRoundMinutesByLeaguePlayer(conn, idJornada, allIds);
                concededGoalsByPlayer =
                        loadRoundConcededGoalsByLeaguePlayer(conn, idJornada, allIds, posicionesPorLj);
                paradasByPlayer = loadRoundParadasByLeaguePlayer(conn, idJornada, allIds);
            }

            ParticipantRoundFantasyBreakdown fantasyBreakdown = "PENDIENTE".equals(round.estadoJornada())
                    ? new ParticipantRoundFantasyBreakdown(0, 0, 0, 0, Set.of(), Set.of())
                    : leagueLineupService.resolveParticipantRoundFantasyBreakdown(conn, idLiga, idLigaParticipante, idJornada);
            Set<Long> fantasyTitularesDescartados = fantasyBreakdown.fantasyTitularesDescartados();
            Set<Long> fantasyBanquilloPorSuplencia = fantasyBreakdown.fantasyBanquilloPorSuplencia();

            List<LeagueParticipantLineupRoundPlayerResponse> titulares = new ArrayList<>();
            List<LeagueParticipantLineupRoundPlayerResponse> reservas = new ArrayList<>();

            int ordenTitular = 1;
            for (Long idLigaJugador : frozenLineup.titularesIds()) {
                PlayerLineupData data = playerData.get(idLigaJugador);
                if (data == null) {
                    continue;
                }
                titulares.add(buildHistoryRoundPlayer(
                        idLigaJugador,
                        data,
                        true,
                        Objects.equals(frozenLineup.idCapitan(), idLigaJugador),
                        ordenTitular++,
                        pointsByPlayer.getOrDefault(idLigaJugador, 0),
                        breakdownByPlayer.get(idLigaJugador),
                        minutesByPlayer.getOrDefault(idLigaJugador, 0),
                        concededGoalsByPlayer.getOrDefault(idLigaJugador, 0),
                        paradasByPlayer.getOrDefault(idLigaJugador, 0),
                        fantasyTitularesDescartados.contains(idLigaJugador),
                        false
                ));
            }

            int ordenReserva = 1;
            for (Long idLigaJugador : frozenLineup.reservasIds()) {
                PlayerLineupData data = playerData.get(idLigaJugador);
                if (data == null) {
                    continue;
                }
                reservas.add(buildHistoryRoundPlayer(
                        idLigaJugador,
                        data,
                        false,
                        false,
                        ordenReserva++,
                        pointsByPlayer.getOrDefault(idLigaJugador, 0),
                        breakdownByPlayer.get(idLigaJugador),
                        minutesByPlayer.getOrDefault(idLigaJugador, 0),
                        concededGoalsByPlayer.getOrDefault(idLigaJugador, 0),
                        paradasByPlayer.getOrDefault(idLigaJugador, 0),
                        false,
                        fantasyBanquilloPorSuplencia.contains(idLigaJugador)
                ));
            }

            int puntosTotales = "PENDIENTE".equals(round.estadoJornada())
                    ? 0
                    : fantasyBreakdown.puntosTotales();

            LineupHistoryAjpcSnapshot ajpc = loadLineupHistoryAjpcSnapshot(conn, idJornada, idLigaParticipante).orElse(null);

            String formacionEfectiva;
            LeagueAssignedCoachResponse entrenadorAsignado = null;

            if (ajpc != null && ajpc.formacionEfectiva() != null && !ajpc.formacionEfectiva().isBlank()) {
                formacionEfectiva = ajpc.formacionEfectiva().trim();
            } else {
                formacionEfectiva = leagueLineupService.getFormationDisplayForRound(conn, idLigaParticipante, idJornada);
            }

            if (ajpc != null && ajpc.idEntrenadorUsado() != null) {
                int bonus = ajpc.bonusEntrenadorPorJugador() == null ? 0 : ajpc.bonusEntrenadorPorJugador();
                String fotoCoach = resolveCoachFotoForHistory(conn, ajpc.idEntrenadorUsado(), ajpc.entrenadorFotoSnapshot());
                int puntosEntrenadorJornada = leagueLineupService.calculateCoachRoundContributionPoints(
                        conn,
                        idJornada,
                        idLigaParticipante,
                        ajpc.entrenadorIdEquipoSnapshot(),
                        bonus,
                        Boolean.TRUE.equals(ajpc.entrenadorActivo()),
                        round.estadoJornada()
                );
                entrenadorAsignado = new LeagueAssignedCoachResponse(
                        ajpc.idEntrenadorUsado(),
                        ajpc.entrenadorNombreSnapshot(),
                        ajpc.entrenadorPilaSnapshot(),
                        formacionEfectiva,
                        fotoCoach,
                        ajpc.entrenadorIdEquipoSnapshot(),
                        ajpc.entrenadorEquipoNombreSnapshot(),
                        bonus,
                        Boolean.TRUE.equals(ajpc.entrenadorActivo()),
                        puntosEntrenadorJornada
                );
            }

            return new LeagueParticipantLineupRoundDetailResponse(
                    idLiga,
                    idLigaParticipante,
                    participant.idUsuarioParticipante(),
                    participant.nickname(),
                    idJornada,
                    round.numeroJornada(),
                    round.estadoJornada(),
                    round.inicioJornada(),
                    formacionEfectiva,
                    entrenadorAsignado,
                    puntosTotales,
                    fantasyBreakdown.puntosJugadoresFormacion(),
                    fantasyBreakdown.penalizacionHuecos(),
                    fantasyBreakdown.puntosEntrenador(),
                    frozenLineup.idCapitan(),
                    titulares,
                    reservas,
                    frozenLineup.emptySlots()
            );
        }
    }

    /** Snapshot tiene prioridad; si falta foto, se usa solo catálogo {@code entrenadores.foto} (no estado actual del participante). */
    private String resolveCoachFotoForHistory(Connection conn, Long idEntrenadorUsado, String fotoSnapshot) {
        if (idEntrenadorUsado == null) {
            return null;
        }
        return LeagueAssetUrls.coercePublicAsset(
                fotoSnapshot == null ? null : fotoSnapshot.trim(),
                LeagueAssetUrls.manager(idEntrenadorUsado)
        );
    }

    private Optional<LineupHistoryAjpcSnapshot> loadLineupHistoryAjpcSnapshot(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante
    ) throws SQLException {
        String sql = """
                SELECT id_entrenador_usado,
                       entrenador_activo,
                       entrenador_nombre_snapshot,
                       entrenador_pila_snapshot,
                       entrenador_foto_snapshot,
                       entrenador_id_equipo_snapshot,
                       entrenador_equipo_nombre_snapshot,
                       formacion_efectiva,
                       bonus_entrenador_por_jugador
                FROM alineacion_jornada_participante_config
                WHERE id_jornada = ?
                  AND id_liga_participante = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }

                Long idEntrenadorUsado = rs.getObject("id_entrenador_usado", Long.class);
                Boolean entrenadorActivo = rs.getObject("entrenador_activo", Boolean.class);
                Integer idEquipo = rs.getObject("entrenador_id_equipo_snapshot", Integer.class);
                Integer bonus = rs.getObject("bonus_entrenador_por_jugador", Integer.class);

                return Optional.of(
                        new LineupHistoryAjpcSnapshot(
                                idEntrenadorUsado,
                                entrenadorActivo,
                                rs.getString("entrenador_nombre_snapshot"),
                                rs.getString("entrenador_pila_snapshot"),
                                rs.getString("entrenador_foto_snapshot"),
                                idEquipo,
                                rs.getString("entrenador_equipo_nombre_snapshot"),
                                rs.getString("formacion_efectiva"),
                                bonus
                        )
                );
            }
        }
    }

    private record LineupHistoryAjpcSnapshot(
            Long idEntrenadorUsado,
            Boolean entrenadorActivo,
            String entrenadorNombreSnapshot,
            String entrenadorPilaSnapshot,
            String entrenadorFotoSnapshot,
            Integer entrenadorIdEquipoSnapshot,
            String entrenadorEquipoNombreSnapshot,
            String formacionEfectiva,
            Integer bonusEntrenadorPorJugador
    ) {
    }

    private ParticipantTargetData loadParticipantTarget(Connection conn, Long idLiga, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lp.id_usuario,
                       u.nickname
                FROM liga_participantes lp
                INNER JOIN usuarios u ON u.id = lp.id_usuario
                WHERE lp.id = ?
                  AND lp.id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new ParticipantTargetData(
                        rs.getLong("id_usuario"),
                        rs.getString("nickname")
                );
            }
        }
    }

    private List<RoundHeaderDataLite> loadLeagueRoundsForHistory(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id,
                       numero,
                       estado,
                       inicio_en
                FROM jornadas
                WHERE id_liga = ?
                ORDER BY numero ASC
                """;

        List<RoundHeaderDataLite> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp inicioTs = rs.getTimestamp("inicio_en");
                    rows.add(new RoundHeaderDataLite(
                            rs.getLong("id"),
                            rs.getInt("numero"),
                            rs.getString("estado"),
                            inicioTs == null ? null : inicioTs.toInstant()
                    ));
                }
            }
        }

        return rows;
    }

    private RoundHeaderDataLite loadRoundHeaderForHistory(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT id,
                       numero,
                       estado,
                       inicio_en
                FROM jornadas
                WHERE id = ?
                  AND id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Timestamp inicioTs = rs.getTimestamp("inicio_en");
                return new RoundHeaderDataLite(
                        rs.getLong("id"),
                        rs.getInt("numero"),
                        rs.getString("estado"),
                        inicioTs == null ? null : inicioTs.toInstant()
                );
            }
        }
    }

    private Set<Long> loadSavedRoundIdsForParticipant(Connection conn, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT DISTINCT id_jornada
                FROM alineacion_jornada_participante
                WHERE id_liga_participante = ?
                """;

        Set<Long> ids = new HashSet<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id_jornada"));
                }
            }
        }

        return ids;
    }

    private Map<Long, PlayerLineupData> loadPlayerLineupDataByLeaguePlayerIds(Connection conn, List<Long> ids) throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT lj.id AS id_liga_jugador,
                       lj.id_jugador,
                       j.nombre,
                       j.pila,
                       j.posicion,
                       CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                       lj.id_equipo,
                       e.nombre AS nombre_equipo,
                       e.foto AS foto_equipo,
                       j.foto AS foto_jugador,
                       lj.estado,
                       lj.cansancio,
                       lj.valor
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = lj.id_equipo
                WHERE lj.id IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, PlayerLineupData> rows = new LinkedHashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 1, ids.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.put(
                            rs.getLong("id_liga_jugador"),
                            new PlayerLineupData(
                                    rs.getLong("id_jugador"),
                                    rs.getString("nombre"),
                                    rs.getString("pila"),
                                    rs.getString("posicion"),
                                    rs.getInt("valoracion"),
                                    rs.getLong("id_equipo"),
                                    rs.getString("nombre_equipo"),
                                    LeagueAssetUrls.team(rs.getInt("id_equipo")),
                                    LeagueAssetUrls.player(rs.getLong("id_jugador")),
                                    rs.getString("estado"),
                                    rs.getInt("cansancio"),
                                    rs.getLong("valor")
                            )
                    );
                }
            }
        }

        return rows;
    }

    private Map<Long, Integer> loadRoundMinutesByLeaguePlayer(Connection conn, Long idJornada, List<Long> ids) throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT id_liga_jugador, minutos_jugados
                FROM jugadores_puntos_jornada
                WHERE id_jornada = ?
                  AND id_liga_jugador IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, Integer> raw = new HashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idJornada);
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 2, ids.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    raw.put(rs.getLong("id_liga_jugador"), rs.getInt("minutos_jugados"));
                }
            }
        }

        Map<Long, Long> catalogByLj = LeagueMatchLiveFantasyMask.catalogByLigaJugadorIds(conn, ids);
        Map<Long, LeagueMatchLiveFantasyMask.MatchAnchor> anchors =
                LeagueMatchLiveFantasyMask.anchorsByCatalogEquipo(conn, idJornada);
        Map<Long, Integer> minutesByPlayer = new HashMap<>();
        for (Long id : ids) {
            int m = raw.getOrDefault(id, 0);
            Long cat = catalogByLj.get(id);
            LeagueMatchLiveFantasyMask.MatchAnchor anchor = cat == null ? null : anchors.get(cat);
            if (anchor != null && "EN_JUEGO".equals(anchor.estado())) {
                LeagueMatchLiveFantasyMask.JpPersistentStats jpForMin = new LeagueMatchLiveFantasyMask.JpPersistentStats(
                        0, m, 0, 0, 0, 0, 0, 0, 0, 0, false, null);
                m = LeagueMatchLiveFantasyMask.visibleMinutesCap(jpForMin, anchor.kickoff(), anchor.estado());
            }
            minutesByPlayer.put(id, m);
        }
        return minutesByPlayer;
    }

    private Map<Long, Integer> loadRoundConcededGoalsByLeaguePlayer(
            Connection conn,
            Long idJornada,
            List<Long> ids,
            Map<Long, String> posicionPorLigaJugador
    ) throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT id_liga_jugador, goles_encajados
                FROM jugadores_puntos_jornada
                WHERE id_jornada = ?
                  AND id_liga_jugador IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, Integer> raw = new HashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idJornada);
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 2, ids.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    raw.put(rs.getLong("id_liga_jugador"), rs.getInt("goles_encajados"));
                }
            }
        }

        Map<Long, Long> catalogByLj = LeagueMatchLiveFantasyMask.catalogByLigaJugadorIds(conn, ids);
        Map<Long, LeagueMatchLiveFantasyMask.MatchAnchor> anchors =
                LeagueMatchLiveFantasyMask.anchorsByCatalogEquipo(conn, idJornada);
        Map<Long, List<LeagueMatchEventResponse>> eventsCache = new HashMap<>();
        Map<Long, Long> ljCatScratch = new HashMap<>(catalogByLj);

        Map<Long, Integer> concededByPlayer = new HashMap<>();
        for (Long id : ids) {
            int gc = raw.getOrDefault(id, 0);
            Long cat = catalogByLj.get(id);
            LeagueMatchLiveFantasyMask.MatchAnchor anchor = cat == null ? null : anchors.get(cat);
            String pos = posicionPorLigaJugador == null ? null : posicionPorLigaJugador.get(id);
            if (anchor != null && "EN_JUEGO".equals(anchor.estado()) && anchor.kickoff() != null) {
                long elapsed = LeagueMatchLiveFantasyMask.elapsedVisibleSeconds(anchor.kickoff());
                List<LeagueMatchEventResponse> allEv = eventsCache.get(anchor.idPartido());
                if (allEv == null) {
                    allEv = LeagueMatchLiveFantasyMask.loadMatchEvents(conn, anchor.idPartido());
                    eventsCache.put(anchor.idPartido(), allEv);
                }
                List<LeagueMatchEventResponse> visEv =
                        LeagueMatchLiveFantasyMask.filterEventsVisibleNow(allEv, elapsed, false);
                int oppVis = LeagueMatchLiveFantasyMask.countVisibleOppositionGoals(conn, visEv, cat, ljCatScratch);
                gc = LeagueMatchLiveFantasyMask.visibleConcededGoalsCap(pos == null ? "" : pos, gc, oppVis);
            }
            concededByPlayer.put(id, gc);
        }
        return concededByPlayer;
    }

    private Map<Long, Integer> loadRoundParadasByLeaguePlayer(Connection conn, Long idJornada, List<Long> ids)
            throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT id_liga_jugador, paradas
                FROM jugadores_puntos_jornada
                WHERE id_jornada = ?
                  AND id_liga_jugador IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, Integer> raw = new HashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idJornada);
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 2, ids.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    raw.put(rs.getLong("id_liga_jugador"), rs.getInt("paradas"));
                }
            }
        }

        Map<Long, Long> catalogByLj = LeagueMatchLiveFantasyMask.catalogByLigaJugadorIds(conn, ids);
        Map<Long, LeagueMatchLiveFantasyMask.MatchAnchor> anchors =
                LeagueMatchLiveFantasyMask.anchorsByCatalogEquipo(conn, idJornada);
        Map<Long, List<LeagueMatchEventResponse>> eventsCache = new HashMap<>();

        Map<Long, Integer> paradasByPlayer = new HashMap<>();
        for (Long id : ids) {
            int p = raw.getOrDefault(id, 0);
            Long cat = catalogByLj.get(id);
            LeagueMatchLiveFantasyMask.MatchAnchor anchor = cat == null ? null : anchors.get(cat);
            if (anchor != null && "EN_JUEGO".equals(anchor.estado()) && anchor.kickoff() != null) {
                long elapsed = LeagueMatchLiveFantasyMask.elapsedVisibleSeconds(anchor.kickoff());
                List<LeagueMatchEventResponse> allEv = eventsCache.get(anchor.idPartido());
                if (allEv == null) {
                    allEv = LeagueMatchLiveFantasyMask.loadMatchEvents(conn, anchor.idPartido());
                    eventsCache.put(anchor.idPartido(), allEv);
                }
                List<LeagueMatchEventResponse> visEv =
                        LeagueMatchLiveFantasyMask.filterEventsVisibleNow(allEv, elapsed, false);
                p = LeagueMatchLiveFantasyMask.deriveVisibleCounts(id, visEv).saves();
            }
            paradasByPlayer.put(id, p);
        }
        return paradasByPlayer;
    }

    private LeagueParticipantLineupRoundPlayerResponse buildHistoryRoundPlayer(
            Long idLigaJugador,
            PlayerLineupData data,
            boolean titular,
            boolean capitan,
            int orden,
            int puntosJornada,
            FantasyPointsBreakdownCalculator.Breakdown puntosDesglose,
            int minutosJugados,
            int golesEncajados,
            int paradasJornada,
            boolean fantasyTitularSinConteoPorBanquillo,
            boolean fantasyBanquilloContandoPorSuplencia
    ) {
        return new LeagueParticipantLineupRoundPlayerResponse(
                idLigaJugador,
                data.idJugador(),
                data.nombre(),
                data.pila(),
                buildPlayerDisplayName(data.nombre(), data.pila()),
                data.posicion(),
                data.valoracion(),
                data.idEquipo(),
                data.nombreEquipo(),
                data.fotoEquipo(),
                data.fotoJugador(),
                data.estado(),
                data.cansancio(),
                data.valor(),
                titular,
                capitan,
                orden,
                puntosJornada,
                puntosDesglose == null ? null : FantasyPointsBreakdownCalculator.toResponse(puntosDesglose),
                minutosJugados,
                golesEncajados,
                paradasJornada,
                fantasyTitularSinConteoPorBanquillo,
                fantasyBanquilloContandoPorSuplencia
        );
    }

    private List<LeagueHomeNewsItemResponse> loadLatestInjuryNews(Connection conn, Long idLiga, int limit) throws SQLException {
    String sql = """
            SELECT pe.id AS id_evento,
                   pe.id_partido_jornada AS id_partido,
                   j.id AS id_jornada,
                   j.numero AS numero_jornada,
                   pj.inicio_en AS inicio_partido,
                   pe.minuto,
                   pe.segundo,
                   pe.tipo,
                   pe.texto,
                   lj.id AS id_liga_jugador,
                   ju.id AS id_jugador,
                   ju.nombre,
                   ju.pila,
                   ju.foto AS foto_jugador,
                   eq.id AS id_equipo,
                   eq.nombre AS nombre_equipo,
                   eq.foto AS foto_equipo,
                   lj.lesionado_hasta,
                   CASE
                       WHEN lj.estado = 'LESIONADO'
                        AND lj.lesionado_hasta IS NOT NULL
                        AND lj.lesionado_hasta > NOW()
                       THEN TRUE
                       ELSE FALSE
                   END AS lesion_activa
            FROM partido_eventos pe
            INNER JOIN partidos_jornada pj ON pj.id = pe.id_partido_jornada
            INNER JOIN jornadas j ON j.id = pj.id_jornada
            INNER JOIN liga_jugadores lj ON lj.id = pe.id_liga_jugador
            INNER JOIN jugadores ju ON ju.id = lj.id_jugador
            INNER JOIN equipos eq ON eq.id = lj.id_equipo
            WHERE j.id_liga = ?
              AND pe.tipo = 'LESION'
            ORDER BY pj.inicio_en DESC, pe.minuto DESC, pe.segundo DESC, pe.id DESC
            LIMIT ?
            """;

    List<LeagueHomeNewsItemResponse> rows = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLiga);
        ps.setInt(2, limit);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Timestamp inicioPartidoTs = rs.getTimestamp("inicio_partido");
                Instant inicioPartido = inicioPartidoTs == null ? null : inicioPartidoTs.toInstant();

                Timestamp lesionadoHastaTs = rs.getTimestamp("lesionado_hasta");
                Instant lesionadoHasta = lesionadoHastaTs == null ? null : lesionadoHastaTs.toInstant();

                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");

                rows.add(new LeagueHomeNewsItemResponse(
                        rs.getLong("id_evento"),
                        rs.getLong("id_partido"),
                        rs.getLong("id_jornada"),
                        rs.getInt("numero_jornada"),
                        inicioPartido,
                        rs.getInt("minuto"),
                        rs.getInt("segundo"),
                        rs.getString("tipo"),
                        rs.getString("texto"),
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_jugador"),
                        nombre,
                        pila,
                        buildPlayerDisplayName(nombre, pila),
                        LeagueAssetUrls.player(rs.getLong("id_jugador")),
                        rs.getLong("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.team(rs.getLong("id_equipo")),
                        lesionadoHasta,
                        rs.getBoolean("lesion_activa")
                ));
            }
        }
    }

    return rows;
}

private List<LeagueHomeTopPlayerResponse> loadTopScorers(Connection conn, Long idLiga, int limit) throws SQLException {
    String sql = """
            SELECT lj.id AS id_liga_jugador,
                   ju.id AS id_jugador,
                   ju.nombre,
                   ju.pila,
                   ju.posicion,
                   CAST(ROUND(COALESCE(lj.valoracion_actual, ju.valoracion), 0) AS SIGNED) AS valoracion,
                   eq.id AS id_equipo,
                   eq.nombre AS nombre_equipo,
                   ju.foto AS foto_jugador,
                   eq.foto AS foto_equipo,
                   COALESCE(SUM(jp.goles), 0) AS total
            FROM jugadores_puntos_jornada jp
            INNER JOIN liga_jugadores lj ON lj.id = jp.id_liga_jugador
            INNER JOIN jugadores ju ON ju.id = lj.id_jugador
            INNER JOIN equipos eq ON eq.id = lj.id_equipo
            WHERE lj.id_liga = ?
            GROUP BY lj.id, ju.id, ju.nombre, ju.pila, ju.posicion,
                     lj.valoracion_actual, ju.valoracion,
                     eq.id, eq.nombre, ju.foto, eq.foto
            HAVING COALESCE(SUM(jp.goles), 0) > 0
            ORDER BY total DESC, COALESCE(SUM(jp.puntos), 0) DESC, ju.nombre ASC
            LIMIT ?
            """;

    List<LeagueHomeTopPlayerResponse> rows = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLiga);
        ps.setInt(2, limit);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");

                rows.add(new LeagueHomeTopPlayerResponse(
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_jugador"),
                        nombre,
                        pila,
                        buildPlayerDisplayName(nombre, pila),
                        rs.getString("posicion"),
                        rs.getInt("valoracion"),
                        rs.getLong("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.player(rs.getLong("id_jugador")),
                        LeagueAssetUrls.team(rs.getLong("id_equipo")),
                        rs.getInt("total"),
                        null,
                        null,
                        null,
                        null
                ));
            }
        }
    }

    return rows;
}

private List<LeagueHomeTopPlayerResponse> loadTopAssisters(Connection conn, Long idLiga, int limit) throws SQLException {
    String sql = """
            SELECT lj.id AS id_liga_jugador,
                   ju.id AS id_jugador,
                   ju.nombre,
                   ju.pila,
                   ju.posicion,
                   CAST(ROUND(COALESCE(lj.valoracion_actual, ju.valoracion), 0) AS SIGNED) AS valoracion,
                   eq.id AS id_equipo,
                   eq.nombre AS nombre_equipo,
                   ju.foto AS foto_jugador,
                   eq.foto AS foto_equipo,
                   COALESCE(SUM(jp.asistencias), 0) AS total
            FROM jugadores_puntos_jornada jp
            INNER JOIN liga_jugadores lj ON lj.id = jp.id_liga_jugador
            INNER JOIN jugadores ju ON ju.id = lj.id_jugador
            INNER JOIN equipos eq ON eq.id = lj.id_equipo
            WHERE lj.id_liga = ?
            GROUP BY lj.id, ju.id, ju.nombre, ju.pila, ju.posicion,
                     lj.valoracion_actual, ju.valoracion,
                     eq.id, eq.nombre, ju.foto, eq.foto
            HAVING COALESCE(SUM(jp.asistencias), 0) > 0
            ORDER BY total DESC, COALESCE(SUM(jp.puntos), 0) DESC, ju.nombre ASC
            LIMIT ?
            """;

    List<LeagueHomeTopPlayerResponse> rows = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLiga);
        ps.setInt(2, limit);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");

                rows.add(new LeagueHomeTopPlayerResponse(
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_jugador"),
                        nombre,
                        pila,
                        buildPlayerDisplayName(nombre, pila),
                        rs.getString("posicion"),
                        rs.getInt("valoracion"),
                        rs.getLong("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.player(rs.getLong("id_jugador")),
                        LeagueAssetUrls.team(rs.getLong("id_equipo")),
                        rs.getInt("total"),
                        null,
                        null,
                        null,
                        null
                ));
            }
        }
    }

    return rows;
}

private List<LeagueHomeTopPlayerResponse> loadTopCleanSheetGoalkeepers(Connection conn, Long idLiga, int limit) throws SQLException {
    String sql = """
            SELECT lj.id AS id_liga_jugador,
                   ju.id AS id_jugador,
                   ju.nombre,
                   ju.pila,
                   ju.posicion,
                   CAST(ROUND(COALESCE(lj.valoracion_actual, ju.valoracion), 0) AS SIGNED) AS valoracion,
                   eq.id AS id_equipo,
                   eq.nombre AS nombre_equipo,
                   ju.foto AS foto_jugador,
                   eq.foto AS foto_equipo,
                   COALESCE(SUM(jp.porteria_cero), 0) AS total
            FROM jugadores_puntos_jornada jp
            INNER JOIN liga_jugadores lj ON lj.id = jp.id_liga_jugador
            INNER JOIN jugadores ju ON ju.id = lj.id_jugador
            INNER JOIN equipos eq ON eq.id = lj.id_equipo
            WHERE lj.id_liga = ?
              AND ju.posicion = 'POR'
            GROUP BY lj.id, ju.id, ju.nombre, ju.pila, ju.posicion,
                     lj.valoracion_actual, ju.valoracion,
                     eq.id, eq.nombre, ju.foto, eq.foto
            HAVING COALESCE(SUM(jp.porteria_cero), 0) > 0
            ORDER BY total DESC, COALESCE(SUM(jp.paradas), 0) DESC, ju.nombre ASC
            LIMIT ?
            """;

    List<LeagueHomeTopPlayerResponse> rows = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLiga);
        ps.setInt(2, limit);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");

                rows.add(new LeagueHomeTopPlayerResponse(
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_jugador"),
                        nombre,
                        pila,
                        buildPlayerDisplayName(nombre, pila),
                        rs.getString("posicion"),
                        rs.getInt("valoracion"),
                        rs.getLong("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.player(rs.getLong("id_jugador")),
                        LeagueAssetUrls.team(rs.getLong("id_equipo")),
                        rs.getInt("total"),
                        null,
                        null,
                        null,
                        null
                ));
            }
        }
    }

    return rows;
}


    public LeagueLiveMatchResponse getLeagueLiveMatch(Long idLiga, Long idPartido, Long idUsuario) throws SQLException {
    if (idLiga == null || idPartido == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        MatchHeaderData matchHeader = loadMatchHeader(conn, idLiga, idPartido);
        if (matchHeader == null) {
            throw new IllegalArgumentException("Partido no encontrado");
        }

        LineupBundle lineupBundle = loadMatchLineups(
                conn,
                matchHeader.idPartido(),
                matchHeader.idLigaEquipoLocal(),
                matchHeader.idLigaEquipoVisitante()
        );

        VisibleMatchProjection projection = buildVisibleMatchProjection(conn, matchHeader, lineupBundle);

        MatchDisplayFormacionesEntrenadores formacionCoach = buildMatchFormacionesYEntrenadores(conn, matchHeader, lineupBundle);

        return new LeagueLiveMatchResponse(
                matchHeader.idPartido(),
                matchHeader.idLiga(),
                matchHeader.idJornada(),
                matchHeader.numeroJornada(),
                matchHeader.inicioJornada(),
                matchHeader.inicioPartido(),
                matchHeader.estado(),
                projection.estadoVisible(),
                projection.enDirecto(),
                projection.minutoActual(),
                projection.segundoActual(),
                matchHeader.idLigaEquipoLocal(),
                matchHeader.idEquipoLocal(),
                matchHeader.nombreEquipoLocal(),
                matchHeader.fotoEquipoLocal(),
                projection.golesLocal(),
                matchHeader.idLigaEquipoVisitante(),
                matchHeader.idEquipoVisitante(),
                matchHeader.nombreEquipoVisitante(),
                matchHeader.fotoEquipoVisitante(),
                projection.golesVisitante(),
                formacionCoach.formacionLocal(),
                formacionCoach.alineacionLocal(),
                formacionCoach.entrenadorLocal(),
                formacionCoach.formacionVisitante(),
                formacionCoach.alineacionVisitante(),
                formacionCoach.entrenadorVisitante(),
                projection.idLigaEquipoGanadorVisible(),
                projection.empateVisible(),
                lineupBundle.titularesLocal(),
                lineupBundle.suplentesLocal(),
                lineupBundle.titularesVisitante(),
                lineupBundle.suplentesVisitante(),
                projection.eventosVisibles()
        );
    }
    }

    public List<LeagueMarketPlayerResponse> listLeagueMarketPlayers(
            Long idLiga,
            Long idUsuario,
            Long teamId,
            Long ownerId,
            String position,
            String search,
            Long idJornadaContext
    ) throws SQLException {
    if (idLiga == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT ");
        sql.append(" lj.id AS id_liga_jugador,");
        sql.append(" lj.id_liga,");
        sql.append(" lj.id_jugador,");
        sql.append(" lj.id_equipo,");
        sql.append(" e.nombre AS nombre_equipo,");
        sql.append(" e.foto AS foto_equipo,");
        sql.append(" j.nombre,");
        sql.append(" j.pila,");
        sql.append(" j.dorsal,");
        sql.append(" j.descripcion,");
        sql.append(" CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,");
        sql.append(" j.genero,");
        sql.append(" j.posicion,");
        sql.append(" j.foto AS foto_jugador,");
        sql.append(" lj.estado,");
        sql.append(" lj.cansancio,");
        sql.append(" lj.valor,");
        sql.append(" lj.valor_anterior,");
        sql.append(" lj.adquirido_en,");
        sql.append(" lj.id_usuario_dueno,");
        sql.append(" CASE ");
        sql.append("   WHEN lj.id_usuario_dueno = ? THEN 'Mercado' ");
        sql.append("   ELSE COALESCE(u.nickname, '') ");
        sql.append(" END AS nombre_dueno_visible,");
        sql.append(" CASE ");
        sql.append("   WHEN lj.id_usuario_dueno = ? THEN TRUE ");
        sql.append("   ELSE FALSE ");
        sql.append(" END AS es_mercado,");
        sql.append(" CASE ");
        sql.append("   WHEN lj.id_usuario_dueno = ? ");
        sql.append("    AND EXISTS (");
        sql.append("       SELECT 1 FROM ofertas_jugador oj");
        sql.append("       WHERE oj.id_liga = lj.id_liga");
        sql.append("         AND oj.id_liga_jugador = lj.id");
        sql.append("         AND oj.estado = 'PENDIENTE'");
        sql.append("    ) THEN TRUE ");
        sql.append("   ELSE FALSE ");
        sql.append(" END AS tiene_oferta_pendiente");
        sql.append(" FROM liga_jugadores lj");
        sql.append(" INNER JOIN jugadores j ON j.id = lj.id_jugador");
        sql.append(" INNER JOIN equipos e ON e.id = lj.id_equipo");
        sql.append(" LEFT JOIN usuarios u ON u.id = lj.id_usuario_dueno");
        sql.append(" WHERE lj.id_liga = ?");

        List<Object> params = new ArrayList<>();
        params.add(MERCADO_USER_ID);
        params.add(MERCADO_USER_ID);
        params.add(idUsuario);
        params.add(idLiga);

        if (teamId != null) {
            sql.append(" AND lj.id_equipo = ?");
            params.add(teamId);
        }

        if (ownerId != null) {
            sql.append(" AND lj.id_usuario_dueno = ?");
            params.add(ownerId);
        }

        if (position != null && !position.isBlank()) {
            sql.append(" AND j.posicion = ?");
            params.add(position.trim());
        }

        if (search != null && !search.isBlank()) {
            sql.append(" AND (j.nombre LIKE ? OR j.pila LIKE ?)");
            String like = "%" + search.trim() + "%";
            params.add(like);
            params.add(like);
        }

        sql.append(" ORDER BY");
        sql.append(" e.nombre ASC,");
        sql.append(" CASE j.posicion");
        sql.append("   WHEN 'POR' THEN 1");
        sql.append("   WHEN 'DEF' THEN 2");
        sql.append("   WHEN 'MED' THEN 3");
        sql.append("   WHEN 'DEL' THEN 4");
        sql.append("   ELSE 5");
        sql.append(" END ASC,");
        sql.append(" lj.valor DESC,");
        sql.append(" j.nombre ASC");

        List<LeagueMarketPlayerResponse> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp adquiridoTs = rs.getTimestamp("adquirido_en");
                    Instant adquiridoEn = adquiridoTs == null ? null : adquiridoTs.toInstant();

                    int dorsalVal = rs.getInt("dorsal");
                    boolean dorsalWasNull = rs.wasNull();

                    rows.add(new LeagueMarketPlayerResponse(
                            rs.getLong("id_liga_jugador"),
                            rs.getLong("id_liga"),
                            rs.getLong("id_jugador"),
                            rs.getLong("id_equipo"),
                            rs.getString("nombre_equipo"),
                            LeagueAssetUrls.team(rs.getLong("id_equipo")),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            dorsalWasNull ? null : dorsalVal,
                            rs.getString("descripcion"),
                            rs.getInt("valoracion"),
                            rs.getString("genero"),
                            rs.getString("posicion"),
                            LeagueAssetUrls.player(rs.getLong("id_jugador")),
                            rs.getString("estado"),
                            rs.getInt("cansancio"),
                            rs.getLong("valor"),
                            rs.getLong("valor_anterior"),
                            adquiridoEn,
                            rs.getLong("id_usuario_dueno"),
                            rs.getString("nombre_dueno_visible"),
                            rs.getBoolean("es_mercado"),
                            rs.getBoolean("tiene_oferta_pendiente"),
                            null,
                            null,
                            null,
                            null
                    ));
                }
            }
        }

        Long idJornadaProb = leagueStarterProbabilityService.resolveTargetJornadaForProbabilities(conn, idLiga, idJornadaContext);
        if (idJornadaProb == null || rows.isEmpty()) {
            return rows;
        }
        List<Long> ljIds = rows.stream().map(LeagueMarketPlayerResponse::idLigaJugador).toList();
        Map<Long, StarterProbabilityLite> probMap =
                leagueStarterProbabilityService.loadProbabilityMapForLeaguePlayers(conn, idLiga, idJornadaProb, ljIds);
        List<LeagueMarketPlayerResponse> enriched = new ArrayList<>();
        for (LeagueMarketPlayerResponse r : rows) {
            StarterProbabilityLite l = probMap.get(r.idLigaJugador());
            enriched.add(
                    new LeagueMarketPlayerResponse(
                            r.idLigaJugador(),
                            r.idLiga(),
                            r.idJugador(),
                            r.idEquipo(),
                            r.nombreEquipo(),
                            r.fotoEquipo(),
                            r.nombre(),
                            r.pila(),
                            r.dorsal(),
                            r.descripcion(),
                            r.valoracion(),
                            r.genero(),
                            r.posicion(),
                            r.fotoJugador(),
                            r.estado(),
                            r.cansancio(),
                            r.valor(),
                            r.valorAnterior(),
                            r.adquiridoEn(),
                            r.idUsuarioDueno(),
                            r.nombreDuenoVisible(),
                            r.esMercado(),
                            r.tieneOfertaPendiente(),
                            l == null ? null : l.probabilidadTitular(),
                            l == null ? null : l.motivoTitularidad(),
                            l == null ? null : l.idPartidoProbabilidad(),
                            l == null ? null : l.calculadoEnProbabilidad()
                    )
            );
        }
        return enriched;
    }
    }

    public List<LeagueRoundSummaryResponse> listLeagueRounds(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT j.id,
                           j.id_liga,
                           j.numero,
                           j.inicio,
                           j.inicio_en,
                           j.fin,
                           j.estado,
                           COUNT(pj.id) AS total_partidos,
                           COALESCE(SUM(CASE WHEN pj.estado = 'FINALIZADO' THEN 1 ELSE 0 END), 0) AS partidos_finalizados
                    FROM jornadas j
                    LEFT JOIN partidos_jornada pj ON pj.id_jornada = j.id
                    WHERE j.id_liga = ?
                    GROUP BY j.id, j.id_liga, j.numero, j.inicio, j.inicio_en, j.fin, j.estado
                    ORDER BY j.numero ASC
                    """;

            List<LeagueRoundSummaryResponse> rounds = new ArrayList<>();
            Long firstPendingRoundId = null;
            Long currentRoundId = null;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Long roundId = rs.getLong("id");
                        String estado = rs.getString("estado");

                        if ("EN_CURSO".equals(estado) && currentRoundId == null) {
                            currentRoundId = roundId;
                        }

                        if ("PENDIENTE".equals(estado) && firstPendingRoundId == null) {
                            firstPendingRoundId = roundId;
                        }

                        Date inicioDate = rs.getDate("inicio");
                        LocalDate inicio = inicioDate == null ? null : inicioDate.toLocalDate();

                        Timestamp inicioEnTs = rs.getTimestamp("inicio_en");
                        Instant inicioEn = inicioEnTs == null ? null : inicioEnTs.toInstant();

                        Date finDate = rs.getDate("fin");
                        LocalDate fin = finDate == null ? null : finDate.toLocalDate();

                        rounds.add(new LeagueRoundSummaryResponse(
                                roundId,
                                rs.getLong("id_liga"),
                                rs.getInt("numero"),
                                inicio,
                                inicioEn,
                                fin,
                                estado,
                                rs.getInt("total_partidos"),
                                rs.getInt("partidos_finalizados"),
                                false,
                                false,
                                "FINALIZADA".equals(estado)
                        ));
                    }
                }
            }

            List<LeagueRoundSummaryResponse> response = new ArrayList<>();

            for (LeagueRoundSummaryResponse round : rounds) {
                boolean actual = currentRoundId != null && currentRoundId.equals(round.idJornada());
                boolean proxima = firstPendingRoundId != null && firstPendingRoundId.equals(round.idJornada());

                response.add(new LeagueRoundSummaryResponse(
                        round.idJornada(),
                        round.idLiga(),
                        round.numero(),
                        round.inicio(),
                        round.inicioEn(),
                        round.fin(),
                        round.estado(),
                        round.totalPartidos(),
                        round.partidosFinalizados(),
                        actual,
                        proxima,
                        round.finalizada()
                ));
            }

            return response;
        }
    }

    public LeagueRoundDetailResponse getLeagueRoundDetail(Long idLiga, Long idJornada, Long idUsuario) throws SQLException {
        if (idLiga == null || idJornada == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            RoundHeaderData roundHeader = loadRoundHeader(conn, idLiga, idJornada);

            if (roundHeader == null) {
                throw new IllegalArgumentException("Jornada no encontrada");
            }

            List<LeagueRoundMatchResponse> matches = loadRoundMatches(conn, idJornada);

            return new LeagueRoundDetailResponse(
                    roundHeader.idJornada(),
                    roundHeader.idLiga(),
                    roundHeader.numero(),
                    roundHeader.inicio(),
                    roundHeader.inicioEn(),
                    roundHeader.fin(),
                    roundHeader.estado(),
                    matches.size(),
                    countFinalizedMatches(matches),
                    matches
            );
        }
    }

    public LeagueMatchDetailResponse getLeagueMatchDetail(Long idLiga, Long idPartido, Long idUsuario) throws SQLException {
    if (idLiga == null || idPartido == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        MatchHeaderData matchHeader = loadMatchHeader(conn, idLiga, idPartido);

        if (matchHeader == null) {
            throw new IllegalArgumentException("Partido no encontrado");
        }

        LineupBundle lineupBundle = loadMatchLineups(
                conn,
                matchHeader.idPartido(),
                matchHeader.idLigaEquipoLocal(),
                matchHeader.idLigaEquipoVisitante()
        );

        VisibleMatchProjection projection = buildVisibleMatchProjection(conn, matchHeader, lineupBundle);

        MatchDisplayFormacionesEntrenadores formacionCoach = buildMatchFormacionesYEntrenadores(conn, matchHeader, lineupBundle);

        return new LeagueMatchDetailResponse(
                matchHeader.idPartido(),
                matchHeader.idLiga(),
                matchHeader.idJornada(),
                matchHeader.numeroJornada(),
                matchHeader.inicioJornada(),
                matchHeader.inicioPartido(),
                projection.estadoVisible(),
                matchHeader.estado(),
                projection.enDirecto(),
                projection.minutoActual(),
                projection.segundoActual(),
                matchHeader.idLigaEquipoLocal(),
                matchHeader.idEquipoLocal(),
                matchHeader.nombreEquipoLocal(),
                matchHeader.fotoEquipoLocal(),
                projection.golesLocal(),
                matchHeader.idLigaEquipoVisitante(),
                matchHeader.idEquipoVisitante(),
                matchHeader.nombreEquipoVisitante(),
                matchHeader.fotoEquipoVisitante(),
                projection.golesVisitante(),
                formacionCoach.formacionLocal(),
                formacionCoach.alineacionLocal(),
                formacionCoach.entrenadorLocal(),
                formacionCoach.formacionVisitante(),
                formacionCoach.alineacionVisitante(),
                formacionCoach.entrenadorVisitante(),
                matchHeader.golesLocal(),
                matchHeader.golesVisitante(),
                projection.idLigaEquipoGanadorVisible(),
                projection.empateVisible(),
                lineupBundle.titularesLocal(),
                lineupBundle.suplentesLocal(),
                lineupBundle.titularesVisitante(),
                lineupBundle.suplentesVisitante(),
                projection.eventosVisibles()
        );
    }
}

    private RoundHeaderData loadRoundHeader(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT j.id, j.id_liga, j.numero, j.inicio, j.inicio_en, j.fin, j.estado
                FROM jornadas j
                WHERE j.id = ? AND j.id_liga = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Date inicioDate = rs.getDate("inicio");
                LocalDate inicio = inicioDate == null ? null : inicioDate.toLocalDate();
                Timestamp inicioEnTs = rs.getTimestamp("inicio_en");
                Instant inicioEn = inicioEnTs == null ? null : inicioEnTs.toInstant();
                Date finDate = rs.getDate("fin");
                LocalDate fin = finDate == null ? null : finDate.toLocalDate();
                return new RoundHeaderData(rs.getLong("id"), rs.getLong("id_liga"), rs.getInt("numero"), inicio, inicioEn, fin, rs.getString("estado"));
            }
        }
    }

    private List<LeagueRoundMatchResponse> loadRoundMatches(Connection conn, Long idJornada) throws SQLException {
    String sql = """
            SELECT pj.id AS id_partido,
                   pj.id_jornada,
                   j_rm.id_liga,
                   j_rm.numero AS numero_jornada,
                   j_rm.inicio AS inicio_jornada,
                   pj.inicio_en AS inicio_partido,
                   pj.estado,
                   le_local.id AS id_liga_equipo_local,
                   le_local.id_equipo AS id_equipo_local,
                   e_local.nombre AS nombre_equipo_local,
                   e_local.foto AS foto_equipo_local,
                   e_local.id_temporada AS id_temporada_local,
                   e_local.alineacion AS alineacion_equipo_local,
                   pj.goles_local,
                   le_visitante.id AS id_liga_equipo_visitante,
                   le_visitante.id_equipo AS id_equipo_visitante,
                   e_visitante.nombre AS nombre_equipo_visitante,
                   e_visitante.foto AS foto_equipo_visitante,
                   e_visitante.id_temporada AS id_temporada_visitante,
                   e_visitante.alineacion AS alineacion_equipo_visitante,
                   pj.goles_visitante,
                   pj.id_liga_equipo_ganador,
                   pj.empate
            FROM partidos_jornada pj
            INNER JOIN jornadas j_rm ON j_rm.id = pj.id_jornada
            INNER JOIN liga_equipos le_local
                ON le_local.id_liga = j_rm.id_liga AND le_local.id_equipo = pj.id_liga_equipo_local
            INNER JOIN equipos e_local ON e_local.id = le_local.id_equipo
            INNER JOIN liga_equipos le_visitante
                ON le_visitante.id_liga = j_rm.id_liga AND le_visitante.id_equipo = pj.id_liga_equipo_visitante
            INNER JOIN equipos e_visitante ON e_visitante.id = le_visitante.id_equipo
            WHERE pj.id_jornada = ?
            ORDER BY pj.inicio_en ASC, pj.id ASC
            """;

    List<LeagueRoundMatchResponse> matches = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idJornada);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Date inicioJornadaDate = rs.getDate("inicio_jornada");
                LocalDate inicioJornada = inicioJornadaDate == null ? null : inicioJornadaDate.toLocalDate();

                Timestamp inicioPartidoTs = rs.getTimestamp("inicio_partido");
                Instant inicioPartido = inicioPartidoTs == null ? null : inicioPartidoTs.toInstant();

                MatchHeaderData matchHeader = readMatchHeaderData(rs, inicioJornada, inicioPartido);

                LineupBundle lineupBundle = loadMatchLineups(
                        conn,
                        matchHeader.idPartido(),
                        matchHeader.idLigaEquipoLocal(),
                        matchHeader.idLigaEquipoVisitante()
                );

                VisibleMatchProjection projection = buildVisibleMatchProjection(conn, matchHeader, lineupBundle);

                matches.add(new LeagueRoundMatchResponse(
                        matchHeader.idPartido(),
                        matchHeader.idJornada(),
                        matchHeader.idLigaEquipoLocal(),
                        matchHeader.idEquipoLocal(),
                        matchHeader.nombreEquipoLocal(),
                        projection.golesLocal(),
                        matchHeader.idLigaEquipoVisitante(),
                        matchHeader.idEquipoVisitante(),
                        matchHeader.nombreEquipoVisitante(),
                        projection.golesVisitante(),
                        projection.idLigaEquipoGanadorVisible(),
                        Boolean.TRUE.equals(projection.empateVisible()),
                        projection.estadoVisible(),
                        matchHeader.inicioPartido()
                ));
            }
        }
    }

    return matches;
}

    

    private MatchHeaderData loadMatchHeader(Connection conn, Long idLiga, Long idPartido) throws SQLException {
        String sql = """
                SELECT pj.id AS id_partido,
                       pj.id_jornada,
                       j.id_liga,
                       j.numero AS numero_jornada,
                       j.inicio AS inicio_jornada,
                       pj.inicio_en AS inicio_partido,
                       pj.estado,
                       le_local.id AS id_liga_equipo_local,
                       le_local.id_equipo AS id_equipo_local,
                       e_local.nombre AS nombre_equipo_local,
                       e_local.foto AS foto_equipo_local,
                       e_local.id_temporada AS id_temporada_local,
                       e_local.alineacion AS alineacion_equipo_local,
                       pj.goles_local,
                       le_visitante.id AS id_liga_equipo_visitante,
                       le_visitante.id_equipo AS id_equipo_visitante,
                       e_visitante.nombre AS nombre_equipo_visitante,
                       e_visitante.foto AS foto_equipo_visitante,
                       e_visitante.id_temporada AS id_temporada_visitante,
                       e_visitante.alineacion AS alineacion_equipo_visitante,
                       pj.goles_visitante,
                       pj.id_liga_equipo_ganador,
                       pj.empate
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                INNER JOIN liga_equipos le_local
                    ON le_local.id_liga = j.id_liga AND le_local.id_equipo = pj.id_liga_equipo_local
                INNER JOIN equipos e_local ON e_local.id = le_local.id_equipo
                INNER JOIN liga_equipos le_visitante
                    ON le_visitante.id_liga = j.id_liga AND le_visitante.id_equipo = pj.id_liga_equipo_visitante
                INNER JOIN equipos e_visitante ON e_visitante.id = le_visitante.id_equipo
                WHERE pj.id = ? AND j.id_liga = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Date inicioJornadaDate = rs.getDate("inicio_jornada");
                LocalDate inicioJornada = inicioJornadaDate == null ? null : inicioJornadaDate.toLocalDate();
                Timestamp inicioPartidoTs = rs.getTimestamp("inicio_partido");
                Instant inicioPartido = inicioPartidoTs == null ? null : inicioPartidoTs.toInstant();

                return readMatchHeaderData(rs, inicioJornada, inicioPartido);
            }
        }
    }

    private MatchHeaderData readMatchHeaderData(ResultSet rs, LocalDate inicioJornada, Instant inicioPartido) throws SQLException {
        return new MatchHeaderData(
                rs.getLong("id_partido"),
                rs.getLong("id_liga"),
                rs.getLong("id_jornada"),
                rs.getInt("numero_jornada"),
                inicioJornada,
                inicioPartido,
                rs.getString("estado"),
                rs.getLong("id_liga_equipo_local"),
                rs.getLong("id_equipo_local"),
                rs.getString("nombre_equipo_local"),
                LeagueAssetUrls.team(rs.getLong("id_equipo_local")),
                rs.getObject("id_temporada_local", Long.class),
                rs.getString("alineacion_equipo_local"),
                rs.getInt("goles_local"),
                rs.getLong("id_liga_equipo_visitante"),
                rs.getLong("id_equipo_visitante"),
                rs.getString("nombre_equipo_visitante"),
                LeagueAssetUrls.team(rs.getLong("id_equipo_visitante")),
                rs.getObject("id_temporada_visitante", Long.class),
                rs.getString("alineacion_equipo_visitante"),
                rs.getInt("goles_visitante"),
                getNullableLong(rs, "id_liga_equipo_ganador"),
                rs.getBoolean("empate")
        );
    }

    private MatchDisplayFormacionesEntrenadores buildMatchFormacionesYEntrenadores(
            Connection conn,
            MatchHeaderData header,
            LineupBundle lineup
    ) throws SQLException {
        String formacionLocal = resolveMatchFormationDisplay(lineup.titularesLocal(), header.alineacionEquipoLocal());
        String formacionVisitante = resolveMatchFormationDisplay(lineup.titularesVisitante(), header.alineacionEquipoVisitante());
        LeagueMatchRealCoachResponse entrenadorLocal = loadMatchRealCoach(
                conn,
                header.idEquipoLocal(),
                header.idTemporadaLocal(),
                header.nombreEquipoLocal()
        );
        LeagueMatchRealCoachResponse entrenadorVisitante = loadMatchRealCoach(
                conn,
                header.idEquipoVisitante(),
                header.idTemporadaVisitante(),
                header.nombreEquipoVisitante()
        );
        return new MatchDisplayFormacionesEntrenadores(
                formacionLocal,
                formacionLocal,
                entrenadorLocal,
                formacionVisitante,
                formacionVisitante,
                entrenadorVisitante
        );
    }

    private String resolveMatchFormationDisplay(
            List<LeagueMatchLineupPlayerResponse> titulares,
            String alineacionEquipoCatalogo
    ) {
        if (titulares != null && !titulares.isEmpty()) {
            return deriveFormationTripletFromTitulares(titulares);
        }
        return normalizeFormationFromEquiposString(alineacionEquipoCatalogo);
    }

    private String deriveFormationTripletFromTitulares(List<LeagueMatchLineupPlayerResponse> titulares) {
        int def = 0;
        int med = 0;
        int del = 0;
        for (LeagueMatchLineupPlayerResponse p : titulares) {
            String pos = p.posicion();
            if (pos == null) {
                continue;
            }
            if ("DEF".equals(pos)) {
                def++;
            } else if ("MED".equals(pos)) {
                med++;
            } else if ("DEL".equals(pos)) {
                del++;
            }
        }
        return def + "-" + med + "-" + del;
    }

    private String normalizeFormationFromEquiposString(String raw) {
        if (raw == null || raw.isBlank()) {
            return DEFAULT_MATCH_FORMATION;
        }
        String normalized = raw.trim().replace(" ", "");
        String[] parts = normalized.split("-");
        if (parts.length != 3) {
            return DEFAULT_MATCH_FORMATION;
        }
        try {
            int def = Integer.parseInt(parts[0]);
            int med = Integer.parseInt(parts[1]);
            int del = Integer.parseInt(parts[2]);
            if (def < 0 || med < 0 || del < 0 || def + med + del != 10) {
                return DEFAULT_MATCH_FORMATION;
            }
            return def + "-" + med + "-" + del;
        } catch (NumberFormatException e) {
            return DEFAULT_MATCH_FORMATION;
        }
    }

    private LeagueMatchRealCoachResponse loadMatchRealCoach(
            Connection conn,
            long idEquipo,
            Long idTemporada,
            String equipoNombre
    ) throws SQLException {
        if (idTemporada == null) {
            return null;
        }
        String sql = """
                SELECT id, nombre, pila, formacion, foto, id_equipo, id_temporada, bonus_puntos, activo
                FROM entrenadores
                WHERE id_equipo = ?
                  AND id_temporada = ?
                  AND activo = TRUE
                ORDER BY id ASC
                LIMIT 2
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEquipo);
            ps.setLong(2, idTemporada);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                long idEntrenador = rs.getLong("id");
                String nombre = rs.getString("nombre");
                String pila = rs.getString("pila");
                String formacion = rs.getString("formacion");
                String fotoUrl = LeagueAssetUrls.manager(idEntrenador);
                long idEqRow = rs.getLong("id_equipo");
                Integer bonus = rs.getObject("bonus_puntos", Integer.class);
                boolean activo = rs.getBoolean("activo");
                if (rs.next()) {
                    log.warn(
                            "Varios entrenadores activos para id_equipo={}, id_temporada={}; usando id_entrenador={}",
                            idEquipo,
                            idTemporada,
                            idEntrenador
                    );
                }
                return new LeagueMatchRealCoachResponse(
                        idEntrenador,
                        nombre,
                        pila,
                        formacion,
                        fotoUrl,
                        fotoUrl,
                        idEqRow,
                        equipoNombre,
                        bonus,
                        activo
                );
            }
        }
    }

    private LineupBundle loadMatchLineups(Connection conn, Long idPartido, Long idLigaEquipoLocal, Long idLigaEquipoVisitante) throws SQLException {
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
                       CAST(ROUND(
                           CASE
                               WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO'
                                   THEN jct.valoracion
                               ELSE COALESCE(lj.valoracion_actual, j.valoracion)
                           END, 0
                       ) AS SIGNED) AS valoracion,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN ect.id
                           ELSE e.id
                       END AS id_equipo,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN ect.nombre
                           ELSE e.nombre
                       END AS nombre_equipo,
                       COALESCE(jct.foto, j.foto) AS foto,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 'DISPONIBLE'
                           ELSE lj.estado
                       END AS estado,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 0
                           ELSE lj.cansancio
                       END AS cansancio,
                       CASE
                           WHEN ap.tipo_origen_jugador = 'CEDIDO_EXCLUSIVO' THEN 0
                           ELSE lj.valor
                       END AS valor
                FROM alineacion_partido ap
                LEFT JOIN liga_jugadores lj ON lj.id = ap.id_liga_jugador
                LEFT JOIN jugadores j ON j.id = lj.id_jugador
                LEFT JOIN equipos e ON e.id = lj.id_equipo
                LEFT JOIN jugadores_cedidos_temporada jct ON jct.id = ap.id_jugador_cedido_temporada
                LEFT JOIN equipos_cedidos_temporada ect ON ect.id = jct.id_equipo_cedidos_temporada
                WHERE ap.id_partido_jornada = ?
                ORDER BY
                    ap.id_liga_equipo ASC,
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
        List<LeagueMatchLineupPlayerResponse> titularesLocal = new ArrayList<>();
        List<LeagueMatchLineupPlayerResponse> suplentesLocal = new ArrayList<>();
        List<LeagueMatchLineupPlayerResponse> titularesVisitante = new ArrayList<>();
        List<LeagueMatchLineupPlayerResponse> suplentesVisitante = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String fotoUrl = buildMatchPlayerPhotoUrl(
                            getNullableLong(rs, "id_jugador"),
                            rs.getObject("id_jugador_cedido_temporada", Integer.class)
                    );
                    LeagueMatchLineupPlayerResponse player = new LeagueMatchLineupPlayerResponse(
                            getNullableLong(rs, "id_liga_jugador"),
                            rs.getObject("id_jugador_cedido_temporada", Integer.class),
                            rs.getString("tipo_origen_jugador"),
                            getNullableLong(rs, "id_jugador"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            buildPlayerDisplayName(rs.getString("nombre"), rs.getString("pila")),
                            rs.getString("posicion"),
                            rs.getInt("valoracion"),
                            getNullableLong(rs, "id_equipo"),
                            rs.getString("nombre_equipo"),
                            fotoUrl,
                            fotoUrl,
                            rs.getString("estado"),
                            rs.getInt("cansancio"),
                            rs.getLong("valor"),
                            rs.getBoolean("titular")
                    );

                    long idLigaEquipo = rs.getLong("id_liga_equipo");
                    boolean titular = rs.getBoolean("titular");

                    if (idLigaEquipo == idLigaEquipoLocal) {
                        if (titular) titularesLocal.add(player);
                        else suplentesLocal.add(player);
                    } else if (idLigaEquipo == idLigaEquipoVisitante) {
                        if (titular) titularesVisitante.add(player);
                        else suplentesVisitante.add(player);
                    }
                }
            }
        }

        return new LineupBundle(titularesLocal, suplentesLocal, titularesVisitante, suplentesVisitante);
    }

    private List<LeagueMatchEventResponse> loadMatchEvents(Connection conn, Long idPartido) throws SQLException {
        String sql = """
                SELECT pe.id,
                       pe.minuto,
                       pe.segundo,
                       pe.tipo,
                       pe.replay_offset_sec,
                       pe.id_liga_jugador,
                       pe.id_jugador_cedido_temporada,
                       j1.id AS id_jugador_principal,
                       pe.id_liga_jugador_sec,
                       pe.id_jugador_cedido_temporada_sec,
                       j2.id AS id_jugador_secundario,
                       pe.texto,
                       COALESCE(jct1.nombre, j1.nombre) AS nombre_principal,
                       COALESCE(jct1.pila, j1.pila) AS pila_principal,
                       COALESCE(jct2.nombre, j2.nombre) AS nombre_secundario,
                       COALESCE(jct2.pila, j2.pila) AS pila_secundario
                FROM partido_eventos pe
                LEFT JOIN liga_jugadores lj1 ON lj1.id = pe.id_liga_jugador
                LEFT JOIN jugadores j1 ON j1.id = lj1.id_jugador
                LEFT JOIN jugadores_cedidos_temporada jct1 ON jct1.id = pe.id_jugador_cedido_temporada
                LEFT JOIN liga_jugadores lj2 ON lj2.id = pe.id_liga_jugador_sec
                LEFT JOIN jugadores j2 ON j2.id = lj2.id_jugador
                LEFT JOIN jugadores_cedidos_temporada jct2 ON jct2.id = pe.id_jugador_cedido_temporada_sec
                WHERE pe.id_partido_jornada = ?
                ORDER BY pe.minuto ASC, pe.segundo ASC, pe.id ASC
                """;
        List<LeagueMatchEventResponse> events = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Integer replayOffsetSec = rs.getInt("replay_offset_sec");
                    if (rs.wasNull()) replayOffsetSec = null;
                    events.add(new LeagueMatchEventResponse(
                            rs.getLong("id"),
                            rs.getInt("minuto"),
                            rs.getInt("segundo"),
                            rs.getString("tipo"),
                            replayOffsetSec,
                            getNullableLong(rs, "id_liga_jugador"),
                            rs.getObject("id_jugador_cedido_temporada", Integer.class),
                            buildPlayerDisplayName(rs.getString("nombre_principal"), rs.getString("pila_principal")),
                            buildMatchPlayerPhotoUrl(
                                    getNullableLong(rs, "id_jugador_principal"),
                                    rs.getObject("id_jugador_cedido_temporada", Integer.class)
                            ),
                            getNullableLong(rs, "id_liga_jugador_sec"),
                            rs.getObject("id_jugador_cedido_temporada_sec", Integer.class),
                            buildPlayerDisplayName(rs.getString("nombre_secundario"), rs.getString("pila_secundario")),
                            buildMatchPlayerPhotoUrl(
                                    getNullableLong(rs, "id_jugador_secundario"),
                                    rs.getObject("id_jugador_cedido_temporada_sec", Integer.class)
                            ),
                            rs.getString("texto")
                    ));
                }
            }
        }

        return events;
    }

    private int countFinalizedMatches(List<LeagueRoundMatchResponse> matches) {
        int total = 0;
        for (LeagueRoundMatchResponse match : matches) {
            if ("FINALIZADO".equals(match.estado())) total++;
        }
        return total;
    }

    private void ensureParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        if (!isParticipant(conn, idLiga, idUsuario)) {
            throw new IllegalArgumentException("No perteneces a esta liga");
        }
    }

    private void normalizeExpiredUnavailablePlayersForLeague(Connection conn, Long idLiga) throws SQLException {
        String sqlLesion = """
                UPDATE liga_jugadores
                SET estado = 'DISPONIBLE',
                    lesionado_hasta = NULL
                WHERE id_liga = ?
                  AND estado = 'LESIONADO'
                  AND lesionado_hasta IS NOT NULL
                  AND lesionado_hasta <= NOW()
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlLesion)) {
            ps.setLong(1, idLiga);
            ps.executeUpdate();
        }

        String sqlSanction = """
                UPDATE liga_jugadores
                SET estado = 'DISPONIBLE',
                    sancionado_hasta = NULL
                WHERE id_liga = ?
                  AND estado = 'SANCIONADO'
                  AND sancionado_hasta IS NOT NULL
                  AND sancionado_hasta <= NOW()
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlSanction)) {
            ps.setLong(1, idLiga);
            ps.executeUpdate();
        }
    }

    private UpcomingRoundRef loadUpcomingRoundForTeam(Connection conn, Long idLiga, Long idEquipo, Instant availableFrom) throws SQLException {
        if (availableFrom == null) {
            return null;
        }

        String sql = """
                SELECT
                  jo.id AS id_jornada,
                  jo.numero AS numero_jornada,
                  pj.inicio_en
                FROM jornadas jo
                JOIN partidos_jornada pj ON pj.id_jornada = jo.id
                JOIN liga_equipos le_local ON le_local.id = pj.id_liga_equipo_local
                JOIN liga_equipos le_visit ON le_visit.id = pj.id_liga_equipo_visitante
                WHERE jo.id_liga = ?
                  AND pj.inicio_en IS NOT NULL
                  AND pj.inicio_en > ?
                  AND (le_local.id_equipo = ? OR le_visit.id_equipo = ?)
                ORDER BY pj.inicio_en ASC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setTimestamp(2, Timestamp.from(availableFrom));
            ps.setLong(3, idEquipo);
            ps.setLong(4, idEquipo);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new UpcomingRoundRef(
                        rs.getLong("id_jornada"),
                        rs.getInt("numero_jornada")
                );
            }
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

    private void appendInClause(StringBuilder sql, int count) {
        for (int i = 0; i < count; i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }
    }

    

    private Long getNullableLong(ResultSet rs, String columnName) throws SQLException {
        long value = rs.getLong(columnName);
        return rs.wasNull() ? null : value;
    }

    private String buildPlayerDisplayName(String nombre, String pila) {
    if (pila != null && !pila.isBlank()) return pila;
    if (nombre != null && !nombre.isBlank()) return nombre;
    return null;
}

    private String buildMatchPlayerPhotoUrl(Long idJugador, Integer idJugadorCedidoTemporada) {
        return LeagueAssetUrls.playerOrLoan(idJugador, idJugadorCedidoTemporada);
    }

private record UpcomingRoundRef(Long idJornada, Integer numeroJornada) {}

private VisibleMatchProjection buildVisibleMatchProjection(
        Connection conn,
        MatchHeaderData matchHeader,
        LineupBundle lineupBundle
) throws SQLException {
    List<LeagueMatchEventResponse> allEvents = loadMatchEvents(conn, matchHeader.idPartido());

    long elapsedSeconds = resolveElapsedVisibleSeconds(matchHeader.inicioPartido());
    boolean finalizadoVisible = isFinalVisible(matchHeader.estado(), elapsedSeconds);

    List<LeagueMatchEventResponse> visibleEvents = filterVisibleEvents(
            allEvents,
            elapsedSeconds,
            finalizadoVisible
    );

    VisibleScore visibleScore = resolveVisibleScore(visibleEvents, lineupBundle);

    String estadoVisible = resolveVisibleState(
            matchHeader.estado(),
            elapsedSeconds,
            visibleScore
    );

    boolean enDirecto = "EN_JUEGO".equals(estadoVisible) || "EN_EMPATE".equals(estadoVisible);
    int minutoActual = resolveCurrentMinute(elapsedSeconds, estadoVisible);
    int segundoActual = resolveCurrentSecond(elapsedSeconds, estadoVisible);

    Long ganadorVisible = null;
    Boolean empateVisible = null;

    if ("FINALIZADO".equals(estadoVisible)) {
    if (visibleScore.golesLocal() > visibleScore.golesVisitante()) {
        ganadorVisible = matchHeader.idEquipoLocal();
        empateVisible = false;
    } else if (visibleScore.golesVisitante() > visibleScore.golesLocal()) {
        ganadorVisible = matchHeader.idEquipoVisitante();
        empateVisible = false;
    } else {
        ganadorVisible = null;
        empateVisible = true;
    }
}

    return new VisibleMatchProjection(
            estadoVisible,
            enDirecto,
            minutoActual,
            segundoActual,
            visibleScore.golesLocal(),
            visibleScore.golesVisitante(),
            ganadorVisible,
            empateVisible,
            visibleEvents
    );
}

private boolean isFinalVisible(String estadoReal, long elapsedSeconds) {
    if ("FINALIZADO".equals(estadoReal)) {
        return true;
    }

    return "EN_JUEGO".equals(estadoReal) && elapsedSeconds >= FULL_MATCH_VISIBLE_SECONDS;
}

private long resolveElapsedVisibleSeconds(Instant inicioPartido) {
    if (inicioPartido == null) {
        return 0L;
    }

    long elapsed = Duration.between(inicioPartido, Instant.now()).getSeconds();

    if (elapsed <= 0) {
        return 0L;
    }

    return Math.min(elapsed, FULL_MATCH_VISIBLE_SECONDS);
}

private String resolveVisibleState(String estadoReal, long elapsedSeconds, VisibleScore visibleScore) {
    if ("PENDIENTE".equals(estadoReal)) {
        return "PENDIENTE";
    }

    if ("FINALIZADO".equals(estadoReal) || ("EN_JUEGO".equals(estadoReal) && elapsedSeconds >= FULL_MATCH_VISIBLE_SECONDS)) {
        return "FINALIZADO";
    }

    if ("EN_JUEGO".equals(estadoReal)) {
        if (Objects.equals(visibleScore.golesLocal(), visibleScore.golesVisitante())) {
            return "EN_EMPATE";
        }
        return "EN_JUEGO";
    }

    return "PENDIENTE";
}

private int resolveCurrentMinute(long elapsedSeconds, String estadoVisible) {
    if ("PENDIENTE".equals(estadoVisible)) {
        return 0;
    }

    if ("FINALIZADO".equals(estadoVisible)) {
        return 90;
    }

    int minute = (int) (elapsedSeconds / 60L);
    return Math.max(1, Math.min(90, minute));
}

private int resolveCurrentSecond(long elapsedSeconds, String estadoVisible) {
    if (!"EN_JUEGO".equals(estadoVisible) && !"EN_EMPATE".equals(estadoVisible)) {
        return 0;
    }

    return (int) (elapsedSeconds % 60L);
}

private List<LeagueMatchEventResponse> filterVisibleEvents(
        List<LeagueMatchEventResponse> allEvents,
        long elapsedSeconds,
        boolean showAll
) {
    if (showAll) {
        return allEvents;
    }

    List<LeagueMatchEventResponse> visible = new ArrayList<>();

    for (LeagueMatchEventResponse event : allEvents) {
        long eventSecond = ((long) event.minuto() * 60L) + event.segundo();

        if (eventSecond <= elapsedSeconds) {
            visible.add(event);
        }
    }

    return visible;
}

private VisibleScore resolveVisibleScore(
        List<LeagueMatchEventResponse> visibleEvents,
        LineupBundle lineupBundle
) {
    Set<Long> localIds = new HashSet<>();
    Set<Integer> localCedidosIds = new HashSet<>();

    for (LeagueMatchLineupPlayerResponse p : lineupBundle.titularesLocal()) {
        if (p.idLigaJugador() != null) {
            localIds.add(p.idLigaJugador());
        }
        if (p.idJugadorCedidoTemporada() != null) {
            localCedidosIds.add(p.idJugadorCedidoTemporada());
        }
    }
    for (LeagueMatchLineupPlayerResponse p : lineupBundle.suplentesLocal()) {
        if (p.idLigaJugador() != null) {
            localIds.add(p.idLigaJugador());
        }
        if (p.idJugadorCedidoTemporada() != null) {
            localCedidosIds.add(p.idJugadorCedidoTemporada());
        }
    }

    int golesLocal = 0;
    int golesVisitante = 0;

    for (LeagueMatchEventResponse event : visibleEvents) {
        if (!"GOL".equals(event.tipo())) {
            continue;
        }

        Long scorerId = event.idLigaJugadorPrincipal();
        Integer scorerCedId = event.idJugadorCedidoTemporadaPrincipal();
        if (scorerId == null && scorerCedId == null) {
            continue;
        }

        if ((scorerId != null && localIds.contains(scorerId))
                || (scorerCedId != null && localCedidosIds.contains(scorerCedId))) {
            golesLocal++;
        } else {
            golesVisitante++;
        }
    }

    return new VisibleScore(golesLocal, golesVisitante);
}

    /**
     * Replica {@link LeagueSimulationService} fantasy sobre acumulador persistido (incluye amarillas=0 como en sim).
     */
    public static int fantasyPointsLikeSimulation(
            String posicion,
            int minutesPlayed,
            int goals,
            int assists,
            int dribbles,
            int recoveries,
            int saves,
            int goalsConceded,
            int yellowCards,
            int redCards,
            boolean injuredInMatch,
            Integer newspaperNotePersisted
    ) {
        return FantasyPointsBreakdownCalculator.totalPoints(fantasyInput(
                posicion,
                minutesPlayed,
                goals,
                assists,
                dribbles,
                recoveries,
                saves,
                goalsConceded,
                yellowCards,
                redCards,
                injuredInMatch,
                newspaperNotePersisted
        ));
    }

    public static FantasyPointsBreakdownCalculator.Breakdown fantasyBreakdownLikeSimulation(
            String posicion,
            int minutesPlayed,
            int goals,
            int assists,
            int dribbles,
            int recoveries,
            int saves,
            int goalsConceded,
            int yellowCards,
            int redCards,
            boolean injuredInMatch,
            Integer newspaperNotePersisted
    ) {
        return FantasyPointsBreakdownCalculator.calculate(fantasyInput(
                posicion,
                minutesPlayed,
                goals,
                assists,
                dribbles,
                recoveries,
                saves,
                goalsConceded,
                yellowCards,
                redCards,
                injuredInMatch,
                newspaperNotePersisted
        ));
    }

    private static FantasyPointsBreakdownCalculator.Input fantasyInput(
            String posicion,
            int minutesPlayed,
            int goals,
            int assists,
            int dribbles,
            int recoveries,
            int saves,
            int goalsConceded,
            int yellowCards,
            int redCards,
            boolean injuredInMatch,
            Integer newspaperNotePersisted
    ) {
        return new FantasyPointsBreakdownCalculator.Input(
                posicion,
                minutesPlayed,
                goals,
                assists,
                dribbles,
                recoveries,
                saves,
                goalsConceded,
                yellowCards,
                redCards,
                injuredInMatch,
                newspaperNotePersisted
        );
    }

private record VisibleScore(Integer golesLocal, Integer golesVisitante) {
}

private record ParticipantTargetData(
        Long idUsuarioParticipante,
        String nickname
) {
}

private record RoundHeaderDataLite(
        Long idJornada,
        Integer numeroJornada,
        String estadoJornada,
        Instant inicioJornada
) {
}

private record PlayerLineupData(
        Long idJugador,
        String nombre,
        String pila,
        String posicion,
        Integer valoracion,
        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        String fotoJugador,
        String estado,
        Integer cansancio,
        Long valor
) {
}

private record VisibleMatchProjection(
        String estadoVisible,
        boolean enDirecto,
        Integer minutoActual,
        Integer segundoActual,
        Integer golesLocal,
        Integer golesVisitante,
        Long idLigaEquipoGanadorVisible,
        Boolean empateVisible,
        List<LeagueMatchEventResponse> eventosVisibles
) {
}

private record RoundHeaderData(
        Long idJornada,
        Long idLiga,
        Integer numero,
        LocalDate inicio,
        Instant inicioEn,
        LocalDate fin,
        String estado
) {
}

private record MatchDisplayFormacionesEntrenadores(
        String formacionLocal,
        String alineacionLocal,
        LeagueMatchRealCoachResponse entrenadorLocal,
        String formacionVisitante,
        String alineacionVisitante,
        LeagueMatchRealCoachResponse entrenadorVisitante
) {
}

private record MatchHeaderData(
        Long idPartido,
        Long idLiga,
        Long idJornada,
        Integer numeroJornada,
        LocalDate inicioJornada,
        Instant inicioPartido,
        String estado,
        Long idLigaEquipoLocal,
        Long idEquipoLocal,
        String nombreEquipoLocal,
        String fotoEquipoLocal,
        Long idTemporadaLocal,
        String alineacionEquipoLocal,
        Integer golesLocal,
        Long idLigaEquipoVisitante,
        Long idEquipoVisitante,
        String nombreEquipoVisitante,
        String fotoEquipoVisitante,
        Long idTemporadaVisitante,
        String alineacionEquipoVisitante,
        Integer golesVisitante,
        Long idLigaEquipoGanador,
        Boolean empate
) {
}

private record LineupBundle(
        List<LeagueMatchLineupPlayerResponse> titularesLocal,
        List<LeagueMatchLineupPlayerResponse> suplentesLocal,
        List<LeagueMatchLineupPlayerResponse> titularesVisitante,
        List<LeagueMatchLineupPlayerResponse> suplentesVisitante
) {
}
}