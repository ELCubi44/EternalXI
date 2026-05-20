package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.league.LeagueMatchEventResponse;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Anti-spoiler para partidos {@code EN_JUEGO}: mismos límites temporales que la cronología ({@code eventSecond <= elapsedSeconds}
 * de tiempo real desde el saque). Los acumuladores en {@code jugadores_puntos_jornada} llevan el partido completo simulado de una vez,
 * así que la API debe derivar goles/asistencias/puntos solo de eventos ya “emitidos”.
 */
public final class LeagueMatchLiveFantasyMask {

    public static final long FULL_MATCH_VISIBLE_SECONDS = 90L * 60L;

    public record MatchAnchor(long idPartido, String estado, Instant kickoff, long catalogLocal, long catalogVisitor) {}

    /** Fila persistida en {@code jugadores_puntos_jornada} (valores completos del simulador). */
    public record JpPersistentStats(
            int puntos,
            int minutosJugados,
            int goles,
            int asistencias,
            int regates,
            int recuperaciones,
            int paradas,
            int tarjetasAmarillas,
            int tarjetasRojas,
            int golesEncajados,
            boolean lesionadoEnPartido,
            Integer notaPeriodico
    ) {}

    public record MaskedRoundFantasy(
            int puntosFantasy,
            int minutosVisibles,
            FantasyPointsBreakdownCalculator.Breakdown puntosDesglose
    ) {}

    public record LiveVisibleDerivedCounts(int goals, int assists, int regates, int recoveries, int saves, int reds, boolean injuredInMatch) {}

    private LeagueMatchLiveFantasyMask() {}

    public static LiveVisibleDerivedCounts deriveVisibleCounts(long idLigaJugador, List<LeagueMatchEventResponse> visibleEvents) {
        int g = 0;
        int a = 0;
        int reg = 0;
        int rec = 0;
        int par = 0;
        int roj = 0;
        boolean les = false;
        for (LeagueMatchEventResponse e : visibleEvents) {
            String t = e.tipo();
            if ("GOL".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                g++;
            } else if ("ASISTENCIA".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                a++;
            } else if ("REGATE".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                reg++;
            } else if ("RECUPERACION".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                rec++;
            } else if ("PARADA".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                par++;
            } else if ("TARJETA_ROJA".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                roj++;
            } else if ("LESION".equals(t) && Objects.equals(idLigaJugador, e.idLigaJugadorPrincipal())) {
                les = true;
            }
        }
        return new LiveVisibleDerivedCounts(g, a, reg, rec, par, roj, les);
    }

    public static long elapsedVisibleSeconds(Instant kickoff) {
        if (kickoff == null) {
            return 0L;
        }
        long elapsed = Duration.between(kickoff, Instant.now()).getSeconds();
        elapsed = Math.max(0L, elapsed);
        return Math.min(elapsed, FULL_MATCH_VISIBLE_SECONDS);
    }

    /**
     * Para cada {@code equipos.id} de catálogo que juega la jornada, metadatos del partido (ids de equipo local/visitante en catálogo).
     */
    public static Map<Long, MatchAnchor> anchorsByCatalogEquipo(Connection conn, long idJornada) throws SQLException {
        String sql = """
                SELECT pj.id,
                       pj.estado,
                       pj.inicio_en,
                       le_loc.id_equipo AS cat_loc,
                       le_vis.id_equipo AS cat_vis
                FROM partidos_jornada pj
                INNER JOIN liga_equipos le_loc ON le_loc.id = pj.id_liga_equipo_local
                INNER JOIN liga_equipos le_vis ON le_vis.id = pj.id_liga_equipo_visitante
                WHERE pj.id_jornada = ?
                """;
        Map<Long, MatchAnchor> out = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idPartido = rs.getLong("id");
                    String estado = rs.getString("estado");
                    Instant kick = rs.getTimestamp("inicio_en") == null ? null : rs.getTimestamp("inicio_en").toInstant();
                    long catLoc = rs.getLong("cat_loc");
                    long catVis = rs.getLong("cat_vis");
                    MatchAnchor anchor = new MatchAnchor(idPartido, estado, kick, catLoc, catVis);
                    mergeAnchor(out, catLoc, anchor);
                    mergeAnchor(out, catVis, anchor);
                }
            }
        }
        return out;
    }

    private static void mergeAnchor(Map<Long, MatchAnchor> out, long catalogId, MatchAnchor candidate) {
        MatchAnchor prev = out.get(catalogId);
        if (prev == null) {
            out.put(catalogId, candidate);
            return;
        }
        if ("EN_JUEGO".equals(candidate.estado()) && !"EN_JUEGO".equals(prev.estado())) {
            out.put(catalogId, candidate);
        }
    }

    public static List<LeagueMatchEventResponse> loadMatchEvents(Connection conn, long idPartido) throws SQLException {
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
                    if (rs.wasNull()) {
                        replayOffsetSec = null;
                    }
                    Long idLjPr = rs.getObject("id_liga_jugador", Long.class);
                    Long idJugPr = rs.getObject("id_jugador_principal", Long.class);
                    Long idLjSec = rs.getObject("id_liga_jugador_sec", Long.class);
                    Long idJugSec = rs.getObject("id_jugador_secundario", Long.class);
                    events.add(new LeagueMatchEventResponse(
                            rs.getLong("id"),
                            rs.getInt("minuto"),
                            rs.getInt("segundo"),
                            rs.getString("tipo"),
                            replayOffsetSec,
                            idLjPr,
                            rs.getObject("id_jugador_cedido_temporada", Integer.class),
                            buildDisplayName(rs.getString("nombre_principal"), rs.getString("pila_principal")),
                            buildPhotoUrl(idJugPr, rs.getObject("id_jugador_cedido_temporada", Integer.class)),
                            idLjSec,
                            rs.getObject("id_jugador_cedido_temporada_sec", Integer.class),
                            buildDisplayName(rs.getString("nombre_secundario"), rs.getString("pila_secundario")),
                            buildPhotoUrl(idJugSec, rs.getObject("id_jugador_cedido_temporada_sec", Integer.class)),
                            rs.getString("texto")
                    ));
                }
            }
        }
        return events;
    }

    private static String buildDisplayName(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        if (nombre != null && !nombre.isBlank()) {
            return nombre;
        }
        return null;
    }

    private static String buildPhotoUrl(Long idJugador, Integer idJugadorCedidoTemporada) {
        return com.eternalxi.eternalxi_api.util.LeagueAssetUrls.playerOrLoan(idJugador, idJugadorCedidoTemporada);
    }

    public static long eventSecond(LeagueMatchEventResponse e) {
        int m = e.minuto() == null ? 0 : e.minuto();
        int s = e.segundo() == null ? 0 : e.segundo();
        return (long) m * 60L + s;
    }

    public static List<LeagueMatchEventResponse> filterEventsVisibleNow(
            List<LeagueMatchEventResponse> all, long elapsedSeconds, boolean matchFinishedVisible
    ) {
        if (matchFinishedVisible) {
            return all;
        }
        List<LeagueMatchEventResponse> visible = new ArrayList<>();
        for (LeagueMatchEventResponse event : all) {
            if (eventSecond(event) <= elapsedSeconds) {
                visible.add(event);
            }
        }
        return visible;
    }

    public static Map<Long, Long> catalogByLigaJugadorIds(Connection conn, Collection<Long> ids) throws SQLException {
        Map<Long, Long> out = new HashMap<>();
        if (ids == null || ids.isEmpty()) {
            return out;
        }
        List<Long> idList = new ArrayList<>(ids);
        StringBuilder sql = new StringBuilder("SELECT id, id_equipo FROM liga_jugadores WHERE id IN (");
        for (int i = 0; i < idList.size(); i++) {
            if (i > 0) {
                sql.append(',');
            }
            sql.append('?');
        }
        sql.append(')');
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < idList.size(); i++) {
                ps.setLong(i + 1, idList.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.put(rs.getLong("id"), rs.getLong("id_equipo"));
                }
            }
        }
        return out;
    }

    private static long catalogOfLj(Connection conn, Long idLj, Map<Long, Long> cache) throws SQLException {
        if (idLj == null) {
            return -1L;
        }
        Long v = cache.get(idLj);
        if (v != null) {
            return v;
        }
        String sql = "SELECT id_equipo FROM liga_jugadores WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLj);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    cache.put(idLj, -1L);
                    return -1L;
                }
                long cat = rs.getLong("id_equipo");
                cache.put(idLj, cat);
                return cat;
            }
        }
    }

    /**
     * Recalcula fantasy y minutos visibles para un jugador en partido en directo.
     */
    public static MaskedRoundFantasy maskJpForLiveMatch(
            Connection conn,
            long idLigaJugador,
            String posicion,
            long catalogEquipo,
            MatchAnchor anchor,
            JpPersistentStats jp,
            Map<Long, List<LeagueMatchEventResponse>> eventsCache,
            Map<Long, Long> ljCatalogCache
    ) throws SQLException {
        if (anchor == null || !"EN_JUEGO".equals(anchor.estado())) {
            FantasyPointsBreakdownCalculator.Breakdown desglose = LeagueDataService.fantasyBreakdownLikeSimulation(
                    posicion,
                    jp.minutosJugados(),
                    jp.goles(),
                    jp.asistencias(),
                    jp.regates(),
                    jp.recuperaciones(),
                    jp.paradas(),
                    jp.golesEncajados(),
                    jp.tarjetasAmarillas(),
                    jp.tarjetasRojas(),
                    jp.lesionadoEnPartido(),
                    jp.notaPeriodico()
            );
            return new MaskedRoundFantasy(desglose.total(), jp.minutosJugados(), desglose);
        }

        long elapsed = elapsedVisibleSeconds(anchor.kickoff());
        long pid = anchor.idPartido();
        List<LeagueMatchEventResponse> all = eventsCache.get(pid);
        if (all == null) {
            all = loadMatchEvents(conn, pid);
            eventsCache.put(pid, all);
        }
        List<LeagueMatchEventResponse> vis = filterEventsVisibleNow(all, elapsed, false);

        int wallMinute = (int) Math.min(90L, elapsed / 60L);
        int minutosVis = jp.minutosJugados();
        if (wallMinute >= 1) {
            minutosVis = Math.min(minutosVis, wallMinute);
        } else {
            minutosVis = Math.min(minutosVis, 0);
        }

        LiveVisibleDerivedCounts d = deriveVisibleCounts(idLigaJugador, vis);

        int oppVisible = 0;
        for (LeagueMatchEventResponse e : vis) {
            if (!"GOL".equals(e.tipo())) {
                continue;
            }
            Long sid = e.idLigaJugadorPrincipal();
            if (sid == null) {
                continue;
            }
            long scCat = catalogOfLj(conn, sid, ljCatalogCache);
            if (scCat >= 0 && scCat != catalogEquipo) {
                oppVisible++;
            }
        }

        int gcUse = jp.golesEncajados();
        if ("POR".equals(posicion) || "DEF".equals(posicion)) {
            gcUse = Math.min(gcUse, oppVisible);
        }

        FantasyPointsBreakdownCalculator.Breakdown desglose = LeagueDataService.fantasyBreakdownLikeSimulation(
                posicion,
                minutosVis,
                d.goals(),
                d.assists(),
                d.regates(),
                d.recoveries(),
                d.saves(),
                gcUse,
                0,
                d.reds(),
                d.injuredInMatch(),
                null
        );

        return new MaskedRoundFantasy(desglose.total(), minutosVis, desglose);
    }

    public static int visibleMinutesCap(JpPersistentStats jp, Instant kickoff, String matchEstado) {
        if (!"EN_JUEGO".equals(matchEstado) || kickoff == null) {
            return jp.minutosJugados();
        }
        long elapsed = elapsedVisibleSeconds(kickoff);
        int wallMinute = (int) Math.min(90L, elapsed / 60L);
        if (wallMinute >= 1) {
            return Math.min(jp.minutosJugados(), wallMinute);
        }
        return Math.min(jp.minutosJugados(), 0);
    }

    public static int visibleConcededGoalsCap(String posicion, int jpGc, int oppGoalsVisible) {
        if ("POR".equals(posicion) || "DEF".equals(posicion)) {
            return Math.min(jpGc, oppGoalsVisible);
        }
        return jpGc;
    }

    public static int countVisibleOppositionGoals(
            Connection conn,
            List<LeagueMatchEventResponse> visibleEvents,
            long defendingCatalogEquipo,
            Map<Long, Long> ljCatalogCache
    ) throws SQLException {
        int opp = 0;
        for (LeagueMatchEventResponse e : visibleEvents) {
            if (!"GOL".equals(e.tipo())) {
                continue;
            }
            Long sid = e.idLigaJugadorPrincipal();
            if (sid == null) {
                continue;
            }
            long scCat = catalogOfLj(conn, sid, ljCatalogCache);
            if (scCat >= 0 && scCat != defendingCatalogEquipo) {
                opp++;
            }
        }
        return opp;
    }
}
