package com.eternalxi.eternalxi_api.tools;

import com.eternalxi.eternalxi_api.config.DBConnection;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Compresión de calendario de ligas existentes (solo fechas, sin tocar estados ni resultados).
 *
 * <p>{@code preview}: solo lectura, imprime plan completo. No crea tablas ni escribe en BD.</p>
 * <p>{@code apply}: backup v3, validaciones, actualiza fechas de filas movibles.</p>
 * <p>{@code rollback}: restaura desde backup v3.</p>
 *
 * <pre>
 *   .\mvnw.cmd -q exec:java "-Dexec.mainClass=com.eternalxi.eternalxi_api.tools.LeagueCalendarCompressionTool" "-Dexec.args=preview"
 * </pre>
 *
 * <p>Antes del preview: {@code sql/check_backup_compresion_cal_20260517.sql}</p>
 */
public final class LeagueCalendarCompressionTool {

    static final String TAG = "20260517_v3";
    static final String BAK_JORNADAS = "bak_jornadas_compresion_cal_20260517_v3";
    static final String BAK_PARTIDOS = "bak_partidos_compresion_cal_20260517_v3";
    static final String BAK_LIGAS_FIN = "bak_ligas_fin_en_compresion_cal_20260517_v3";

    private static final long LIGA_ORDEN_RARO = 8L;
    private static final int MAX_SLOTS = 8;

    private static final LocalTime[] WEEKDAY_TIMES = {
            LocalTime.of(17, 0), LocalTime.of(18, 30), LocalTime.of(20, 0), LocalTime.of(21, 30),
            LocalTime.of(17, 0), LocalTime.of(18, 30), LocalTime.of(20, 0), LocalTime.of(21, 30),
    };
    private static final int[] WEEKDAY_DAY_OFFSET = {0, 0, 0, 0, 1, 1, 1, 1};

    private static final LocalTime[] WEEKEND_TIMES = {
            LocalTime.of(17, 0), LocalTime.of(19, 0),
            LocalTime.of(17, 0), LocalTime.of(19, 0), LocalTime.of(21, 0),
            LocalTime.of(17, 0), LocalTime.of(19, 0), LocalTime.of(21, 0),
    };
    private static final int[] WEEKEND_DAY_OFFSET = {0, 0, 1, 1, 1, 2, 2, 2};

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final DateTimeFormatter D = DateTimeFormatter.ISO_LOCAL_DATE;

    private LeagueCalendarCompressionTool() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("Uso: preview | apply | rollback");
            System.exit(1);
        }
        switch (args[0].trim().toLowerCase()) {
            case "preview" -> runPreview();
            case "apply" -> runApply();
            case "rollback" -> runRollback();
            default -> {
                System.err.println("Modo desconocido: " + args[0]);
                System.exit(1);
            }
        }
    }

    private static void runPreview() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setReadOnly(true);
            List<PreviewRow> rows = buildPreviewRows(conn);
            printPreviewTable(rows);
            printPreviewSummary(rows);
        }
    }

    private static void runApply() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ensureBackupV3(conn);
                List<PreviewRow> rows = buildPreviewRows(conn);
                printPreviewTable(rows);
                validateForApply(conn, rows);
                int updated = applyMovableRows(conn, rows);
                conn.commit();
                System.out.println();
                System.out.println("APPLY OK | jornadas actualizadas (movibles): " + updated);
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private static void runRollback() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            if (!backupV3Exists(conn)) {
                throw new SQLException("No existe backup v3 (" + BAK_JORNADAS + ").");
            }
            conn.setAutoCommit(false);
            try {
                int j = restoreJornadas(conn);
                int p = restorePartidos(conn);
                int l = restoreLigasFinEn(conn);
                conn.commit();
                System.out.println("ROLLBACK OK | jornadas=" + j + " partidos=" + p + " ligas.fin_en=" + l);
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private static List<PreviewRow> buildPreviewRows(Connection conn) throws SQLException {
        Map<Long, String> leagueNames = loadLeagueNames(conn);
        Map<Long, List<PendingRound>> pendingByLeague = loadPendingRounds(conn);
        List<PreviewRow> rows = new ArrayList<>();

        for (Map.Entry<Long, List<PendingRound>> entry : pendingByLeague.entrySet()) {
            long idLiga = entry.getKey();
            String ligaNombre = leagueNames.getOrDefault(idLiga, "?");
            LeagueContext ctx = loadLeagueContext(conn, idLiga);
            boolean excluirLiga8 = idLiga == LIGA_ORDEN_RARO && ctx.nonlinearPendingOrder();

            LocalDate cursor = ctx.anchorDate();
            boolean nextMidweek = firstBlockIsMidweek(cursor);

            for (PendingRound round : entry.getValue()) {
                RoundSnapshot current = loadRoundSnapshot(conn, round);
                PreviewRow row = new PreviewRow();
                row.idLiga = idLiga;
                row.liga = ligaNombre;
                row.idJornada = round.idJornada();
                row.numeroJornada = round.numero();
                row.estado = current.estado();
                row.inicioActual = current.inicio();
                row.finActual = current.fin();
                row.primerPartidoActual = current.primerPartido();
                row.ultimoPartidoActual = current.ultimoPartido();
                row.partidos = current.partidosPendientes();
                row.partidosNoPendientes = current.partidosNoPendientes();

                List<String> issues = new ArrayList<>();
                if (row.partidosNoPendientes > 0) {
                    issues.add("PARTIDOS_NO_PENDIENTE_EN_JORNADA");
                }
                if (row.partidos > MAX_SLOTS) {
                    issues.add("DEMASIADOS_PARTIDOS");
                }

                ScheduledRound scheduled = null;
                if (issues.isEmpty()) {
                    try {
                        scheduled = scheduleRound(conn, ctx, round.numero(), row.partidos, cursor, nextMidweek);
                        row.bloqueNuevo = scheduled.midweek() ? "MIDWEEK" : "WEEKEND";
                        row.inicioNuevo = scheduled.inicio();
                        row.finNuevo = scheduled.fin();
                        row.primerPartidoNuevo = scheduled.primerPartido();
                        row.ultimoPartidoNuevo = scheduled.ultimoPartido();
                        row.matchKickoffs = scheduled.matchKickoffs();
                        cursor = scheduled.fin();
                        nextMidweek = !nextMidweek;

                        if (!row.primerPartidoNuevo.isAfter(LocalDateTime.now())) {
                            issues.add("KICKOFF_EN_PASADO");
                        }
                        String ordenVal = validateAgainstHigherRounds(
                                conn, idLiga, round.numero(), row.primerPartidoNuevo
                        );
                        if (ordenVal.startsWith("ERROR")) {
                            issues.add(ordenVal);
                        }
                    } catch (SQLException ex) {
                        issues.add("ERROR_PLAN:" + ex.getMessage());
                    }
                }

                if (excluirLiga8) {
                    row.movible = false;
                    List<String> motivos = new ArrayList<>();
                    motivos.add("ORDEN_NUMERO_NO_LINEAL_LIGA_8");
                    motivos.addAll(issues);
                    row.motivoNoMovible = String.join("; ", motivos);
                    row.validacion = buildValidacionLiga8(conn, idLiga, row, issues);
                } else if (!issues.isEmpty()) {
                    row.movible = false;
                    row.motivoNoMovible = String.join("; ", issues);
                    row.validacion = issues.stream().anyMatch(i -> i.startsWith("ERROR")) ? "ERROR" : "BLOQUEADO";
                } else {
                    row.movible = true;
                    row.motivoNoMovible = "";
                    row.validacion = ctx.nonlinearPendingOrder()
                            ? "WARN_NUMERO_NO_LINEAL;OK"
                            : "OK";
                }

                rows.add(row);
            }
        }
        return rows;
    }

    private static ScheduledRound scheduleRound(
            Connection conn,
            LeagueContext ctx,
            int numeroJornada,
            int numMatches,
            LocalDate cursor,
            boolean midweekBlock
    ) throws SQLException {
        boolean blockMidweek = midweekBlock;
        LocalDate blockStart = blockMidweek
                ? nextWeekdayStrictAfter(cursor, DayOfWeek.TUESDAY)
                : nextWeekdayStrictAfter(cursor, DayOfWeek.FRIDAY);

        LocalDate fin = blockMidweek ? blockStart.plusDays(1) : blockStart.plusDays(2);
        LocalDateTime[] slots = blockMidweek ? midweekSlots(blockStart) : weekendSlots(blockStart);
        LocalDateTime now = LocalDateTime.now();

        if (numMatches > slots.length) {
            throw new SQLException("mas de " + slots.length + " partidos");
        }

        LocalDateTime firstKickoff = slots[0];
        LocalDateTime minAfterHigher = ctx.maxKickoffAfterHigherRound(conn, numeroJornada);

        int guard = 0;
        while (guard++ < 24) {
            boolean pastNow = !firstKickoff.isAfter(now);
            boolean beforeHigher = minAfterHigher != null && !firstKickoff.isAfter(minAfterHigher);
            if (!pastNow && !beforeHigher) {
                break;
            }
            cursor = fin;
            blockMidweek = !blockMidweek;
            blockStart = blockMidweek
                    ? nextWeekdayStrictAfter(cursor, DayOfWeek.TUESDAY)
                    : nextWeekdayStrictAfter(cursor, DayOfWeek.FRIDAY);
            fin = blockMidweek ? blockStart.plusDays(1) : blockStart.plusDays(2);
            slots = blockMidweek ? midweekSlots(blockStart) : weekendSlots(blockStart);
            firstKickoff = slots[0];
        }

        if (!firstKickoff.isAfter(now)) {
            throw new SQLException("no hay bloque con kickoff > NOW()");
        }
        if (minAfterHigher != null && !firstKickoff.isAfter(minAfterHigher)) {
            throw new SQLException("no hay bloque posterior a jornada superior activa");
        }

        List<LocalDateTime> kickoffs = new ArrayList<>(numMatches);
        for (int i = 0; i < numMatches; i++) {
            kickoffs.add(slots[i]);
        }

        return new ScheduledRound(
                blockMidweek,
                blockStart,
                fin,
                kickoffs.get(0),
                kickoffs.get(kickoffs.size() - 1),
                kickoffs
        );
    }

    private static void validateForApply(Connection conn, List<PreviewRow> rows) throws SQLException {
        List<String> fatal = new ArrayList<>();

        for (PreviewRow row : rows) {
            if (row.partidosNoPendientes > 0) {
                fatal.add("Liga " + row.idLiga + " J" + row.numeroJornada + ": partidos no PENDIENTE en jornada PENDIENTE");
            }
            if (row.partidos > MAX_SLOTS) {
                fatal.add("Liga " + row.idLiga + " J" + row.numeroJornada + ": mas de " + MAX_SLOTS + " partidos");
            }
        }

        for (PreviewRow row : rows) {
            if (!row.movible) {
                continue;
            }
            if (row.primerPartidoNuevo == null || !row.primerPartidoNuevo.isAfter(LocalDateTime.now())) {
                fatal.add("Liga " + row.idLiga + " J" + row.numeroJornada + ": kickoff <= NOW()");
            }
            if (row.validacion != null && row.validacion.contains("ERROR")) {
                fatal.add("Liga " + row.idLiga + " J" + row.numeroJornada + ": " + row.validacion);
            }
            if (!hasBackupV3ForRound(conn, row.idJornada)) {
                fatal.add("Liga " + row.idLiga + " J" + row.numeroJornada + ": falta backup v3");
            }
        }

        PreviewRow j4 = rows.stream()
                .filter(r -> r.idLiga == LIGA_ORDEN_RARO && r.numeroJornada == 4)
                .findFirst()
                .orElse(null);
        if (j4 != null && j4.movible && j4.primerPartidoNuevo != null
                && !j4AfterJ5(conn, LIGA_ORDEN_RARO, j4.primerPartidoNuevo)) {
            fatal.add("Liga 8 J4: incluida en apply pero no queda despues de J5 EN_CURSO");
        }

        long movable = rows.stream().filter(r -> r.movible).count();
        if (movable == 0) {
            fatal.add("Ninguna fila movible; apply no actualizaria ninguna liga");
        }

        if (!fatal.isEmpty()) {
            throw new SQLException("APPLY abortado:\n- " + String.join("\n- ", fatal));
        }
    }

    private static boolean hasBackupV3ForRound(Connection conn, long idJornada) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM " + BAK_JORNADAS + " WHERE id = ?")) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private static int applyMovableRows(Connection conn, List<PreviewRow> rows) throws SQLException {
        String updateMatch = """
                UPDATE partidos_jornada pj
                INNER JOIN %s b ON b.id = pj.id
                SET pj.inicio_en = ?
                WHERE pj.id = ? AND pj.estado = 'PENDIENTE' AND (pj.inicio_en <=> b.inicio_en)
                """.formatted(BAK_PARTIDOS);

        String updateRound = """
                UPDATE jornadas j
                INNER JOIN %s b ON b.id = j.id
                SET j.inicio = ?, j.inicio_en = ?, j.fin = ?
                WHERE j.id = ? AND j.estado = 'PENDIENTE' AND (j.inicio_en <=> b.inicio_en)
                """.formatted(BAK_JORNADAS);

        int roundsUpdated = 0;
        try (PreparedStatement psMatch = conn.prepareStatement(updateMatch);
             PreparedStatement psRound = conn.prepareStatement(updateRound)) {

            for (PreviewRow row : rows) {
                if (!row.movible) {
                    continue;
                }

                List<Long> matchIds = loadPendingMatchIds(conn, row.idJornada);
                if (matchIds.size() != row.matchKickoffs.size()) {
                    throw new SQLException("Mismatch partidos jornada " + row.idJornada);
                }

                for (int i = 0; i < matchIds.size(); i++) {
                    psMatch.setTimestamp(1, Timestamp.valueOf(row.matchKickoffs.get(i)));
                    psMatch.setLong(2, matchIds.get(i));
                    psMatch.addBatch();
                }

                psRound.setDate(1, Date.valueOf(row.inicioNuevo));
                psRound.setTimestamp(2, Timestamp.valueOf(row.primerPartidoNuevo));
                psRound.setDate(3, Date.valueOf(row.finNuevo));
                psRound.setLong(4, row.idJornada);
                psRound.addBatch();
                roundsUpdated++;
            }
            psMatch.executeBatch();
            psRound.executeBatch();
        }

        updateLigasFinEn(conn);
        return roundsUpdated;
    }

    private static void ensureBackupV3(Connection conn) throws SQLException {
        try (Statement st = conn.createStatement()) {
            st.execute("""
                    CREATE TABLE IF NOT EXISTS %s (
                        id BIGINT NOT NULL PRIMARY KEY,
                        id_liga BIGINT NOT NULL,
                        numero INT NOT NULL,
                        inicio DATE NULL,
                        inicio_en DATETIME NULL,
                        fin DATE NULL,
                        estado VARCHAR(32) NOT NULL,
                        backed_up_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        migration_tag VARCHAR(32) NOT NULL DEFAULT '%s'
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                    """.formatted(BAK_JORNADAS, TAG));
            st.execute("""
                    CREATE TABLE IF NOT EXISTS %s (
                        id BIGINT NOT NULL PRIMARY KEY,
                        id_jornada BIGINT NOT NULL,
                        inicio_en DATETIME NULL,
                        estado VARCHAR(32) NOT NULL,
                        backed_up_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        migration_tag VARCHAR(32) NOT NULL DEFAULT '%s',
                        KEY idx_jornada (id_jornada)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                    """.formatted(BAK_PARTIDOS, TAG));
            st.execute("""
                    CREATE TABLE IF NOT EXISTS %s (
                        id_liga BIGINT NOT NULL PRIMARY KEY,
                        fin_en DATE NULL,
                        backed_up_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        migration_tag VARCHAR(32) NOT NULL DEFAULT '%s'
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                    """.formatted(BAK_LIGAS_FIN, TAG));
        }

        execUpdate(conn, """
                INSERT INTO %s (id, id_liga, numero, inicio, inicio_en, fin, estado)
                SELECT j.id, j.id_liga, j.numero, j.inicio, j.inicio_en, j.fin, j.estado
                FROM jornadas j
                WHERE j.estado = 'PENDIENTE'
                  AND NOT EXISTS (SELECT 1 FROM %s b WHERE b.id = j.id)
                """.formatted(BAK_JORNADAS, BAK_JORNADAS));

        execUpdate(conn, """
                INSERT INTO %s (id, id_jornada, inicio_en, estado)
                SELECT pj.id, pj.id_jornada, pj.inicio_en, pj.estado
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE j.estado = 'PENDIENTE' AND pj.estado = 'PENDIENTE'
                  AND NOT EXISTS (SELECT 1 FROM %s b WHERE b.id = pj.id)
                """.formatted(BAK_PARTIDOS, BAK_PARTIDOS));

        execUpdate(conn, """
                INSERT INTO %s (id_liga, fin_en)
                SELECT l.id, l.fin_en FROM ligas l
                WHERE EXISTS (
                    SELECT 1 FROM jornadas j WHERE j.id_liga = l.id AND j.estado = 'PENDIENTE'
                )
                AND NOT EXISTS (SELECT 1 FROM %s b WHERE b.id_liga = l.id)
                """.formatted(BAK_LIGAS_FIN, BAK_LIGAS_FIN));
    }

    private static boolean backupV3Exists(Connection conn) throws SQLException {
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT COUNT(*) AS c FROM information_schema.TABLES "
                             + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '" + BAK_JORNADAS + "'")) {
            rs.next();
            return rs.getInt("c") > 0;
        }
    }

    private static int restoreJornadas(Connection conn) throws SQLException {
        return conn.createStatement().executeUpdate("""
                UPDATE jornadas j
                INNER JOIN %s b ON b.id = j.id
                SET j.inicio = b.inicio, j.inicio_en = b.inicio_en, j.fin = b.fin
                WHERE j.estado = 'PENDIENTE'
                """.formatted(BAK_JORNADAS));
    }

    private static int restorePartidos(Connection conn) throws SQLException {
        return conn.createStatement().executeUpdate("""
                UPDATE partidos_jornada pj
                INNER JOIN %s b ON b.id = pj.id
                SET pj.inicio_en = b.inicio_en
                WHERE pj.estado = 'PENDIENTE'
                """.formatted(BAK_PARTIDOS));
    }

    private static int restoreLigasFinEn(Connection conn) throws SQLException {
        return conn.createStatement().executeUpdate("""
                UPDATE ligas l
                INNER JOIN %s b ON b.id_liga = l.id
                SET l.fin_en = b.fin_en
                """.formatted(BAK_LIGAS_FIN));
    }

    private static void updateLigasFinEn(Connection conn) throws SQLException {
        conn.createStatement().executeUpdate("""
                UPDATE ligas l
                INNER JOIN %s bl ON bl.id_liga = l.id
                INNER JOIN (
                    SELECT id_liga, MAX(fin) AS nuevo_fin
                    FROM jornadas
                    GROUP BY id_liga
                ) x ON x.id_liga = l.id
                SET l.fin_en = x.nuevo_fin
                """.formatted(BAK_LIGAS_FIN));
    }

    private static void printPreviewTable(List<PreviewRow> rows) {
        System.out.println("=== PREVIEW CALENDARIO COMPRIMIDO (solo lectura, sin escritura BD) ===");
        System.out.printf(
                "%-7s %-18s %-9s %-4s %-11s %-7s %-30s %-8s %-11s %-11s %-11s %-11s "
                        + "%-19s %-19s %-19s %-19s %-4s %-7s %-22s%n",
                "id_liga", "liga", "id_jorn", "num", "estado", "movible", "motivo_no_movible",
                "bloque", "inicio_act", "inicio_nue", "fin_act", "fin_nue",
                "p1_actual", "p1_nuevo", "pN_actual", "pN_nuevo", "part", "no_pend", "validacion"
        );
        for (PreviewRow r : rows) {
            System.out.printf(
                    "%-7d %-18.18s %-9d %-4d %-11s %-7s %-30s %-8s %-11s %-11s %-11s %-11s "
                            + "%-19s %-19s %-19s %-19s %-4d %-7d %-22s%n",
                    r.idLiga,
                    trunc(r.liga, 18),
                    r.idJornada,
                    r.numeroJornada,
                    r.estado,
                    r.movible ? "true" : "false",
                    trunc(r.motivoNoMovible, 30),
                    nullToDash(r.bloqueNuevo),
                    fmtDate(r.inicioActual),
                    fmtDate(r.inicioNuevo),
                    fmtDate(r.finActual),
                    fmtDate(r.finNuevo),
                    fmtDt(r.primerPartidoActual),
                    fmtDt(r.primerPartidoNuevo),
                    fmtDt(r.ultimoPartidoActual),
                    fmtDt(r.ultimoPartidoNuevo),
                    r.partidos,
                    r.partidosNoPendientes,
                    trunc(r.validacion, 22)
            );
        }
    }

    private static void printPreviewSummary(List<PreviewRow> rows) {
        long movable = rows.stream().filter(r -> r.movible).count();
        long liga8 = rows.stream().filter(r -> r.idLiga == LIGA_ORDEN_RARO).count();
        System.out.println();
        System.out.println("=== RESUMEN ===");
        System.out.println("Filas: " + rows.size() + " | Movibles (apply): " + movable + " | Liga 8 en preview: " + liga8);
        System.out.println("Liga 8: movible=false por ORDEN_NUMERO_NO_LINEAL_LIGA_8 (plan visible para revision)");
        System.out.println("Backup apply/rollback: tablas *_" + TAG);
    }

    private static LeagueContext loadLeagueContext(Connection conn, long idLiga) throws SQLException {
        LocalDate maxFin = null;
        LocalDateTime maxNonPendingKickoff = null;
        boolean hasActiveOrDone = false;
        int minPendingNum = Integer.MAX_VALUE;
        int maxActiveNum = -1;

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT numero, estado, fin FROM jornadas WHERE id_liga = ?")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int num = rs.getInt("numero");
                    String est = rs.getString("estado");
                    if ("PENDIENTE".equals(est)) {
                        minPendingNum = Math.min(minPendingNum, num);
                    }
                    if ("EN_CURSO".equals(est) || "FINALIZADA".equals(est)) {
                        hasActiveOrDone = true;
                        maxActiveNum = Math.max(maxActiveNum, num);
                        Date fin = rs.getDate("fin");
                        if (fin != null) {
                            LocalDate d = fin.toLocalDate();
                            maxFin = maxFin == null ? d : (d.isAfter(maxFin) ? d : maxFin);
                        }
                    }
                }
            }
        }

        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT MAX(pj.inicio_en) AS mx
                FROM partidos_jornada pj
                INNER JOIN jornadas j ON j.id = pj.id_jornada
                WHERE j.id_liga = ? AND pj.estado <> 'PENDIENTE'
                """)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Timestamp ts = rs.getTimestamp("mx");
                    if (ts != null) {
                        maxNonPendingKickoff = ts.toLocalDateTime();
                    }
                }
            }
        }

        LocalDate anchor;
        if (hasActiveOrDone) {
            LocalDate fromMatches = maxNonPendingKickoff == null ? null : maxNonPendingKickoff.toLocalDate();
            anchor = maxFin;
            if (fromMatches != null) {
                anchor = anchor == null ? fromMatches : (fromMatches.isAfter(anchor) ? fromMatches : anchor);
            }
            if (anchor == null) {
                anchor = LocalDate.now();
            }
        } else {
            anchor = LocalDate.now();
        }

        boolean nonlinear = minPendingNum != Integer.MAX_VALUE && maxActiveNum >= 0 && minPendingNum < maxActiveNum;
        return new LeagueContext(idLiga, anchor, nonlinear);
    }

    private static boolean j4AfterJ5(Connection conn, long idLiga, LocalDateTime j4First) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT MAX(pj.inicio_en) AS mx, MAX(j.fin) AS fin_j5
                FROM jornadas j
                LEFT JOIN partidos_jornada pj ON pj.id_jornada = j.id
                WHERE j.id_liga = ? AND j.numero = 5 AND j.estado = 'EN_CURSO'
                """)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                Timestamp mx = rs.getTimestamp("mx");
                Date fin = rs.getDate("fin_j5");
                LocalDateTime ref = mx != null
                        ? mx.toLocalDateTime()
                        : (fin != null ? fin.toLocalDate().atTime(23, 59, 59) : LocalDateTime.MIN);
                return j4First.isAfter(ref);
            }
        }
    }

    private static String buildValidacionLiga8(Connection conn, long idLiga, PreviewRow row, List<String> issues)
            throws SQLException {
        if (row.partidosNoPendientes > 0) {
            return "WARN_NUMERO_NO_LINEAL;ERROR;PARTIDOS_NO_PENDIENTE";
        }
        if (row.primerPartidoNuevo == null) {
            return "WARN_NUMERO_NO_LINEAL;ERROR;SIN_PLAN";
        }
        if (!row.primerPartidoNuevo.isAfter(LocalDateTime.now())) {
            return "WARN_NUMERO_NO_LINEAL;ERROR;KICKOFF_PASADO";
        }
        if (row.numeroJornada == 4 && !j4AfterJ5(conn, idLiga, row.primerPartidoNuevo)) {
            return "WARN_NUMERO_NO_LINEAL;ERROR;J4_NO_DESPUES_J5";
        }
        if (!issues.isEmpty()) {
            return "WARN_NUMERO_NO_LINEAL;" + String.join(";", issues);
        }
        return "WARN_NUMERO_NO_LINEAL;OK_PLAN";
    }

    private static String validateAgainstHigherRounds(
            Connection conn,
            long idLiga,
            int numero,
            LocalDateTime firstNew
    ) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT MAX(pj.inicio_en) AS mx
                FROM jornadas j
                INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id
                WHERE j.id_liga = ?
                  AND j.estado IN ('EN_CURSO', 'FINALIZADA')
                  AND j.numero > ?
                """)) {
            ps.setLong(1, idLiga);
            ps.setInt(2, numero);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return "OK";
                }
                Timestamp ts = rs.getTimestamp("mx");
                if (ts == null) {
                    return "OK";
                }
                return firstNew.isAfter(ts.toLocalDateTime()) ? "OK" : "ERROR;ANTES_JORNADA_SUPERIOR";
            }
        }
    }

    private static RoundSnapshot loadRoundSnapshot(Connection conn, PendingRound round) throws SQLException {
        String estado;
        LocalDate inicio = null;
        LocalDate fin = null;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT estado, inicio, fin FROM jornadas WHERE id = ?")) {
            ps.setLong(1, round.idJornada());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                estado = rs.getString("estado");
                if (rs.getDate("inicio") != null) {
                    inicio = rs.getDate("inicio").toLocalDate();
                }
                if (rs.getDate("fin") != null) {
                    fin = rs.getDate("fin").toLocalDate();
                }
            }
        }

        int pend = 0;
        int noPend = 0;
        LocalDateTime minP = null;
        LocalDateTime maxP = null;
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT
                    SUM(CASE WHEN estado = 'PENDIENTE' THEN 1 ELSE 0 END) AS pend,
                    SUM(CASE WHEN estado <> 'PENDIENTE' THEN 1 ELSE 0 END) AS no_pend,
                    MIN(CASE WHEN estado = 'PENDIENTE' THEN inicio_en END) AS min_p,
                    MAX(CASE WHEN estado = 'PENDIENTE' THEN inicio_en END) AS max_p
                FROM partidos_jornada WHERE id_jornada = ?
                """)) {
            ps.setLong(1, round.idJornada());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                pend = rs.getInt("pend");
                noPend = rs.getInt("no_pend");
                Timestamp t1 = rs.getTimestamp("min_p");
                Timestamp t2 = rs.getTimestamp("max_p");
                if (t1 != null) {
                    minP = t1.toLocalDateTime();
                }
                if (t2 != null) {
                    maxP = t2.toLocalDateTime();
                }
            }
        }
        return new RoundSnapshot(estado, inicio, fin, minP, maxP, pend, noPend);
    }

    private static List<Long> loadPendingMatchIds(Connection conn, long idJornada) throws SQLException {
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT id FROM partidos_jornada
                WHERE id_jornada = ? AND estado = 'PENDIENTE'
                ORDER BY COALESCE(inicio_en, '9999-12-31'), id
                """)) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id"));
                }
            }
        }
        return ids;
    }

    private static Map<Long, List<PendingRound>> loadPendingRounds(Connection conn) throws SQLException {
        Map<Long, List<PendingRound>> map = new TreeMap<>();
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT id, id_liga, numero FROM jornadas
                WHERE estado = 'PENDIENTE'
                ORDER BY id_liga, numero, id
                """);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                long idLiga = rs.getLong("id_liga");
                map.computeIfAbsent(idLiga, k -> new ArrayList<>())
                        .add(new PendingRound(rs.getLong("id"), idLiga, rs.getInt("numero")));
            }
        }
        return map;
    }

    private static Map<Long, String> loadLeagueNames(Connection conn) throws SQLException {
        Map<Long, String> names = new LinkedHashMap<>();
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT id, nombre FROM ligas")) {
            while (rs.next()) {
                names.put(rs.getLong("id"), rs.getString("nombre"));
            }
        }
        return names;
    }

    private static void execUpdate(Connection conn, String sql) throws SQLException {
        try (Statement st = conn.createStatement()) {
            st.executeUpdate(sql);
        }
    }

    private static boolean firstBlockIsMidweek(LocalDate cursor) {
        LocalDate nextTue = nextWeekdayStrictAfter(cursor, DayOfWeek.TUESDAY);
        LocalDate nextFri = nextWeekdayStrictAfter(cursor, DayOfWeek.FRIDAY);
        return !nextTue.isAfter(nextFri);
    }

    private static LocalDate nextWeekdayStrictAfter(LocalDate after, DayOfWeek target) {
        LocalDate d = after.plusDays(1);
        while (d.getDayOfWeek() != target) {
            d = d.plusDays(1);
        }
        return d;
    }

    private static LocalDateTime[] midweekSlots(LocalDate tuesday) {
        LocalDateTime[] slots = new LocalDateTime[MAX_SLOTS];
        for (int i = 0; i < MAX_SLOTS; i++) {
            slots[i] = LocalDateTime.of(tuesday.plusDays(WEEKDAY_DAY_OFFSET[i]), WEEKDAY_TIMES[i]);
        }
        return slots;
    }

    private static LocalDateTime[] weekendSlots(LocalDate friday) {
        LocalDateTime[] slots = new LocalDateTime[MAX_SLOTS];
        for (int i = 0; i < MAX_SLOTS; i++) {
            slots[i] = LocalDateTime.of(friday.plusDays(WEEKEND_DAY_OFFSET[i]), WEEKEND_TIMES[i]);
        }
        return slots;
    }

    private static String fmtDt(LocalDateTime dt) {
        return dt == null ? "-" : dt.format(DT);
    }

    private static String fmtDate(LocalDate d) {
        return d == null ? "-" : d.format(D);
    }

    private static String nullToDash(String s) {
        return s == null || s.isBlank() ? "-" : s;
    }

    private static String trunc(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() <= max ? s : s.substring(0, max - 1) + "...";
    }

    private record PendingRound(long idJornada, long idLiga, int numero) {
    }

    private record RoundSnapshot(
            String estado,
            LocalDate inicio,
            LocalDate fin,
            LocalDateTime primerPartido,
            LocalDateTime ultimoPartido,
            int partidosPendientes,
            int partidosNoPendientes
    ) {
    }

    private record ScheduledRound(
            boolean midweek,
            LocalDate inicio,
            LocalDate fin,
            LocalDateTime primerPartido,
            LocalDateTime ultimoPartido,
            List<LocalDateTime> matchKickoffs
    ) {
    }

    private static final class LeagueContext {
        private final long idLiga;
        private final LocalDate anchorDate;
        private final boolean nonlinearPendingOrder;

        LeagueContext(long idLiga, LocalDate anchorDate, boolean nonlinear) {
            this.idLiga = idLiga;
            this.anchorDate = anchorDate;
            this.nonlinearPendingOrder = nonlinear;
        }

        LocalDate anchorDate() {
            return anchorDate;
        }

        boolean nonlinearPendingOrder() {
            return nonlinearPendingOrder;
        }

        LocalDateTime maxKickoffAfterHigherRound(Connection conn, int numeroPendiente) throws SQLException {
            try (PreparedStatement ps = conn.prepareStatement("""
                    SELECT MAX(pj.inicio_en) AS mx
                    FROM jornadas j
                    INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id
                    WHERE j.id_liga = ?
                      AND j.estado IN ('EN_CURSO', 'FINALIZADA')
                      AND j.numero > ?
                    """)) {
                ps.setLong(1, idLiga);
                ps.setInt(2, numeroPendiente);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return null;
                    }
                    Timestamp ts = rs.getTimestamp("mx");
                    return ts == null ? null : ts.toLocalDateTime();
                }
            }
        }
    }

    static final class PreviewRow {
        long idLiga;
        String liga;
        long idJornada;
        int numeroJornada;
        String estado;
        boolean movible;
        String motivoNoMovible = "";
        String bloqueNuevo;
        LocalDate inicioActual;
        LocalDate inicioNuevo;
        LocalDate finActual;
        LocalDate finNuevo;
        LocalDateTime primerPartidoActual;
        LocalDateTime primerPartidoNuevo;
        LocalDateTime ultimoPartidoActual;
        LocalDateTime ultimoPartidoNuevo;
        int partidos;
        int partidosNoPendientes;
        String validacion = "";
        List<LocalDateTime> matchKickoffs = List.of();
    }
}
