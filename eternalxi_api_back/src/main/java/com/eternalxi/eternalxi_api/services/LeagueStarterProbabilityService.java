package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueStarterProbabilitiesResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueStarterProbabilityRowResponse;
import com.eternalxi.eternalxi_api.dto.league.StarterProbabilityLite;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Probabilidad de titularidad alineada con la preparación automática de partidos en
 * {@link LeagueSimulationService}: mismo {@code selectionScore} (valoración + forma − cansancio − duda),
 * mismos cupos de formación y mismos desempates ({@code valoracion}, {@code valor}, nombre).
 */
@Service
public class LeagueStarterProbabilityService {

    /** Jornada mostrada + equipo de catálogo (misma semántica que en plantilla/ficha). */
    public record CatalogTeamRound(Long idJornada, Long idCatalogEquipo) {}

    private static final Logger log = LoggerFactory.getLogger(LeagueStarterProbabilityService.class);

    private static final String VERSION_MODELO = "v3_2";
    private static final int PROB_CAP = 100;
    /** Mínimo mostrado/guardado para jugadores elegibles (el front no debe ver 1 %). */
    private static final int PROB_MIN_ELIGIBLE = 7;
    private static final int PROB_PREPARED_STARTER = 95;
    private static final int PROB_PREPARED_BENCH = 15;
    private static final String MOTIVO_ONCE_PREPARADO = "Once ya preparado";

    public void recalculateForLeague(Long idLiga) throws SQLException {
        if (idLiga == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            Long idJornada = findNextOpenRoundId(conn, idLiga);
            if (idJornada == null) {
                return;
            }
            recalculateForRound(conn, idLiga, idJornada);
        }
    }

    /**
     * Recalcula la próxima jornada abierta (no finalizada) de cada liga que tenga al menos una.
     * Pensado para el scheduler diario.
     */
    public void recalculateNextOpenRoundForAllLeagues() throws SQLException {
        List<Long> leagueIds;
        try (Connection conn = DBConnection.getConnection()) {
            leagueIds = loadDistinctLeagueIdsWithOpenRound(conn);
        }
        for (Long idLiga : leagueIds) {
            recalculateForLeague(idLiga);
        }
    }

    public void recalculateForRound(Long idLiga, Long idJornada) throws SQLException {
        if (idLiga == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            verifyRoundBelongsToLeague(conn, idLiga, idJornada);
            recalculateForRound(conn, idLiga, idJornada);
        }
    }

    public void recalculateForMatch(Long idLiga, Long idPartido) throws SQLException {
        if (idLiga == null || idPartido == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            verifyMatchBelongsToLeague(conn, idLiga, idPartido);
            recalculateForMatchInternal(conn, idLiga, idPartido);
        }
    }

    /**
     * Recalcula probabilidades tras comprobar que el usuario participa en la liga.
     * Si {@code idPartido} no es nulo, solo ese partido; si no, si {@code idJornada} no es nula esa jornada;
     * en caso contrario la próxima jornada abierta de la liga.
     */
    public void recalculateForParticipant(
            Long idLiga,
            Long idUsuario,
            Long idJornada,
            Long idPartido
    ) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
        }
        if (idPartido != null) {
            recalculateForMatch(idLiga, idPartido);
        } else if (idJornada != null) {
            recalculateForRound(idLiga, idJornada);
        } else {
            recalculateForLeague(idLiga);
        }
    }

    /**
     * Si no hay filas de probabilidad para jugadores de esos equipos en esa jornada, recalcula cada
     * {@code id_partido} implicado una sola vez (local y visitante del mismo duelo se deduplican).
     */
    public void ensureProbabilitiesForCatalogTeamRounds(Long idLiga, Set<CatalogTeamRound> teamRounds) {
        if (idLiga == null || teamRounds == null || teamRounds.isEmpty()) {
            return;
        }
        Set<Long> partidoIds = new LinkedHashSet<>();
        try (Connection conn = DBConnection.getConnection()) {
            for (CatalogTeamRound tr : teamRounds) {
                if (tr.idJornada() == null || tr.idCatalogEquipo() == null) {
                    continue;
                }
                Long pid = loadFirstPartidoIdForCatalogTeamInRound(conn, idLiga, tr.idJornada(), tr.idCatalogEquipo());
                if (pid != null) {
                    partidoIds.add(pid);
                }
            }
        } catch (SQLException e) {
            log.warn(
                    "No se pudieron resolver partidos para probabilidades al vuelo (liga={}): {}",
                    idLiga,
                    e.getMessage());
            return;
        }
        for (Long idPartido : partidoIds) {
            try {
                recalculateForMatch(idLiga, idPartido);
            } catch (SQLException e) {
                log.warn(
                        "Fallo recálculo automático de probabilidades (liga={}, partido={}): {}",
                        idLiga,
                        idPartido,
                        e.getMessage());
            }
        }
    }

    public LeagueStarterProbabilitiesResponse listProbabilities(Long idLiga, Long idJornada, Long idUsuario)
            throws SQLException {
        if (idLiga == null || idJornada == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);
            verifyRoundBelongsToLeague(conn, idLiga, idJornada);
            Integer numero = loadRoundNumber(conn, idJornada);
            List<LeagueStarterProbabilityRowResponse> rows = loadProbabilityRows(conn, idLiga, idJornada);
            return new LeagueStarterProbabilitiesResponse(idLiga, idJornada, numero, rows);
        }
    }

    /**
     * Jornada para leer probabilidades: la explícita (debe pertenecer a la liga) o la próxima abierta
     * {@code PENDIENTE}/{@code EN_CURSO}, alineada con el recálculo de titularidad.
     */
    public Long resolveTargetJornadaForProbabilities(Connection conn, Long idLiga, Long idJornadaExplicit)
            throws SQLException {
        if (idLiga == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if (idJornadaExplicit != null) {
            verifyRoundBelongsToLeague(conn, idLiga, idJornadaExplicit);
            return idJornadaExplicit;
        }
        return findNextOpenRoundId(conn, idLiga);
    }

    /**
     * Jornada cuyas filas de {@link #loadProbabilityMapForLeaguePlayers} debe usar la UI por equipo de catálogo:
     * partido del equipo {@code PENDIENTE} o {@code EN_JUEGO} → misma jornada base;
     * {@code FINALIZADO} → siguiente jornada {@code PENDIENTE}/{@code EN_CURSO}.
     */
    public Long resolveDisplayJornadaForTeamStarterProbability(
            Connection conn,
            Long idLiga,
            Long idJornadaExplicit,
            Long idCatalogEquipo
    ) throws SQLException {
        if (idCatalogEquipo == null) {
            return resolveTargetJornadaForProbabilities(conn, idLiga, idJornadaExplicit);
        }
        Long base = resolveTargetJornadaForProbabilities(conn, idLiga, idJornadaExplicit);
        if (base == null) {
            return null;
        }
        String estado = loadTeamMatchEstadoForRound(conn, idLiga, base, idCatalogEquipo);
        if (estado == null) {
            return base;
        }
        if ("FINALIZADO".equals(estado)) {
            Integer numero = loadRoundNumber(conn, base);
            if (numero == null) {
                return null;
            }
            return findNextOpenRoundAfterNumero(conn, idLiga, numero);
        }
        return base;
    }

    /**
     * Probabilidades para UI alineadas con la jornada “display” por equipo de catálogo
     * (plantilla, mercado de compra y ficha de jugador).
     */
    public Map<Long, StarterProbabilityLite> loadDisplayProbabilityMapForPlayers(
            Connection conn,
            Long idLiga,
            Long idJornadaExplicit,
            Map<Long, Long> ligaJugadorToEquipo
    ) throws SQLException {
        if (idLiga == null || ligaJugadorToEquipo == null || ligaJugadorToEquipo.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<Long, Long> displayRoundByEquipo = new HashMap<>();
        for (Long eq : new LinkedHashSet<>(ligaJugadorToEquipo.values())) {
            if (eq == null) {
                continue;
            }
            displayRoundByEquipo.put(
                    eq,
                    resolveDisplayJornadaForTeamStarterProbability(conn, idLiga, idJornadaExplicit, eq));
        }

        Map<Long, List<Long>> jugadoresPorJornada = new HashMap<>();
        for (Map.Entry<Long, Long> entry : ligaJugadorToEquipo.entrySet()) {
            Long idLigaJugador = entry.getKey();
            Long idEquipo = entry.getValue();
            if (idLigaJugador == null || idEquipo == null) {
                continue;
            }
            Long idJornadaDisplay = displayRoundByEquipo.get(idEquipo);
            if (idJornadaDisplay == null) {
                continue;
            }
            jugadoresPorJornada.computeIfAbsent(idJornadaDisplay, k -> new ArrayList<>()).add(idLigaJugador);
        }

        Map<Long, StarterProbabilityLite> prob = new HashMap<>();
        for (Map.Entry<Long, List<Long>> batch : jugadoresPorJornada.entrySet()) {
            prob.putAll(loadProbabilityMapForLeaguePlayers(conn, idLiga, batch.getKey(), batch.getValue()));
        }

        LinkedHashSet<CatalogTeamRound> equiposSinProb = new LinkedHashSet<>();
        for (Map.Entry<Long, Long> entry : ligaJugadorToEquipo.entrySet()) {
            Long idLigaJugador = entry.getKey();
            Long idEquipo = entry.getValue();
            if (idLigaJugador == null || idEquipo == null) {
                continue;
            }
            Long idJornadaDisplay = displayRoundByEquipo.get(idEquipo);
            if (idJornadaDisplay == null) {
                continue;
            }
            if (!prob.containsKey(idLigaJugador)) {
                equiposSinProb.add(new CatalogTeamRound(idJornadaDisplay, idEquipo));
            }
        }
        if (!equiposSinProb.isEmpty()) {
            ensureProbabilitiesForCatalogTeamRounds(idLiga, equiposSinProb);
            prob.clear();
            for (Map.Entry<Long, List<Long>> batch : jugadoresPorJornada.entrySet()) {
                prob.putAll(loadProbabilityMapForLeaguePlayers(conn, idLiga, batch.getKey(), batch.getValue()));
            }
        }

        return prob;
    }

    /**
     * Una sola lectura por lote de ids (varias consultas si el IN supera el tamaño máximo).
     * Si hay varias filas por jugador en la jornada, se conserva la de {@code calculado_en} más reciente
     * y desempate por {@code id} descendente.
     */
    public Map<Long, StarterProbabilityLite> loadProbabilityMapForLeaguePlayers(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Collection<Long> idLigaJugadores
    ) throws SQLException {
        if (idJornada == null || idLiga == null || idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Long> ids = idLigaJugadores.stream().filter(Objects::nonNull).distinct().toList();
        if (ids.isEmpty()) {
            return Collections.emptyMap();
        }
        final int maxIn = 450;
        Map<Long, ProbRowPick> best = new HashMap<>();
        for (int from = 0; from < ids.size(); from += maxIn) {
            List<Long> chunk = ids.subList(from, Math.min(from + maxIn, ids.size()));
            String inClause = chunk.stream().map(id -> "?").collect(Collectors.joining(","));
            String sql = String.format(
                    """
                    SELECT id, id_liga_jugador, id_partido_jornada, probabilidad_titular, motivo_resumen, calculado_en
                    FROM liga_jugador_titularidad_probabilidad
                    WHERE id_liga = ?
                      AND id_jornada = ?
                      AND id_liga_jugador IN (%s)
                    """,
                    inClause
            );
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                int ix = 1;
                ps.setLong(ix++, idLiga);
                ps.setLong(ix++, idJornada);
                for (Long id : chunk) {
                    ps.setLong(ix++, id);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long rowId = rs.getLong("id");
                        long lj = rs.getLong("id_liga_jugador");
                        Timestamp calcTs = rs.getTimestamp("calculado_en");
                        Instant instant = calcTs == null ? null : calcTs.toInstant();
                        ProbRowPick candidate = new ProbRowPick(
                                rowId,
                                rs.getLong("id_partido_jornada"),
                                rs.getInt("probabilidad_titular"),
                                rs.getString("motivo_resumen"),
                                instant
                        );
                        best.merge(lj, candidate, ProbRowPick::prefer);
                    }
                }
            }
        }
        Map<Long, StarterProbabilityLite> out = new HashMap<>();
        for (Map.Entry<Long, ProbRowPick> e : best.entrySet()) {
            ProbRowPick r = e.getValue();
            out.put(
                    e.getKey(),
                    new StarterProbabilityLite(
                            r.probabilidad(),
                            r.motivo(),
                            r.idPartido(),
                            r.calculadoEn()
                    )
            );
        }
        return out;
    }

    void recalculateForRound(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        List<Long> partidos = loadMatchIdsForRound(conn, idLiga, idJornada);
        for (Long idPartido : partidos) {
            recalculateForMatchInternal(conn, idLiga, idPartido);
        }
    }

    private void recalculateForMatchInternal(Connection conn, Long idLiga, Long idPartido) throws SQLException {
        MatchContext ctx = loadMatchContext(conn, idLiga, idPartido);
        if (ctx == null) {
            throw new IllegalArgumentException("Partido no encontrado");
        }
        boolean prepared = hasPreparedLineup(conn, idPartido);
        List<ProbabilityInsertRow> rows = new ArrayList<>();
        rows.addAll(computeProbabilitiesForTeam(conn, ctx, true, prepared));
        rows.addAll(computeProbabilitiesForTeam(conn, ctx, false, prepared));
        replaceProbabilitiesForMatch(conn, idLiga, ctx.idJornada(), idPartido, rows);
    }

    private List<ProbabilityInsertRow> computeProbabilitiesForTeam(
            Connection conn,
            MatchContext ctx,
            boolean localSide,
            boolean lineupPrepared
    ) throws SQLException {
        long idLigaEquipo = localSide ? ctx.idLigaEquipoLocal() : ctx.idLigaEquipoVisitante();
        long catalogEquipoId = localSide ? ctx.catalogEquipoLocal() : ctx.catalogEquipoVisitante();
        String formationRaw = localSide ? ctx.alineacionLocal() : ctx.alineacionVisitante();
        String equipoNombre = localSide ? ctx.nombreEquipoLocal() : ctx.nombreEquipoVisitante();
        TeamFormation formation = parseFormation(formationRaw);

        List<SquadPlayerEval> squad = loadFullSquad(conn, ctx.idLiga(), catalogEquipoId);
        Map<Long, Boolean> preparedTitular = lineupPrepared
                ? loadPreparedTitularByLigaJugador(conn, ctx.idPartido(), idLigaEquipo)
                : Map.of();

        if (lineupPrepared) {
            List<ProbabilityInsertRow> out = new ArrayList<>();
            for (SquadPlayerEval p : squad) {
                if (!isEligibleForMatchPool(p.estado())) {
                    out.add(buildRow(ctx.idPartido(), idLigaEquipo, p, 0, "No disponible", catalogEquipoId, equipoNombre));
                    continue;
                }
                Boolean tit = preparedTitular.get(p.idLigaJugador());
                if (Boolean.TRUE.equals(tit)) {
                    out.add(buildRow(ctx.idPartido(), idLigaEquipo, p, PROB_PREPARED_STARTER, MOTIVO_ONCE_PREPARADO,
                            catalogEquipoId, equipoNombre));
                } else if (Boolean.FALSE.equals(tit)) {
                    out.add(buildRow(ctx.idPartido(), idLigaEquipo, p, PROB_PREPARED_BENCH, MOTIVO_ONCE_PREPARADO,
                            catalogEquipoId, equipoNombre));
                } else {
                    out.add(buildRow(ctx.idPartido(), idLigaEquipo, p, 0,
                            MOTIVO_ONCE_PREPARADO + " (no convocado)", catalogEquipoId, equipoNombre));
                }
            }
            return out;
        }

        String formacionLabel = formation.def() + "-" + formation.med() + "-" + formation.del();
        return computeUnpreparedBatch(
                ctx.idLiga(),
                ctx.idPartido(),
                idLigaEquipo,
                squad,
                formation,
                formacionLabel,
                catalogEquipoId,
                equipoNombre
        );
    }

    private ProbabilityInsertRow buildRow(
            long idPartido,
            long idLigaEquipo,
            SquadPlayerEval p,
            int prob,
            String motivo,
            long catalogEquipoId,
            String equipoNombre
    ) {
        return new ProbabilityInsertRow(
                idPartido,
                idLigaEquipo,
                p.idLigaJugador(),
                prob,
                motivo,
                p.idJugador(),
                p.nombre(),
                p.pila(),
                p.posicion(),
                p.valoracion(),
                p.estado(),
                p.cansancio(),
                catalogEquipoId,
                equipoNombre
        );
    }

    /** Contexto solo para trazas ante datos de formación/plantilla extremos. */
    private record ProbCalcLog(long idLiga, long idPartido, long idLigaEquipo, String equipoNombre) {}

    private List<ProbabilityInsertRow> computeUnpreparedBatch(
            long idLiga,
            long idPartido,
            long idLigaEquipo,
            List<SquadPlayerEval> squad,
            TeamFormation formation,
            String formacionLabel,
            long catalogEquipoId,
            String equipoNombre
    ) {
        List<SquadPlayerEval> eligiblePlayers = squad.stream()
                .filter(p -> isEligibleForMatchPool(p.estado()))
                .toList();
        if (eligiblePlayers.size() <= 11) {
            List<ProbabilityInsertRow> forcedOut = new ArrayList<>();
            for (SquadPlayerEval p : squad) {
                int prob = isEligibleForMatchPool(p.estado()) ? PROB_CAP : 0;
                String motivo = isEligibleForMatchPool(p.estado())
                        ? "Plantilla disponible corta (<=11): titular prácticamente asegurado"
                        : "No disponible";
                forcedOut.add(new ProbabilityInsertRow(
                        idPartido,
                        idLigaEquipo,
                        p.idLigaJugador(),
                        prob,
                        motivo,
                        p.idJugador(),
                        p.nombre(),
                        p.pila(),
                        p.posicion(),
                        p.valoracion(),
                        p.estado(),
                        p.cansancio(),
                        catalogEquipoId,
                        equipoNombre
                ));
            }
            return forcedOut;
        }

        Map<String, List<SquadPlayerEval>> byPos = new HashMap<>();
        for (SquadPlayerEval p : squad) {
            if (!isEligibleForMatchPool(p.estado())) {
                continue;
            }
            byPos.computeIfAbsent(normalizePos(p.posicion()), k -> new ArrayList<>()).add(p);
        }
        for (List<SquadPlayerEval> list : byPos.values()) {
            list.sort(simulationConvocatoriaComparator());
        }

        Map<Long, ProbResult> results = new HashMap<>();
        ProbCalcLog calcLog = new ProbCalcLog(idLiga, idPartido, idLigaEquipo, equipoNombre);
        for (String pos : List.of("POR", "DEF", "MED", "DEL")) {
            int slots = slotsForPosition(formation, pos);
            List<SquadPlayerEval> list = byPos.getOrDefault(pos, List.of());
            applyPositionProbabilities(calcLog, pos, list, slots, formacionLabel, results);
        }
        for (SquadPlayerEval p : squad) {
            if (!isEligibleForMatchPool(p.estado())) {
                results.put(p.idLigaJugador(), new ProbResult(0, "No disponible"));
            }
        }
        for (SquadPlayerEval p : squad) {
            if (!results.containsKey(p.idLigaJugador())) {
                results.put(p.idLigaJugador(), new ProbResult(PROB_MIN_ELIGIBLE, "Posición no usada en la formación"));
            }
        }

        List<ProbabilityInsertRow> out = new ArrayList<>();
        for (SquadPlayerEval p : squad) {
            int prob;
            String motivo;
            if (!isEligibleForMatchPool(p.estado())) {
                prob = 0;
                motivo = "No disponible";
            } else {
                ProbResult r = results.get(p.idLigaJugador());
                prob = clampProbEligible(r.prob());
                motivo = r.motivo();
            }
            out.add(new ProbabilityInsertRow(
                    idPartido,
                    idLigaEquipo,
                    p.idLigaJugador(),
                    prob,
                    motivo,
                    p.idJugador(),
                    p.nombre(),
                    p.pila(),
                    p.posicion(),
                    p.valoracion(),
                    p.estado(),
                    p.cansancio(),
                    catalogEquipoId,
                    equipoNombre
            ));
        }
        return out;
    }

    /** Igual que {@link LeagueSimulationService#sortBySelectionDescending}: score, valoración, valor mercado, nombre. */
    private Comparator<SquadPlayerEval> simulationConvocatoriaComparator() {
        return Comparator.comparingDouble(SquadPlayerEval::selectionScore).reversed()
                .thenComparingInt(SquadPlayerEval::valoracion).reversed()
                .thenComparingLong(SquadPlayerEval::valorMercado).reversed()
                .thenComparing(SquadPlayerEval::nombre);
    }

    private void applyPositionProbabilities(
            ProbCalcLog calcLog,
            String posLine,
            List<SquadPlayerEval> sorted,
            int slots,
            String formacionLabel,
            Map<Long, ProbResult> results
    ) {
        if (slots <= 0) {
            if (!sorted.isEmpty()) {
                logEdgeCaseProb(calcLog, posLine, slots, sorted.size(), formacionLabel);
                for (SquadPlayerEval p : sorted) {
                    String motivo = "Sin plaza en formación para esta línea (" + formacionLabel + ")";
                    results.put(
                            p.idLigaJugador(),
                            new ProbResult(clampProbEligible(10), appendFatigueDoubtMotivo(motivo, p))
                    );
                }
            }
            return;
        }

        if (sorted.isEmpty()) {
            return;
        }

        int n = sorted.size();
        double[] scores = new double[n];
        for (int i = 0; i < n; i++) {
            scores[i] = sorted.get(i).selectionScore();
        }

        if (slots == 1) {
            applyGoalkeeperProbabilities(sorted, scores, formacionLabel, results);
            return;
        }

        if (slots > n) {
            logEdgeCaseProb(calcLog, posLine, slots, n, formacionLabel);
        }

        /*
         * Referencia “banquillo/límite”: si hay más candidatos que cupos, el primero fuera es scores[slots].
         * Si hay menos o igual candidatos que cupos, no existe ese índice: usar peor candidato − margen.
         */
        final double benchScoreRef = n > slots ? scores[slots] : scores[n - 1] - 18.0;
        final boolean insufficientCandidatesInLine = n <= slots;

        for (int i = 0; i < n; i++) {
            int rank = i + 1;
            SquadPlayerEval p = sorted.get(i);
            if (rank <= slots) {
                double spread = scores[i] - benchScoreRef;
                double raw;
                if (insufficientCandidatesInLine) {
                    raw = 99 - Math.max(0, (rank - 1) * 2);
                } else {
                    raw = 63.0 + spread * 2.55 + (slots - rank) * 5.0 + (rank == slots ? 5.0 : 0.0);
                    raw = Math.min(100.0, Math.max(52.0, raw));
                }
                String motivo = rank == 1
                        ? "Titular muy probable: mejor score de convocatoria en " + p.posicion()
                        : "Titular probable: " + rank + "º " + p.posicion() + " en formación " + formacionLabel;
                if (insufficientCandidatesInLine) {
                    motivo = "Titular casi fijo: menos jugadores que plazas en la línea (" + formacionLabel + ")";
                }
                motivo = appendFatigueDoubtMotivo(motivo, p);
                results.put(p.idLigaJugador(), new ProbResult(clampProbEligible((int) Math.round(raw)), motivo));
            } else {
                int worstStarterIdx = Math.min(slots - 1, n - 1);
                double gapVsWorstStarter = scores[worstStarterIdx] - scores[i];
                int depthIdx = rank - (slots + 1);
                double raw = 44.0 - gapVsWorstStarter * 8.5 - depthIdx * 5.0;
                raw = Math.min(38.0, Math.max(PROB_MIN_ELIGIBLE, raw));
                String motivo = depthIdx == 0
                        ? "Fuera del cupo titular: diferencia de score con el peor titular de la línea"
                        : "Suplente profundo en " + p.posicion();
                motivo = appendFatigueDoubtMotivo(motivo, p);
                results.put(p.idLigaJugador(), new ProbResult(clampProbEligible((int) Math.round(raw)), motivo));
            }
        }
    }

    private void logEdgeCaseProb(ProbCalcLog c, String posLine, int cupo, int candidates, String formacionLabel) {
        log.warn(
                "Titularidad (caso límite): idLiga={} idPartido={} idLigaEquipo={} equipo={} formacion={} pos={} cupo={} candidates={}",
                c.idLiga(),
                c.idPartido(),
                c.idLigaEquipo(),
                c.equipoNombre(),
                formacionLabel,
                posLine,
                cupo,
                candidates
        );
    }

    /** Una sola plaza; diferencias según el mismo {@code selectionScore} que usa la simulación. */
    private void applyGoalkeeperProbabilities(
            List<SquadPlayerEval> sorted,
            double[] scores,
            String formacionLabel,
            Map<Long, ProbResult> results
    ) {
        int n = sorted.size();
        for (int i = 0; i < n; i++) {
            int rank = i + 1;
            SquadPlayerEval p = sorted.get(i);
            if (rank == 1) {
                double gapToSecond = n >= 2 ? scores[0] - scores[1] : 12.0;
                double topRaw = 82.0 + Math.min(14.0, gapToSecond * 2.2);
                topRaw = Math.min(97.0, Math.max(76.0, topRaw));
                String motivo = "Titular muy probable: 1º portero en " + formacionLabel;
                motivo = appendFatigueDoubtMotivo(motivo, p);
                results.put(p.idLigaJugador(), new ProbResult(clampProbEligible((int) Math.round(topRaw)), motivo));
            } else if (rank == 2) {
                double gap = scores[0] - scores[1];
                double backupRaw = 8.0 + 58.0 * Math.exp(-1.05 * Math.max(0.0, gap));
                backupRaw = Math.min(40.0, Math.max(PROB_MIN_ELIGIBLE, backupRaw));
                String motivo = "Suplente de portería: diferencia de score de convocatoria con el titular";
                motivo = appendFatigueDoubtMotivo(motivo, p);
                results.put(p.idLigaJugador(), new ProbResult(clampProbEligible((int) Math.round(backupRaw)), motivo));
            } else {
                double gapFromFirst = scores[0] - scores[i];
                double raw = Math.max(PROB_MIN_ELIGIBLE, 12.0 - gapFromFirst * 1.8 - (rank - 3) * 5.0);
                String motivo = "Tercer portero o más: probabilidad muy baja";
                motivo = appendFatigueDoubtMotivo(motivo, p);
                results.put(p.idLigaJugador(), new ProbResult(clampProbEligible((int) Math.round(raw)), motivo));
            }
        }
    }

    private String appendFatigueDoubtMotivo(String motivo, SquadPlayerEval p) {
        String out = motivo;
        if (p.cansancio() >= 70) {
            out = out + "; cansancio alto";
        } else if (p.cansancio() >= 35) {
            out = out + "; cansancio moderado";
        } else if (p.cansancio() > 0) {
            out = out + "; algo de cansancio";
        }
        if ("DUDA".equalsIgnoreCase(p.estado())) {
            out = out + "; duda";
        }
        return out;
    }

    private int clampProbEligible(int p) {
        return Math.min(PROB_CAP, Math.max(PROB_MIN_ELIGIBLE, p));
    }

    private String normalizePos(String pos) {
        if (pos == null) {
            return "UNK";
        }
        return switch (pos) {
            case "POR", "DEF", "MED", "DEL" -> pos;
            default -> "UNK";
        };
    }

    private int slotsForPosition(TeamFormation f, String pos) {
        if (pos == null) {
            return 0;
        }
        return switch (pos) {
            case "POR" -> 1;
            case "DEF" -> f.def();
            case "MED" -> f.med();
            case "DEL" -> f.del();
            default -> 0;
        };
    }

    private boolean isEligibleForMatchPool(String estado) {
        return "DISPONIBLE".equalsIgnoreCase(estado) || "DUDA".equalsIgnoreCase(estado);
    }

    private void replaceProbabilitiesForMatch(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long idPartido,
            List<ProbabilityInsertRow> rows
    ) throws SQLException {
        String del = "DELETE FROM liga_jugador_titularidad_probabilidad WHERE id_partido_jornada = ?";
        try (PreparedStatement ps = conn.prepareStatement(del)) {
            ps.setLong(1, idPartido);
            ps.executeUpdate();
        }
        if (rows.isEmpty()) {
            return;
        }
        String ins = """
                INSERT INTO liga_jugador_titularidad_probabilidad (
                    id_liga, id_jornada, id_partido_jornada, id_liga_equipo, id_liga_jugador,
                    probabilidad_titular, motivo_resumen, version_modelo
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(ins)) {
            for (ProbabilityInsertRow r : rows) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idJornada);
                ps.setLong(3, idPartido);
                ps.setLong(4, r.idLigaEquipo());
                ps.setLong(5, r.idLigaJugador());
                ps.setInt(6, r.probabilidadTitular());
                ps.setString(7, truncate(r.motivoResumen(), 255));
                ps.setString(8, VERSION_MODELO);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private String truncate(String s, int max) {
        if (s == null) {
            return null;
        }
        return s.length() <= max ? s : s.substring(0, max);
    }

    private boolean hasPreparedLineup(Connection conn, Long idPartido) throws SQLException {
        String sql = "SELECT COUNT(*) AS c FROM alineacion_partido WHERE id_partido_jornada = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("c") > 0;
            }
        }
    }

    private Map<Long, Boolean> loadPreparedTitularByLigaJugador(Connection conn, Long idPartido, long idLigaEquipo)
            throws SQLException {
        String sql = """
                SELECT id_liga_jugador, titular
                FROM alineacion_partido
                WHERE id_partido_jornada = ?
                  AND id_liga_equipo = ?
                  AND id_liga_jugador IS NOT NULL
                """;
        Map<Long, Boolean> map = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            ps.setLong(2, idLigaEquipo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getLong("id_liga_jugador"), rs.getBoolean("titular"));
                }
            }
        }
        return map;
    }

    private List<SquadPlayerEval> loadFullSquad(Connection conn, Long idLiga, long catalogEquipoId) throws SQLException {
        String sql = """
                SELECT lj.id AS id_liga_jugador,
                       j.id AS id_jugador,
                       j.nombre,
                       j.pila,
                       j.posicion,
                       COALESCE(lj.valoracion_actual, j.valoracion) AS valoracion_actual,
                       COALESCE(lj.valor, 0) AS valor_mercado,
                       lj.estado,
                       lj.cansancio,
                       COALESCE((
                           SELECT AVG(t.puntos)
                           FROM (
                               SELECT jp.puntos
                               FROM jugadores_puntos_jornada jp
                               WHERE jp.id_liga_jugador = lj.id
                               ORDER BY jp.id_jornada DESC
                               LIMIT 5
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
                ORDER BY j.posicion, lj.id ASC
                """;
        List<SquadPlayerEval> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, catalogEquipoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    double vr = rs.getDouble("valoracion_actual");
                    long valorMercado = rs.getLong("valor_mercado");
                    double m3 = rs.getDouble("media_ultimos_3");
                    double ms = rs.getDouble("media_temporada");
                    int cans = rs.getInt("cansancio");
                    String estado = rs.getString("estado");
                    double sel = calculateSelectionScore(vr, m3, ms, cans, estado);
                    list.add(
                            new SquadPlayerEval(
                                    rs.getLong("id_liga_jugador"),
                                    rs.getLong("id_jugador"),
                                    rs.getString("nombre"),
                                    rs.getString("pila"),
                                    rs.getString("posicion"),
                                    (int) Math.round(vr),
                                    estado,
                                    cans,
                                    valorMercado,
                                    sel
                            )
                    );
                }
            }
        }
        return list;
    }

    private MatchContext loadMatchContext(Connection conn, Long idLiga, Long idPartido) throws SQLException {
        String sql = """
                SELECT pj.id AS id_partido,
                       pj.id_jornada,
                       j.id_liga,
                       le_l.id AS id_le_local,
                       le_v.id AS id_le_visit,
                       e_l.id AS id_eq_local,
                       e_v.id AS id_eq_visit,
                       e_l.alineacion AS alin_local,
                       e_v.alineacion AS alin_visit,
                       e_l.nombre AS nombre_local,
                       e_v.nombre AS nombre_visit
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                INNER JOIN liga_equipos le_l
                    ON le_l.id_liga = j.id_liga AND le_l.id_equipo = pj.id_liga_equipo_local
                INNER JOIN equipos e_l ON e_l.id = le_l.id_equipo
                INNER JOIN liga_equipos le_v
                    ON le_v.id_liga = j.id_liga AND le_v.id_equipo = pj.id_liga_equipo_visitante
                INNER JOIN equipos e_v ON e_v.id = le_v.id_equipo
                WHERE pj.id = ?
                  AND j.id_liga = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new MatchContext(
                        rs.getLong("id_partido"),
                        rs.getLong("id_jornada"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_le_local"),
                        rs.getLong("id_le_visit"),
                        rs.getLong("id_eq_local"),
                        rs.getLong("id_eq_visit"),
                        rs.getString("alin_local"),
                        rs.getString("alin_visit"),
                        rs.getString("nombre_local"),
                        rs.getString("nombre_visit")
                );
            }
        }
    }

    private List<Long> loadMatchIdsForRound(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT pj.id
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE j.id = ?
                  AND j.id_liga = ?
                ORDER BY pj.inicio_en ASC, pj.id ASC
                """;
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id"));
                }
            }
        }
        return ids;
    }

    private Long findNextOpenRoundId(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                WHERE j.id_liga = ?
                  AND j.estado IN ('PENDIENTE', 'EN_CURSO')
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

    private Long findNextOpenRoundAfterNumero(Connection conn, Long idLiga, int numeroExclusiveLowerBound)
            throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                WHERE j.id_liga = ?
                  AND j.numero > ?
                  AND j.estado IN ('PENDIENTE', 'EN_CURSO')
                ORDER BY j.numero ASC, j.id ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setInt(2, numeroExclusiveLowerBound);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private String loadTeamMatchEstadoForRound(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long idCatalogEquipo
    ) throws SQLException {
        String sql = """
                SELECT pj.estado
                FROM partidos_jornada pj
                INNER JOIN jornadas jo ON jo.id = pj.id_jornada
                WHERE jo.id = ?
                  AND jo.id_liga = ?
                  AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                ORDER BY pj.inicio_en ASC, pj.id ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            ps.setLong(3, idCatalogEquipo);
            ps.setLong(4, idCatalogEquipo);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getString("estado");
            }
        }
    }

    private Long loadFirstPartidoIdForCatalogTeamInRound(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long idCatalogEquipo
    ) throws SQLException {
        String sql = """
                SELECT pj.id
                FROM partidos_jornada pj
                INNER JOIN jornadas jo ON jo.id = pj.id_jornada
                WHERE jo.id = ?
                  AND jo.id_liga = ?
                  AND (pj.id_liga_equipo_local = ? OR pj.id_liga_equipo_visitante = ?)
                ORDER BY pj.inicio_en ASC, pj.id ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            ps.setLong(3, idCatalogEquipo);
            ps.setLong(4, idCatalogEquipo);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private List<Long> loadDistinctLeagueIdsWithOpenRound(Connection conn) throws SQLException {
        String sql = """
                SELECT DISTINCT j.id_liga
                FROM jornadas j
                WHERE j.estado IN ('PENDIENTE', 'EN_CURSO')
                ORDER BY j.id_liga ASC
                """;
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ids.add(rs.getLong("id_liga"));
            }
        }
        return ids;
    }

    private Integer loadRoundNumber(Connection conn, Long idJornada) throws SQLException {
        String sql = "SELECT numero FROM jornadas WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getInt("numero");
            }
        }
    }

    private List<LeagueStarterProbabilityRowResponse> loadProbabilityRows(
            Connection conn,
            Long idLiga,
            Long idJornada
    ) throws SQLException {
        String sql = """
                SELECT p.id_partido_jornada,
                       p.id_liga_equipo,
                       e.id AS id_equipo,
                       e.nombre AS nombre_equipo,
                       p.id_liga_jugador,
                       j.id AS id_jugador,
                       j.nombre,
                       j.pila,
                       j.posicion,
                       CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                       lj.estado,
                       lj.cansancio,
                       p.probabilidad_titular,
                       p.motivo_resumen
                FROM liga_jugador_titularidad_probabilidad p
                INNER JOIN liga_jugadores lj ON lj.id = p.id_liga_jugador
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN liga_equipos le ON le.id = p.id_liga_equipo
                INNER JOIN equipos e ON e.id = le.id_equipo
                WHERE p.id_liga = ?
                  AND p.id_jornada = ?
                ORDER BY p.id_partido_jornada ASC, e.nombre ASC, j.posicion, p.probabilidad_titular DESC, j.nombre ASC
                """;
        List<LeagueStarterProbabilityRowResponse> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(
                            new LeagueStarterProbabilityRowResponse(
                                    rs.getLong("id_partido_jornada"),
                                    rs.getLong("id_liga_equipo"),
                                    rs.getLong("id_equipo"),
                                    rs.getString("nombre_equipo"),
                                    rs.getLong("id_liga_jugador"),
                                    rs.getLong("id_jugador"),
                                    rs.getString("nombre"),
                                    rs.getString("pila"),
                                    rs.getString("posicion"),
                                    rs.getInt("valoracion"),
                                    rs.getString("estado"),
                                    rs.getInt("cansancio"),
                                    rs.getInt("probabilidad_titular"),
                                    rs.getString("motivo_resumen")
                            )
                    );
                }
            }
        }
        return rows;
    }

    private void verifyRoundBelongsToLeague(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = "SELECT 1 FROM jornadas WHERE id = ? AND id_liga = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Jornada no encontrada en la liga");
                }
            }
        }
    }

    private void verifyMatchBelongsToLeague(Connection conn, Long idLiga, Long idPartido) throws SQLException {
        String sql = """
                SELECT 1
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE pj.id = ?
                  AND j.id_liga = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPartido);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Partido no encontrado en la liga");
                }
            }
        }
    }

    private void ensureParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT 1
                FROM liga_participantes lp
                WHERE lp.id_liga = ?
                  AND lp.id_usuario = ?
                LIMIT 1
                """;
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

    private TeamFormation parseFormation(String raw) {
        TeamFormation fallback = new TeamFormation(4, 3, 3);
        if (raw == null || raw.isBlank()) {
            return fallback;
        }
        String normalized = raw.trim().replace(" ", "");
        String[] parts = normalized.split("-");
        if (parts.length != 3) {
            return fallback;
        }
        try {
            int def = Integer.parseInt(parts[0]);
            int med = Integer.parseInt(parts[1]);
            int del = Integer.parseInt(parts[2]);
            if (def < 0 || med < 0 || del < 0 || def + med + del != 10) {
                return fallback;
            }
            return new TeamFormation(def, med, del);
        } catch (NumberFormatException e) {
            return fallback;
        }
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

    private static double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private record TeamFormation(int def, int med, int del) {}

    private record MatchContext(
            long idPartido,
            long idJornada,
            long idLiga,
            long idLigaEquipoLocal,
            long idLigaEquipoVisitante,
            long catalogEquipoLocal,
            long catalogEquipoVisitante,
            String alineacionLocal,
            String alineacionVisitante,
            String nombreEquipoLocal,
            String nombreEquipoVisitante
    ) {}

    private record SquadPlayerEval(
            long idLigaJugador,
            long idJugador,
            String nombre,
            String pila,
            String posicion,
            int valoracion,
            String estado,
            int cansancio,
            long valorMercado,
            double selectionScore
    ) {}

    private record ProbResult(int prob, String motivo) {}

    /**
     * Fila interna antes de insertar (incluye datos de presentación para no releer).
     */
    private record ProbabilityInsertRow(
            long idPartido,
            long idLigaEquipo,
            long idLigaJugador,
            int probabilidadTitular,
            String motivoResumen,
            long idJugador,
            String nombre,
            String pila,
            String posicion,
            int valoracion,
            String estado,
            int cansancio,
            long catalogEquipoId,
            String equipoNombre
    ) {}

    private record ProbRowPick(long rowId, long idPartido, int probabilidad, String motivo, Instant calculadoEn) {
        static ProbRowPick prefer(ProbRowPick a, ProbRowPick b) {
            Instant ta = a.calculadoEn();
            Instant tb = b.calculadoEn();
            if (ta != null && tb != null) {
                int cmp = ta.compareTo(tb);
                if (cmp > 0) {
                    return a;
                }
                if (cmp < 0) {
                    return b;
                }
            } else if (ta != null) {
                return a;
            } else if (tb != null) {
                return b;
            }
            return a.rowId() >= b.rowId() ? a : b;
        }
    }
}
