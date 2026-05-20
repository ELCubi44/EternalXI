package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueAssignedCoachResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueEditableLineupResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueEmptySlotResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueMatchEventResponse;
import com.eternalxi.eternalxi_api.dto.league.ParticipantRoundFantasyBreakdown;
import com.eternalxi.eternalxi_api.dto.league.SaveLeagueLineupRequest;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class LeagueLineupService {

    private static final int STARTERS_TOTAL = 11;
    private static final int MAX_RESERVES_TOTAL = 4;
    private static final String DEFAULT_FORMATION = "4-3-3";

    public LeagueEditableLineupResponse getEditableLineup(Long idLiga, Long idUsuario) throws SQLException {
    if (idLiga == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        Long idLigaParticipante = findLeagueParticipantId(conn, idLiga, idUsuario);
        if (idLigaParticipante == null) {
            throw new IllegalArgumentException("Participante no encontrado en la liga");
        }

        EditableRoundData editableRound = findEditableRound(conn, idLiga);
        if (editableRound == null) {
            throw new IllegalArgumentException("No hay jornadas editables disponibles");
        }

        FormationSpec formationSpec = resolveEffectiveFormationSpec(conn, idLigaParticipante);
        LineupSnapshot exactSnapshot = loadExactSavedLineupForRound(
                conn,
                idLigaParticipante,
                editableRound.idJornada()
        );

        boolean bloqueada = isRoundKickoffStarted(conn, editableRound.idJornada());

        LineupSnapshot snapshot = exactSnapshot;
        boolean fromSavedLineup = false;

        if (!bloqueada) {
            if (snapshot != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, snapshot, formationSpec)) {
                fromSavedLineup = true;
            } else {
                snapshot = null;
            }

            if (snapshot == null) {
                LineupSnapshot reusable = loadLastReusableLineupBeforeRound(
                        conn,
                        idLiga,
                        idLigaParticipante,
                        editableRound.numero()
                );

                if (reusable != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, reusable, formationSpec)) {
                    snapshot = reusable;
                    fromSavedLineup = true;
                }
            }

            LineupSnapshot optimizedSnapshot = optimizeSnapshotWithCurrentSquad(
                    conn,
                    idLiga,
                    idUsuario,
                    snapshot,
                    formationSpec
            );
            if (optimizedSnapshot != snapshot) {
                snapshot = optimizedSnapshot;
                fromSavedLineup = false;
            }
            if (snapshot == null) {
                snapshot = buildDefaultSnapshot(conn, idLiga, idUsuario, formationSpec);
                fromSavedLineup = false;
            }

            if (exactSnapshot == null || !sameSnapshot(exactSnapshot, snapshot)) {
                persistLineup(conn, idLigaParticipante, editableRound.idJornada(), snapshot);
            } else {
                syncLineupArtifactsForRound(conn, editableRound.idJornada(), idLigaParticipante, snapshot);
            }
        } else {
            if (snapshot != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, snapshot, formationSpec)) {
                fromSavedLineup = true;
            } else {
                snapshot = null;
            }

            if (snapshot == null) {
                LineupSnapshot reusable = loadLastReusableLineupBeforeRound(
                        conn,
                        idLiga,
                        idLigaParticipante,
                        editableRound.numero()
                );

                if (reusable != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, reusable, formationSpec)) {
                    snapshot = reusable;
                    fromSavedLineup = true;
                }
            }

            if (snapshot == null) {
                snapshot = buildDefaultSnapshot(conn, idLiga, idUsuario, formationSpec);
                fromSavedLineup = false;
            }
        }
        LeagueAssignedCoachResponse entrenadorAsignado = loadAssignedCoachByParticipant(conn, idLigaParticipante);
        boolean entrenadorActivo = entrenadorAsignado != null && Boolean.TRUE.equals(entrenadorAsignado.activo());
        String formacionEfectiva = formationSpec.value();
        List<LeagueEmptySlotResponse> emptySlots = loadEmptySlotsForRound(conn, editableRound.idJornada(), idLigaParticipante);

        return new LeagueEditableLineupResponse(
                idLiga,
                idLigaParticipante,
                editableRound.idJornada(),
                editableRound.numero(),
                editableRound.editableHasta(),
                bloqueada,
                fromSavedLineup,
                entrenadorAsignado,
                entrenadorActivo,
                formacionEfectiva,
                extractIds(snapshot.titulares()),
                extractIds(snapshot.reservas()),
                snapshot.idCapitan(),
                emptySlots
        );
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

    private FormationSpec resolveEffectiveFormationSpec(Connection conn, Long idLigaParticipante) throws SQLException {
        LeagueAssignedCoachResponse coach = loadAssignedCoachByParticipant(conn, idLigaParticipante);
        if (coach == null || !Boolean.TRUE.equals(coach.activo())) {
            return FormationSpec.default433();
        }
        return FormationSpec.parseOrDefault(coach.formacion());
    }

    /**
     * Cadena "{def}-{med}-{del}" para una jornada: prioriza config/alineación persistida (sin usar el míster actual).
     */
    public String getFormationDisplayForRound(Connection conn, Long idLigaParticipante, Long idJornada) throws SQLException {
        return resolveFormationSpecForRound(conn, idLigaParticipante, idJornada).value();
    }

    private FormationSpec resolveFormationSpecForRound(
            Connection conn,
            Long idLigaParticipante,
            Long idJornada
    ) throws SQLException {
        FormationSpec inferred = loadFormationSpecFromStoredLineup(conn, idLigaParticipante, idJornada);
        String stored = loadStoredFormationForRound(conn, idLigaParticipante, idJornada);
        if (stored != null && !stored.isBlank()) {
            FormationSpec storedSpec = FormationSpec.parseOrDefault(stored);
            if (inferred != null && !storedSpec.value().equals(inferred.value())) {
                return inferred;
            }
            return storedSpec;
        }
        if (inferred != null) {
            return inferred;
        }

        return FormationSpec.default433();
    }

    private FormationSpec loadFormationSpecFromStoredLineup(
            Connection conn,
            Long idLigaParticipante,
            Long idJornada
    ) throws SQLException {
        LineupSnapshot snapshot = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
        if (snapshot == null) {
            return null;
        }
        return inferFormationSpecFromSnapshot(snapshot);
    }

    private FormationSpec inferFormationSpecFromSnapshot(LineupSnapshot snapshot) {
        if (snapshot == null || snapshot.titulares() == null || snapshot.titulares().isEmpty()) {
            return null;
        }

        int por = countByPosition(snapshot.titulares(), "POR");
        int def = countByPosition(snapshot.titulares(), "DEF");
        int med = countByPosition(snapshot.titulares(), "MED");
        int del = countByPosition(snapshot.titulares(), "DEL");
        if (por == 1 && (def + med + del) == 10) {
            return new FormationSpec(1, def, med, del);
        }
        return null;
    }

    private String loadStoredFormationForRound(Connection conn, Long idLigaParticipante, Long idJornada) throws SQLException {
        String sql = """
                SELECT formacion_efectiva
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
                    return null;
                }
                return rs.getString("formacion_efectiva");
            }
        }
    }

    private void ensureLineupConfigSnapshotForRound(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante
    ) throws SQLException {
        LineupConfigSnapshot snapshot = buildLineupConfigSnapshot(conn, idLigaParticipante);
        upsertLineupConfigSnapshot(conn, idJornada, idLigaParticipante, snapshot);
    }

    private void syncLineupArtifactsForRound(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante,
            LineupSnapshot lineupSnapshot
    ) throws SQLException {
        ensureLineupConfigSnapshotForRound(conn, idJornada, idLigaParticipante);
        Long idConfig = loadLineupConfigId(conn, idJornada, idLigaParticipante);
        if (idConfig == null) {
            throw new SQLException("No se pudo recuperar la cabecera de alineación para guardar huecos");
        }

        FormationSpec formationSpec = resolveFormationSpecForRound(conn, idLigaParticipante, idJornada);
        List<LeagueEmptySlotResponse> emptySlots = buildEmptySlots(lineupSnapshot, formationSpec);
        replaceLineupEmptySlots(conn, idConfig, emptySlots);
    }

    private Long loadLineupConfigId(Connection conn, Long idJornada, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT id
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
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private List<LeagueEmptySlotResponse> loadEmptySlotsForRound(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante
    ) throws SQLException {
        String sql = """
                SELECT h.posicion, h.orden, h.penalizacion
                FROM alineacion_jornada_huecos h
                INNER JOIN alineacion_jornada_participante_config c
                  ON c.id = h.id_alineacion_jornada_participante_config
                WHERE c.id_jornada = ?
                  AND c.id_liga_participante = ?
                ORDER BY
                    CASE h.posicion
                        WHEN 'POR' THEN 1
                        WHEN 'DEF' THEN 2
                        WHEN 'MED' THEN 3
                        WHEN 'DEL' THEN 4
                        ELSE 5
                    END,
                    h.orden ASC
                """;
        List<LeagueEmptySlotResponse> slots = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    slots.add(new LeagueEmptySlotResponse(
                            rs.getString("posicion"),
                            rs.getInt("orden"),
                            rs.getInt("penalizacion"),
                            true
                    ));
                }
            }
        }
        return slots;
    }

    private List<LeagueEmptySlotResponse> buildEmptySlots(LineupSnapshot snapshot, FormationSpec formationSpec) {
        List<LeagueEmptySlotResponse> slots = new ArrayList<>();
        addEmptySlotsForPosition(slots, "POR", countByPosition(snapshot.titulares(), "POR"), formationSpec.goalkeepers());
        addEmptySlotsForPosition(slots, "DEF", countByPosition(snapshot.titulares(), "DEF"), formationSpec.defenders());
        addEmptySlotsForPosition(slots, "MED", countByPosition(snapshot.titulares(), "MED"), formationSpec.midfielders());
        addEmptySlotsForPosition(slots, "DEL", countByPosition(snapshot.titulares(), "DEL"), formationSpec.forwards());
        return slots;
    }

    private int countEmptySlots(LineupSnapshot snapshot, FormationSpec formationSpec) {
        return buildEmptySlots(snapshot, formationSpec).size();
    }

    private LineupSnapshot optimizeSnapshotWithCurrentSquad(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            LineupSnapshot currentSnapshot,
            FormationSpec formationSpec
    ) throws SQLException {
        if (currentSnapshot == null) {
            return null;
        }

        LineupSnapshot rebuilt = buildDefaultSnapshot(conn, idLiga, idUsuario, formationSpec);
        int currentMissing = countEmptySlots(currentSnapshot, formationSpec);
        int rebuiltMissing = countEmptySlots(rebuilt, formationSpec);
        if (rebuiltMissing < currentMissing) {
            return rebuilt;
        }
        return currentSnapshot;
    }

    private boolean sameSnapshot(LineupSnapshot left, LineupSnapshot right) {
        if (left == right) {
            return true;
        }
        if (left == null || right == null) {
            return false;
        }
        return Objects.equals(left.idCapitan(), right.idCapitan())
                && left.titulares().equals(right.titulares())
                && left.reservas().equals(right.reservas());
    }

    private void addEmptySlotsForPosition(
            List<LeagueEmptySlotResponse> slots,
            String posicion,
            int current,
            int required
    ) {
        for (int orden = current + 1; orden <= required; orden++) {
            slots.add(new LeagueEmptySlotResponse(posicion, orden, -5, true));
        }
    }

    private void replaceLineupEmptySlots(
            Connection conn,
            Long idAlineacionJornadaParticipanteConfig,
            List<LeagueEmptySlotResponse> emptySlots
    ) throws SQLException {
        String deleteSql = """
                DELETE FROM alineacion_jornada_huecos
                WHERE id_alineacion_jornada_participante_config = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
            ps.setLong(1, idAlineacionJornadaParticipanteConfig);
            ps.executeUpdate();
        }

        if (emptySlots.isEmpty()) {
            return;
        }

        String insertSql = """
                INSERT INTO alineacion_jornada_huecos (
                  id_alineacion_jornada_participante_config,
                  posicion,
                  orden,
                  penalizacion
                ) VALUES (?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            for (LeagueEmptySlotResponse slot : emptySlots) {
                ps.setLong(1, idAlineacionJornadaParticipanteConfig);
                ps.setString(2, slot.posicion());
                ps.setInt(3, slot.orden());
                ps.setInt(4, slot.penalizacion());
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private LineupConfigSnapshot buildLineupConfigSnapshot(Connection conn, Long idLigaParticipante) throws SQLException {
        LeagueAssignedCoachResponse coach = loadAssignedCoachByParticipant(conn, idLigaParticipante);
        if (coach == null || !Boolean.TRUE.equals(coach.activo())) {
            return LineupConfigSnapshot.defaultSnapshot();
        }

        FormationSpec formationSpec = FormationSpec.parseOrDefault(coach.formacion());
        Integer idEquipo = coach.idEquipo();
        Integer bonusPuntos = coach.bonusPuntos() == null ? 0 : coach.bonusPuntos();

        return new LineupConfigSnapshot(
                coach.idEntrenador(),
                true,
                coach.entrenadorNombre(),
                coach.entrenadorPila(),
                coach.foto(),
                idEquipo == null ? null : Long.valueOf(idEquipo),
                coach.equipoNombre(),
                formationSpec.value(),
                bonusPuntos
        );
    }

    private void upsertLineupConfigSnapshot(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante,
            LineupConfigSnapshot snapshot
    ) throws SQLException {
        String sql = """
                INSERT INTO alineacion_jornada_participante_config (
                  id_jornada,
                  id_liga_participante,
                  id_entrenador_usado,
                  entrenador_activo,
                  entrenador_nombre_snapshot,
                  entrenador_pila_snapshot,
                  entrenador_foto_snapshot,
                  entrenador_id_equipo_snapshot,
                  entrenador_equipo_nombre_snapshot,
                  formacion_efectiva,
                  bonus_entrenador_por_jugador
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                  id_entrenador_usado = VALUES(id_entrenador_usado),
                  entrenador_activo = VALUES(entrenador_activo),
                  entrenador_nombre_snapshot = VALUES(entrenador_nombre_snapshot),
                  entrenador_pila_snapshot = VALUES(entrenador_pila_snapshot),
                  entrenador_foto_snapshot = VALUES(entrenador_foto_snapshot),
                  entrenador_id_equipo_snapshot = VALUES(entrenador_id_equipo_snapshot),
                  entrenador_equipo_nombre_snapshot = VALUES(entrenador_equipo_nombre_snapshot),
                  formacion_efectiva = VALUES(formacion_efectiva),
                  bonus_entrenador_por_jugador = VALUES(bonus_entrenador_por_jugador),
                  actualizado_en = CURRENT_TIMESTAMP
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLigaParticipante);

            if (snapshot.idEntrenadorUsado() == null) {
                ps.setNull(3, Types.BIGINT);
            } else {
                ps.setLong(3, snapshot.idEntrenadorUsado());
            }

            ps.setBoolean(4, snapshot.entrenadorActivo());
            ps.setString(5, snapshot.entrenadorNombreSnapshot());
            ps.setString(6, snapshot.entrenadorPilaSnapshot());
            ps.setString(7, snapshot.entrenadorFotoSnapshot());

            if (snapshot.entrenadorIdEquipoSnapshot() == null) {
                ps.setNull(8, Types.INTEGER);
            } else {
                ps.setLong(8, snapshot.entrenadorIdEquipoSnapshot());
            }

            ps.setString(9, snapshot.entrenadorEquipoNombreSnapshot());
            ps.setString(10, snapshot.formacionEfectiva());
            ps.setInt(11, snapshot.bonusEntrenadorPorJugador());
            ps.executeUpdate();
        }
    }

    /**
     * Última alineación guardada (mayor número de jornada) para consulta en solo lectura (otro participante).
     * Igual criterio que el detalle de {@code lineup-history/{idJornada}}: si hay snapshot persistido,
     * se considera disponible aunque haya huecos o la formación no cumpla validación estricta de edición.
     */
    public record LatestSavedLineupForPeer(
            boolean disponible,
            long idJornadaOrigen,
            long numeroJornadaOrigen,
            long idCapitan,
            List<Long> titularesIds,
            List<Long> reservasIds,
            List<LeagueEmptySlotResponse> emptySlots
    ) {
    }

    public record ParticipantRoundFrozenLineup(
            Long idLigaParticipante,
            Long idUsuario,
            Long idJornada,
            Integer numeroJornada,
            Long idCapitan,
            List<Long> titularesIds,
            List<Long> reservasIds,
            List<LeagueEmptySlotResponse> emptySlots
    ) {
    }

    public LatestSavedLineupForPeer resolveLatestSavedLineupForPeer(Long idLiga, Long idLigaParticipante) throws SQLException {
        if (idLiga == null || idLigaParticipante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            String verify = """
                    SELECT 1
                    FROM liga_participantes lp
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
                }
            }

            String latest = """
                    SELECT ajp.id_jornada, j.numero
                    FROM alineacion_jornada_participante ajp
                    INNER JOIN jornadas j ON j.id = ajp.id_jornada
                    WHERE ajp.id_liga_participante = ?
                      AND j.id_liga = ?
                    ORDER BY j.numero DESC, j.id DESC
                    LIMIT 1
                    """;

            Long idJornada = null;
            int numero = 0;
            try (PreparedStatement ps = conn.prepareStatement(latest)) {
                ps.setLong(1, idLigaParticipante);
                ps.setLong(2, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return new LatestSavedLineupForPeer(false, 0, 0, 0, List.of(), List.of(), List.of());
                    }
                    idJornada = rs.getLong("id_jornada");
                    numero = rs.getInt("numero");
                }
            }

            LineupSnapshot snap = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
            if (snap == null) {
                return new LatestSavedLineupForPeer(false, idJornada != null ? idJornada : 0, numero, 0, List.of(), List.of(), List.of());
            }

            long cap = snap.idCapitan() != null ? snap.idCapitan() : 0L;
            List<LeagueEmptySlotResponse> emptySlots = loadEmptySlotsForRound(conn, idJornada, idLigaParticipante);
            return new LatestSavedLineupForPeer(
                    true,
                    idJornada,
                    numero,
                    cap,
                    extractIds(snap.titulares()),
                    extractIds(snap.reservas()),
                    emptySlots
            );
        }
    }

    public void saveEditableLineup(Long idLiga, SaveLeagueLineupRequest request) throws SQLException {
        if (idLiga == null || request == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        if (request.idUsuario() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        if (request.titulares() == null) {
            throw new IllegalArgumentException("Debes enviar titulares");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, request.idUsuario());

                Long idLigaParticipante = findLeagueParticipantId(conn, idLiga, request.idUsuario());
                if (idLigaParticipante == null) {
                    throw new IllegalArgumentException("Participante no encontrado en la liga");
                }
                FormationSpec formationSpec = resolveEffectiveFormationSpec(conn, idLigaParticipante);

                EditableRoundData editableRound = findEditableRound(conn, idLiga);
                if (editableRound == null) {
                    throw new IllegalArgumentException("No hay jornadas editables disponibles");
                }

                if (isRoundKickoffStarted(conn, editableRound.idJornada())) {
                    throw new IllegalArgumentException("La jornada editable actual ya ha comenzado");
                }

                List<Long> titularesReq = new ArrayList<>(request.titulares());
                List<Long> reservasReq = request.reservas() == null ? new ArrayList<>() : new ArrayList<>(request.reservas());

                LineupSnapshot snapshot;
                try {
                    snapshot = validateIncomingLineup(
                            conn,
                            idLiga,
                            request.idUsuario(),
                            titularesReq,
                            reservasReq,
                            request.idCapitan(),
                            formationSpec
                    );
                } catch (IllegalArgumentException ex) {
                    if (!isFormationLayoutValidationError(ex.getMessage())) {
                        throw ex;
                    }
                    AdjustedLineupIds adjusted = rebalanceTitularesForFormationCaps(
                            conn,
                            idLiga,
                            request.idUsuario(),
                            titularesReq,
                            reservasReq,
                            formationSpec
                    );
                    snapshot = validateIncomingLineup(
                            conn,
                            idLiga,
                            request.idUsuario(),
                            adjusted.titulares(),
                            adjusted.reservas(),
                            request.idCapitan(),
                            formationSpec
                    );
                }

                persistLineup(conn, idLigaParticipante, editableRound.idJornada(), snapshot);

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }

                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error guardando alineación fantasy: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /**
     * Congela explícitamente la alineación fantasy de TODOS los participantes
     * para una jornada concreta.
     *
     * <p>Una vez la jornada ha arrancado (primer partido en juego/finalizado o ya llegó el primer
     * {@code inicio_en}) y el participante ya tiene filas en {@code alineacion_jornada_participante},
     * esa plantilla no se vuelve a borrar ni a sustituir (fichajes/ventas no reescriben el fantasy
     * de esa jornada).</p>
     *
     * <p>Si aún no hay filas y la jornada ya ha arrancado, se aplica la prioridad habitual:</p>
     * <ol>
     *   <li>alineación exacta ya guardada para esa jornada si es válida</li>
     *   <li>última alineación válida de jornadas anteriores</li>
     *   <li>default con la formación efectiva del participante</li>
     * </ol>
     */
    public void ensureFrozenLineupsForRound(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        if (conn == null || idLiga == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        Integer numeroJornada = findRoundNumber(conn, idLiga, idJornada);
        if (numeroJornada == null) {
            throw new IllegalArgumentException("Jornada no encontrada");
        }

        List<ParticipantRow> participants = loadLeagueParticipants(conn, idLiga);

        for (ParticipantRow participant : participants) {
            ensureFrozenLineupForParticipant(
                    conn,
                    idLiga,
                    idJornada,
                    numeroJornada,
                    participant.idLigaParticipante(),
                    participant.idUsuario()
            );
        }
    }

    public void ensureDefaultLineupForNextEditableRound(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
    if (conn == null || idLiga == null || idUsuario == null) {
        return;
    }

    Long idLigaParticipante = findLeagueParticipantId(conn, idLiga, idUsuario);
    if (idLigaParticipante == null) {
        return;
    }

    EditableRoundData editableRound = findEditableRound(conn, idLiga);
    if (editableRound == null) {
        return;
    }

    FormationSpec formationSpec = resolveEffectiveFormationSpec(conn, idLigaParticipante);
    LineupSnapshot exact = loadExactSavedLineupForRound(conn, idLigaParticipante, editableRound.idJornada());
    if (exact != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, exact, formationSpec)) {
        LineupSnapshot optimizedExact = optimizeSnapshotWithCurrentSquad(conn, idLiga, idUsuario, exact, formationSpec);
        if (optimizedExact != exact) {
            persistLineup(conn, idLigaParticipante, editableRound.idJornada(), optimizedExact);
        } else {
            syncLineupArtifactsForRound(conn, editableRound.idJornada(), idLigaParticipante, exact);
        }
        return;
    }

    LineupSnapshot snapshot = loadLastReusableLineupBeforeRound(
            conn,
            idLiga,
            idLigaParticipante,
            editableRound.numero()
    );

    if (snapshot == null || !isSnapshotUsableForUser(conn, idLiga, idUsuario, snapshot, formationSpec)) {
        snapshot = buildDefaultSnapshot(conn, idLiga, idUsuario, formationSpec);
    }

    snapshot = optimizeSnapshotWithCurrentSquad(conn, idLiga, idUsuario, snapshot, formationSpec);

    persistLineup(conn, idLigaParticipante, editableRound.idJornada(), snapshot);
    }

    public void recalculateParticipantPoints(Connection conn, Long idLiga) throws SQLException {
        if (conn == null || idLiga == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        List<ParticipantRow> participants = loadLeagueParticipants(conn, idLiga);
        List<RoundEstadoRow> rounds = loadAllLeagueRoundsWithEstado(conn, idLiga);

        for (ParticipantRow participant : participants) {
            Set<Long> savedRoundIds = loadSavedRoundIdsForParticipant(conn, participant.idLigaParticipante());
            int totalPoints = 0;

            for (RoundEstadoRow round : rounds) {
                totalPoints += fantasyPointsForRoundHistoryAligned(
                        conn,
                        idLiga,
                        participant.idLigaParticipante(),
                        round.idJornada(),
                        round.estado(),
                        savedRoundIds.contains(round.idJornada())
                );
            }

            updateParticipantTotalPoints(conn, participant.idLigaParticipante(), totalPoints);
        }
    }

    /**
     * Puntos fantasy de una jornada alineados con {@code GET .../lineup-history}: 0 si {@code PENDIENTE}
     * o no hay filas en {@code alineacion_jornada_participante} para esa jornada; en otro caso igual que
     * {@link #resolveParticipantRoundFantasyBreakdown}{@code .puntosTotales()}.
     */
    public int fantasyPointsForRoundHistoryAligned(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idJornada,
            String estadoJornada,
            boolean alineacionGuardadaParaEstaJornada
    ) throws SQLException {
        if (conn == null || idLiga == null || idLigaParticipante == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        if ("PENDIENTE".equals(estadoJornada) || !alineacionGuardadaParaEstaJornada) {
            return 0;
        }
        return resolveParticipantRoundFantasyBreakdown(conn, idLiga, idLigaParticipante, idJornada).puntosTotales();
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

    private List<RoundEstadoRow> loadAllLeagueRoundsWithEstado(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id, numero, estado
                FROM jornadas
                WHERE id_liga = ?
                ORDER BY numero ASC
                """;

        List<RoundEstadoRow> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new RoundEstadoRow(
                            rs.getLong("id"),
                            rs.getInt("numero"),
                            rs.getString("estado")
                    ));
                }
            }
        }

        return rows;
    }

    private void ensureFrozenLineupForParticipant(
        Connection conn,
        Long idLiga,
        Long idJornada,
        Integer numeroJornada,
        Long idLigaParticipante,
        Long idUsuario
) throws SQLException {
    boolean jornadaYaArrancada = isRoundKickoffStarted(conn, idJornada);
    if (jornadaYaArrancada && countFrozenLineupRows(conn, idLigaParticipante, idJornada) > 0) {
        // Plantilla ya congelada para esta jornada: no revalidar propiedad ni regenerar tras fichajes.
        return;
    }

    FormationSpec formationSpec = resolveEffectiveFormationSpec(conn, idLigaParticipante);
    LineupSnapshot exact = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
    if (exact != null && isSnapshotUsableForUser(conn, idLiga, idUsuario, exact, formationSpec)) {
        syncLineupArtifactsForRound(conn, idJornada, idLigaParticipante, exact);
        return;
    }

    if (exact != null) {
        deleteLineupForRound(conn, idLigaParticipante, idJornada);
    }

    LineupSnapshot snapshot = loadLastReusableLineupBeforeRound(
            conn,
            idLiga,
            idLigaParticipante,
            numeroJornada
    );

    if (snapshot == null || !isSnapshotUsableForUser(conn, idLiga, idUsuario, snapshot, formationSpec)) {
        snapshot = buildDefaultSnapshot(conn, idLiga, idUsuario, formationSpec);
    }

    persistLineup(conn, idLigaParticipante, idJornada, snapshot);
    }

    /**
     * Estado del partido de la jornada por {@code equipos.id} (coincide con {@code liga_jugadores.id_equipo}
     * y con {@code partidos_jornada.id_liga_equipo_*}).
     */
    private Map<Long, String> loadMatchEstadoPorEquipoCatalogoForJornada(Connection conn, Long idJornada)
            throws SQLException {
        String sql = """
                SELECT le_loc.id_equipo AS cat_loc,
                       le_vis.id_equipo AS cat_vis,
                       pj.estado
                FROM partidos_jornada pj
                INNER JOIN liga_equipos le_loc ON le_loc.id = pj.id_liga_equipo_local
                INNER JOIN liga_equipos le_vis ON le_vis.id = pj.id_liga_equipo_visitante
                WHERE pj.id_jornada = ?
                """;
        Map<Long, String> estadoPorCatalogEquipo = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long catLoc = rs.getLong("cat_loc");
                    long catVis = rs.getLong("cat_vis");
                    String estado = rs.getString("estado");
                    estadoPorCatalogEquipo.put(catLoc, estado);
                    estadoPorCatalogEquipo.put(catVis, estado);
                }
            }
        }
        return estadoPorCatalogEquipo;
    }

    /**
     * Fantasy del 11 efectivo. Las únicas piezas candidatas a sustituir a un titular sin minutos son los
     * jugadores en {@link LineupSnapshot#reservas()}, cargados de {@code alineacion_jornada_participante}
     * (como mucho {@link #MAX_RESERVES_TOTAL}); no se mira la plantilla completa ni jugadores no guardados al cerrar la jornada.
     * El suplente solo cuenta si también disputó minutos ({@code minutos_jugados > 0}) en esa jornada.
     */
    private FantasyPlayersComputation computeFantasyPointsFromSnapshotDetailed(
            Connection conn,
            Long idJornada,
            LineupSnapshot snapshot,
            Map<Long, Long> equipoPorLigaJugador,
            Map<Long, String> estadoPartidoPorEquipoCatalogo
    ) throws SQLException {
        Map<Long, PlayerRoundStat> statsByLeaguePlayerId = loadRoundStatsByPlayer(conn, idJornada, snapshot);
        Map<String, LineupEntry> reserveByPosition = new HashMap<>();
        Set<String> reserveConsumedForPosition = new HashSet<>();

        for (LineupEntry reserve : snapshot.reservas()) {
            reserveByPosition.putIfAbsent(reserve.posicion(), reserve);
        }

        int total = 0;
        Set<Long> titularesDescartados = new HashSet<>();
        Set<Long> banquilloSuplencia = new HashSet<>();

        List<LineupEntry> startersOrdered = new ArrayList<>(snapshot.titulares());
        startersOrdered.sort(
                Comparator
                        .comparingInt((LineupEntry e) -> positionSortKey(e.posicion()))
                        .thenComparingLong(LineupEntry::idLigaJugador)
        );

        for (LineupEntry starter : startersOrdered) {
            PlayerRoundStat starterStat = statsByLeaguePlayerId.get(starter.idLigaJugador());
            int starterMinutes = starterStat == null ? 0 : starterStat.minutosJugados();
            int starterPoints = starterStat == null ? 0 : starterStat.puntos();

            if (starterMinutes > 0) {
                int pts = starterPoints;
                if (Objects.equals(snapshot.idCapitan(), starter.idLigaJugador())) {
                    pts *= 2;
                }
                total += pts;
                continue;
            }

            Long catalogEquipo = equipoPorLigaJugador.get(starter.idLigaJugador());
            String estadoPartido = catalogEquipo == null ? null : estadoPartidoPorEquipoCatalogo.get(catalogEquipo);
            boolean partidoEquipoFinalizado = "FINALIZADO".equals(estadoPartido);

            LineupEntry reserve = reserveByPosition.get(starter.posicion());
            if (partidoEquipoFinalizado
                    && reserve != null
                    && !reserveConsumedForPosition.contains(starter.posicion())) {
                reserveConsumedForPosition.add(starter.posicion());
                PlayerRoundStat reserveStat = statsByLeaguePlayerId.get(reserve.idLigaJugador());
                int reserveMinutes = reserveStat == null ? 0 : reserveStat.minutosJugados();
                if (reserveMinutes > 0) {
                    int reservePoints = reserveStat.puntos();
                    total += reservePoints;
                    titularesDescartados.add(starter.idLigaJugador());
                    banquilloSuplencia.add(reserve.idLigaJugador());
                } else {
                    int pts = starterPoints;
                    if (Objects.equals(snapshot.idCapitan(), starter.idLigaJugador())) {
                        pts *= 2;
                    }
                    total += pts;
                }
            } else {
                int pts = starterPoints;
                if (Objects.equals(snapshot.idCapitan(), starter.idLigaJugador())) {
                    pts *= 2;
                }
                total += pts;
            }
        }

        return new FantasyPlayersComputation(total, Set.copyOf(titularesDescartados), Set.copyOf(banquilloSuplencia));
    }

    private int computeFantasyPointsFromSnapshot(
            Connection conn,
            Long idJornada,
            LineupSnapshot snapshot
    ) throws SQLException {
        List<Long> ids = new ArrayList<>();
        ids.addAll(extractIds(snapshot.titulares()));
        ids.addAll(extractIds(snapshot.reservas()));
        if (ids.isEmpty()) {
            return 0;
        }
        Map<Long, Long> equipoPorLigaJugador = loadCatalogEquipoIdByLigaJugadorIds(conn, ids);
        Map<Long, String> estadoPorEquipo = loadMatchEstadoPorEquipoCatalogoForJornada(conn, idJornada);
        return computeFantasyPointsFromSnapshotDetailed(
                conn,
                idJornada,
                snapshot,
                equipoPorLigaJugador,
                estadoPorEquipo
        ).puntosJugadores();
    }

    private Map<Long, PlayerRoundStat> loadRoundStatsByPlayer(Connection conn, Long idJornada, LineupSnapshot snapshot) throws SQLException {
        List<Long> ids = new ArrayList<>();
        ids.addAll(extractIds(snapshot.titulares()));
        ids.addAll(extractIds(snapshot.reservas()));

        if (ids.isEmpty()) {
            return Map.of();
        }
        Map<Long, String> posiciones = new HashMap<>();
        for (LineupEntry e : snapshot.titulares()) {
            posiciones.put(e.idLigaJugador(), e.posicion());
        }
        for (LineupEntry e : snapshot.reservas()) {
            posiciones.putIfAbsent(e.idLigaJugador(), e.posicion());
        }
        return loadMaskedRoundStatsForPlayerIds(conn, idJornada, ids, posiciones);
    }

    public Map<Long, String> loadPosicionesByLigaJugadorIds(Connection conn, List<Long> ids) throws SQLException {
        Map<Long, String> out = new HashMap<>();
        if (ids.isEmpty()) {
            return out;
        }
        StringBuilder sql = new StringBuilder("""
                SELECT lj.id, j.posicion
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 1, ids.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.put(rs.getLong("id"), rs.getString("posicion"));
                }
            }
        }
        return out;
    }

    /**
     * Stats de jornada para fantasy con anti-spoiler si el partido del club está {@code EN_JUEGO}
     * (misma regla temporal que la cronología).
     */
    private Map<Long, PlayerRoundStat> loadMaskedRoundStatsForPlayerIds(
            Connection conn,
            Long idJornada,
            List<Long> ids,
            Map<Long, String> posicionPorLigaJugador
    ) throws SQLException {
        StringBuilder sql = new StringBuilder("""
                SELECT id_liga_jugador,
                       puntos,
                       minutos_jugados,
                       goles,
                       asistencias,
                       regates,
                       balones_recuperados,
                       paradas,
                       tarjetas_amarillas,
                       tarjetas_rojas,
                       goles_encajados,
                       lesionado_en_partido,
                       nota_periodico
                FROM jugadores_puntos_jornada
                WHERE id_jornada = ?
                  AND id_liga_jugador IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, LeagueMatchLiveFantasyMask.JpPersistentStats> jpRows = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idJornada);
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 2, ids.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id_liga_jugador");
                    jpRows.put(
                            idLj,
                            new LeagueMatchLiveFantasyMask.JpPersistentStats(
                                    rs.getInt("puntos"),
                                    rs.getInt("minutos_jugados"),
                                    rs.getInt("goles"),
                                    rs.getInt("asistencias"),
                                    rs.getInt("regates"),
                                    rs.getInt("balones_recuperados"),
                                    rs.getInt("paradas"),
                                    rs.getInt("tarjetas_amarillas"),
                                    rs.getInt("tarjetas_rojas"),
                                    rs.getInt("goles_encajados"),
                                    rs.getInt("lesionado_en_partido") > 0,
                                    rs.getObject("nota_periodico", Integer.class)
                            )
                    );
                }
            }
        }

        Map<Long, Long> catalogByLj = LeagueMatchLiveFantasyMask.catalogByLigaJugadorIds(conn, ids);
        Map<Long, LeagueMatchLiveFantasyMask.MatchAnchor> anchors =
                LeagueMatchLiveFantasyMask.anchorsByCatalogEquipo(conn, idJornada);
        Map<Long, List<LeagueMatchEventResponse>> eventsCache = new HashMap<>();
        Map<Long, Long> ljCatScratch = new HashMap<>(catalogByLj);

        Map<Long, PlayerRoundStat> stats = new HashMap<>();
        for (Long idLj : ids) {
            LeagueMatchLiveFantasyMask.JpPersistentStats jp = jpRows.get(idLj);
            if (jp == null) {
                continue;
            }
            Long cat = catalogByLj.get(idLj);
            String pos = posicionPorLigaJugador.get(idLj);
            if (pos == null) {
                pos = "DEL";
            }
            LeagueMatchLiveFantasyMask.MatchAnchor anchor = cat == null ? null : anchors.get(cat);
            if (anchor != null && "EN_JUEGO".equals(anchor.estado())) {
                LeagueMatchLiveFantasyMask.MaskedRoundFantasy m =
                        LeagueMatchLiveFantasyMask.maskJpForLiveMatch(
                                conn,
                                idLj,
                                pos,
                                cat,
                                anchor,
                                jp,
                                eventsCache,
                                ljCatScratch
                        );
                stats.put(idLj, new PlayerRoundStat(idLj, m.puntosFantasy(), m.minutosVisibles(), m.puntosDesglose()));
            } else {
                FantasyPointsBreakdownCalculator.Breakdown desglose = LeagueDataService.fantasyBreakdownLikeSimulation(
                        pos,
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
                stats.put(idLj, new PlayerRoundStat(idLj, desglose.total(), jp.minutosJugados(), desglose));
            }
        }
        return stats;
    }

    private void updateParticipantTotalPoints(Connection conn, Long idLigaParticipante, int totalPoints) throws SQLException {
        String sql = """
                UPDATE liga_participantes
                SET puntos_totales = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, totalPoints);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private List<ParticipantRow> loadLeagueParticipants(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT id, id_usuario
                FROM liga_participantes
                WHERE id_liga = ?
                ORDER BY id ASC
                """;

        List<ParticipantRow> rows = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new ParticipantRow(
                            rs.getLong("id"),
                            rs.getLong("id_usuario")
                    ));
                }
            }
        }

        return rows;
    }

    public Map<Long, Integer> calculateRoundPointsByUser(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        if (conn == null || idLiga == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        String estadoJornada = loadRoundEstado(conn, idLiga, idJornada);
        if (estadoJornada == null) {
            throw new IllegalArgumentException("Jornada no encontrada");
        }

        List<ParticipantRow> participants = loadLeagueParticipants(conn, idLiga);
        Map<Long, Integer> pointsByUser = new LinkedHashMap<>();

        for (ParticipantRow participant : participants) {
            Set<Long> savedRoundIds = loadSavedRoundIdsForParticipant(conn, participant.idLigaParticipante());
            boolean tieneLineup = savedRoundIds.contains(idJornada);
            int roundPoints = fantasyPointsForRoundHistoryAligned(
                    conn,
                    idLiga,
                    participant.idLigaParticipante(),
                    idJornada,
                    estadoJornada,
                    tieneLineup
            );

            pointsByUser.put(participant.idUsuario(), roundPoints);
        }

        return pointsByUser;
    }

    public Map<Long, Integer> calculateRoundPointsByLeaguePlayer(
            Connection conn,
            Long idJornada,
            List<Long> idLigaJugadores
    ) throws SQLException {
        Map<Long, PlayerRoundStat> masked = loadMaskedRoundStats(conn, idJornada, idLigaJugadores);
        Map<Long, Integer> pointsByPlayer = new HashMap<>();
        for (Long id : idLigaJugadores) {
            PlayerRoundStat st = masked.get(id);
            pointsByPlayer.put(id, st == null ? 0 : st.puntos());
        }
        return pointsByPlayer;
    }

    public Map<Long, FantasyPointsBreakdownCalculator.Breakdown> calculateRoundBreakdownByLeaguePlayer(
            Connection conn,
            Long idJornada,
            List<Long> idLigaJugadores
    ) throws SQLException {
        Map<Long, PlayerRoundStat> masked = loadMaskedRoundStats(conn, idJornada, idLigaJugadores);
        Map<Long, FantasyPointsBreakdownCalculator.Breakdown> out = new HashMap<>();
        for (Long id : idLigaJugadores) {
            PlayerRoundStat st = masked.get(id);
            if (st != null && st.puntosDesglose() != null) {
                out.put(id, st.puntosDesglose());
            }
        }
        return out;
    }

    private Map<Long, PlayerRoundStat> loadMaskedRoundStats(
            Connection conn,
            Long idJornada,
            List<Long> idLigaJugadores
    ) throws SQLException {
        if (idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return Map.of();
        }
        Map<Long, String> posiciones = loadPosicionesByLigaJugadorIds(conn, idLigaJugadores);
        return loadMaskedRoundStatsForPlayerIds(conn, idJornada, idLigaJugadores, posiciones);
    }

    public ParticipantRoundFrozenLineup getParticipantFrozenLineupForRound(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idJornada
    ) throws SQLException {
        if (conn == null || idLiga == null || idLigaParticipante == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        Long idUsuario = findParticipantUserId(conn, idLiga, idLigaParticipante);
        if (idUsuario == null) {
            throw new IllegalArgumentException("Participante no encontrado en la liga");
        }

        Integer numeroJornada = findRoundNumber(conn, idLiga, idJornada);
        if (numeroJornada == null) {
            throw new IllegalArgumentException("Jornada no encontrada");
        }

        LineupSnapshot snapshot = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
        if (snapshot == null) {
            return null;
        }

        List<LineupEntry> titulares = new ArrayList<>(snapshot.titulares());
        titulares.sort(
                Comparator
                        .comparingInt((LineupEntry e) -> positionSortKey(e.posicion()))
                        .thenComparingLong(LineupEntry::idLigaJugador)
        );

        List<LineupEntry> reservas = new ArrayList<>(snapshot.reservas());
        reservas.sort(
                Comparator
                        .comparingInt((LineupEntry e) -> positionSortKey(e.posicion()))
                        .thenComparingLong(LineupEntry::idLigaJugador)
        );
        FormationSpec formationSpecForHoles = resolveFormationSpecForRound(conn, idLigaParticipante, idJornada);
        List<LeagueEmptySlotResponse> emptySlots = buildEmptySlots(snapshot, formationSpecForHoles);

        return new ParticipantRoundFrozenLineup(
                idLigaParticipante,
                idUsuario,
                idJornada,
                numeroJornada,
                snapshot.idCapitan(),
                extractIds(titulares),
                extractIds(reservas),
                emptySlots
        );
    }

    /**
     * Desglose de fantasy de la jornada (jugadores con sustitución solo si el partido del club está
     * {@code FINALIZADO} en esa jornada) + penalización por huecos de titular + entrenador.
     *
     * <p>Si la snapshot está incompleta (menos titulares de los exigidos por la formación), igualmente
     * se suman los puntos de los jugadores presentes (con bonus de capitán solo si el capitán es titular
     * con reglas habituales) y se aplican {@code -5} por cada hueco obligatorio inferido
     * (formación vs titulares por posición), sin recolocar jugadores.</p>
     */
    public ParticipantRoundFantasyBreakdown resolveParticipantRoundFantasyBreakdown(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idJornada
    ) throws SQLException {
        if (conn == null || idLiga == null || idLigaParticipante == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        FormationSpec formationSpec = resolveFormationSpecForRound(conn, idLigaParticipante, idJornada);
        LineupSnapshot snapshot = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
        if (snapshot == null) {
            return new ParticipantRoundFantasyBreakdown(0, 0, 0, 0, Set.of(), Set.of());
        }

        List<LeagueEmptySlotResponse> huecosTitularesInferidos = buildEmptySlots(snapshot, formationSpec);
        int penalizacionHuecos = 0;
        for (LeagueEmptySlotResponse h : huecosTitularesInferidos) {
            penalizacionHuecos += h.penalizacion() == null ? 0 : h.penalizacion();
        }

        List<Long> ids = new ArrayList<>();
        ids.addAll(extractIds(snapshot.titulares()));
        ids.addAll(extractIds(snapshot.reservas()));

        FantasyPlayersComputation fp;
        if (ids.isEmpty()) {
            fp = new FantasyPlayersComputation(0, Set.of(), Set.of());
        } else {
            Map<Long, Long> equipoPorLigaJugador = loadCatalogEquipoIdByLigaJugadorIds(conn, ids);
            Map<Long, String> estadoPorEquipo = loadMatchEstadoPorEquipoCatalogoForJornada(conn, idJornada);
            fp = computeFantasyPointsFromSnapshotDetailed(
                    conn,
                    idJornada,
                    snapshot,
                    equipoPorLigaJugador,
                    estadoPorEquipo
            );
        }

        int puntosEntrenador = resolveCoachRoundContributionFromAjpc(conn, idLiga, idJornada, idLigaParticipante);
        int puntosTotales = fp.puntosJugadores() + penalizacionHuecos + puntosEntrenador;
        return new ParticipantRoundFantasyBreakdown(
                puntosTotales,
                fp.puntosJugadores(),
                penalizacionHuecos,
                puntosEntrenador,
                Set.copyOf(fp.titularesDescartados()),
                Set.copyOf(fp.banquilloPorSuplencia())
        );
    }

    /**
     * Puntos totales de fantasy de la jornada: jugadores (alineación efectiva + capitán) + penalización por huecos
     * + {@link #resolveCoachRoundContributionFromAjpc aporte del entrenador} cuando aplica.
     */
    public Integer calculateParticipantRoundFantasyPointsExact(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuario,
            Long idJornada
    ) throws SQLException {
        if (conn == null || idLiga == null || idLigaParticipante == null || idUsuario == null || idJornada == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        return resolveParticipantRoundFantasyBreakdown(conn, idLiga, idLigaParticipante, idJornada).puntosTotales();
    }

    private String loadRoundEstado(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT estado
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
                return rs.getString("estado");
            }
        }
    }

    private AjpcCoachRow loadAjpcCoachRow(Connection conn, Long idJornada, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT id_entrenador_usado,
                       entrenador_activo,
                       entrenador_id_equipo_snapshot,
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
                    return null;
                }
                return new AjpcCoachRow(
                        rs.getObject("id_entrenador_usado", Long.class),
                        rs.getObject("entrenador_activo", Boolean.class),
                        rs.getObject("entrenador_id_equipo_snapshot", Integer.class),
                        rs.getObject("bonus_entrenador_por_jugador", Integer.class)
                );
            }
        }
    }

    /**
     * Aporte del entrenador para la jornada usando el mismo cálculo que {@link #calculateCoachRoundContributionPoints}
     * (sin sumar {@code bonus_puntos} directamente; solo el resultado ya ponderado). Sin snapshot de entrenador en AJPC:
     * 0.
     */
    private int resolveCoachRoundContributionFromAjpc(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long idLigaParticipante
    ) throws SQLException {
        if (conn == null || idLiga == null || idJornada == null || idLigaParticipante == null) {
            return 0;
        }
        String estadoJornada = loadRoundEstado(conn, idLiga, idJornada);
        if (estadoJornada == null) {
            return 0;
        }
        AjpcCoachRow ajpc = loadAjpcCoachRow(conn, idJornada, idLigaParticipante);
        if (ajpc == null || ajpc.idEntrenadorUsado() == null) {
            return 0;
        }
        int bonus = ajpc.bonusEntrenadorPorJugador() == null ? 0 : ajpc.bonusEntrenadorPorJugador();
        return calculateCoachRoundContributionPoints(
                conn,
                idJornada,
                idLigaParticipante,
                ajpc.entrenadorIdEquipoSnapshot(),
                bonus,
                Boolean.TRUE.equals(ajpc.entrenadorActivo()),
                estadoJornada
        );
    }

    /**
     * Puntos del míster en una jornada (no persistidos). Solo con jornada {@code EN_CURSO} o {@code FINALIZADA};
     * si está {@code PENDIENTE}, devuelve 0.
     * Regla: {@code bonus_por_jugador} × número de jugadores de la alineación efectiva (misma sustitución por
     * posición que {@link #computeFantasyPointsFromSnapshot}) cuyo {@code id_equipo} coincide con el del entrenador
     * y {@code minutos_jugados >= 1}. No usa puntos fantasy ni multiplicador de capitán. El valor devuelto es el que
     * debe sumarse al total de jornada vía {@link #resolveCoachRoundContributionFromAjpc} /
     * {@link #calculateParticipantRoundFantasyPointsExact}.
     */
    public int calculateCoachRoundContributionPoints(
            Connection conn,
            Long idJornada,
            Long idLigaParticipante,
            Integer idEquipoEntrenadorCatalogo,
            int bonusPorUnidadFantasy,
            boolean entrenadorActivoSnapshot,
            String estadoJornada
    ) throws SQLException {
        if (conn == null || idJornada == null || idLigaParticipante == null) {
            return 0;
        }
        if (!"EN_CURSO".equals(estadoJornada) && !"FINALIZADA".equals(estadoJornada)) {
            return 0;
        }
        if (!entrenadorActivoSnapshot || idEquipoEntrenadorCatalogo == null || bonusPorUnidadFantasy <= 0) {
            return 0;
        }
        long coachEquipo = idEquipoEntrenadorCatalogo.longValue();

        LineupSnapshot snapshot = loadExactSavedLineupForRound(conn, idLigaParticipante, idJornada);
        if (snapshot == null) {
            return 0;
        }

        int jugadoresClubConMinutos = countEffectiveCoachClubPlayersWithPlayedMinutesInSnapshot(
                conn,
                idJornada,
                snapshot,
                coachEquipo
        );
        return bonusPorUnidadFantasy * jugadoresClubConMinutos;
    }

    /**
     * Cuenta jugadores del club del entrenador en la alineación efectiva con al menos 1 minuto disputado.
     */
    private int countEffectiveCoachClubPlayersWithPlayedMinutesInSnapshot(
            Connection conn,
            Long idJornada,
            LineupSnapshot snapshot,
            long idEquipoEntrenadorCatalogo
    ) throws SQLException {
        Map<Long, PlayerRoundStat> statsByLeaguePlayerId = loadRoundStatsByPlayer(conn, idJornada, snapshot);
        List<Long> allIds = new ArrayList<>();
        allIds.addAll(extractIds(snapshot.titulares()));
        allIds.addAll(extractIds(snapshot.reservas()));
        if (allIds.isEmpty()) {
            return 0;
        }
        Map<Long, Long> equipoPorLigaJugador = loadCatalogEquipoIdByLigaJugadorIds(conn, allIds);
        Map<Long, String> estadoPorEquipo = loadMatchEstadoPorEquipoCatalogoForJornada(conn, idJornada);

        Map<String, LineupEntry> reserveByPosition = new HashMap<>();
        Set<String> reserveConsumedForPosition = new HashSet<>();
        for (LineupEntry reserve : snapshot.reservas()) {
            reserveByPosition.putIfAbsent(reserve.posicion(), reserve);
        }

        int count = 0;
        List<LineupEntry> startersOrdered = new ArrayList<>(snapshot.titulares());
        startersOrdered.sort(
                Comparator
                        .comparingInt((LineupEntry e) -> positionSortKey(e.posicion()))
                        .thenComparingLong(LineupEntry::idLigaJugador)
        );

        for (LineupEntry starter : startersOrdered) {
            PlayerRoundStat starterStat = statsByLeaguePlayerId.get(starter.idLigaJugador());
            int starterMinutes = starterStat == null ? 0 : starterStat.minutosJugados();

            if (starterMinutes >= 1) {
                Long eq = equipoPorLigaJugador.get(starter.idLigaJugador());
                if (eq != null && eq.longValue() == idEquipoEntrenadorCatalogo) {
                    count++;
                }
                continue;
            }

            Long catalogEquipo = equipoPorLigaJugador.get(starter.idLigaJugador());
            String estadoPartido = catalogEquipo == null ? null : estadoPorEquipo.get(catalogEquipo);
            boolean partidoEquipoFinalizado = "FINALIZADO".equals(estadoPartido);

            LineupEntry reserve = reserveByPosition.get(starter.posicion());
            if (partidoEquipoFinalizado
                    && reserve != null
                    && !reserveConsumedForPosition.contains(starter.posicion())) {
                reserveConsumedForPosition.add(starter.posicion());
                PlayerRoundStat reserveStat = statsByLeaguePlayerId.get(reserve.idLigaJugador());
                int reserveMinutes = reserveStat == null ? 0 : reserveStat.minutosJugados();
                if (reserveMinutes >= 1) {
                    Long eq = equipoPorLigaJugador.get(reserve.idLigaJugador());
                    if (eq != null && eq.longValue() == idEquipoEntrenadorCatalogo) {
                        count++;
                    }
                }
            }
        }

        return count;
    }

    private Map<Long, Long> loadCatalogEquipoIdByLigaJugadorIds(Connection conn, List<Long> idLigaJugadores) throws SQLException {
        if (idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT id, id_equipo
                FROM liga_jugadores
                WHERE id IN (
                """);
        appendInClause(sql, idLigaJugadores.size());
        sql.append(")");

        Map<Long, Long> out = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < idLigaJugadores.size(); i++) {
                ps.setLong(i + 1, idLigaJugadores.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id");
                    long idEq = rs.getLong("id_equipo");
                    out.put(idLj, idEq);
                }
            }
        }
        return out;
    }

    private LineupSnapshot validateIncomingLineup(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            List<Long> titularesIds,
            List<Long> reservasIds,
            Long idCapitan,
            FormationSpec formationSpec
    ) throws SQLException {
        if (titularesIds.size() > STARTERS_TOTAL) {
            throw new IllegalArgumentException("No puedes enviar más de 11 titulares");
        }

        if (reservasIds.size() > MAX_RESERVES_TOTAL) {
            throw new IllegalArgumentException("Puedes enviar entre 0 y 4 reservas");
        }

        Set<Long> uniqueIds = new HashSet<>();
        uniqueIds.addAll(titularesIds);
        uniqueIds.addAll(reservasIds);

        if (uniqueIds.size() != titularesIds.size() + reservasIds.size()) {
            throw new IllegalArgumentException("No puede haber jugadores repetidos en la alineación");
        }

        if (idCapitan != null && !titularesIds.contains(idCapitan)) {
            throw new IllegalArgumentException("El capitán debe estar entre los titulares");
        }

        Map<Long, OwnedPlayerRef> ownedPlayers = loadOwnedPlayersByIds(conn, idLiga, idUsuario, uniqueIds);
        if (ownedPlayers.size() != uniqueIds.size()) {
            throw new IllegalArgumentException("Alguno de los jugadores enviados no pertenece al usuario en esta liga");
        }

        List<LineupEntry> titulares = new ArrayList<>();
        List<LineupEntry> reservas = new ArrayList<>();

        for (Long idLigaJugador : titularesIds) {
            OwnedPlayerRef ref = ownedPlayers.get(idLigaJugador);
            titulares.add(new LineupEntry(ref.idLigaJugador(), ref.posicion(), ref.valor()));
        }

        for (Long idLigaJugador : reservasIds) {
            OwnedPlayerRef ref = ownedPlayers.get(idLigaJugador);
            reservas.add(new LineupEntry(ref.idLigaJugador(), ref.posicion(), ref.valor()));
        }

        if (countByPosition(titulares, "POR") > formationSpec.goalkeepers()
                || countByPosition(titulares, "DEF") > formationSpec.defenders()
                || countByPosition(titulares, "MED") > formationSpec.midfielders()
                || countByPosition(titulares, "DEL") > formationSpec.forwards()) {
            throw new IllegalArgumentException(
                    "La alineación enviada supera el máximo permitido por posición para la formación "
                            + formationSpec.value()
            );
        }

        Long resolvedCaptainId = idCapitan;
        if (resolvedCaptainId == null || !extractIds(titulares).contains(resolvedCaptainId)) {
            resolvedCaptainId = resolveDefaultCaptainId(titulares);
        }

        LineupSnapshot snapshot = new LineupSnapshot(titulares, reservas, resolvedCaptainId);
        if (!isStructurallyValid(snapshot, formationSpec)) {
            throw new IllegalArgumentException(
                    "La alineación enviada no es válida para la formación "
                            + formationSpec.value()
            );
        }

        return snapshot;
    }

    private record AdjustedLineupIds(List<Long> titulares, List<Long> reservas) {}

    private static boolean isFormationLayoutValidationError(String message) {
        if (message == null || message.isBlank()) {
            return false;
        }
        return message.contains("formación")
                || message.contains("máximo permitido por posición")
                || message.contains("no es válida para la formación");
    }

    /**
     * Cuando el cliente aún envía la XI de la formación anterior (p. ej. tras activar otro entrenador
     * con PATCH), recoloca excedentes por posición al banquillo respetando el orden de titulares.
     */
    private AdjustedLineupIds rebalanceTitularesForFormationCaps(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            List<Long> titularesIds,
            List<Long> reservasIds,
            FormationSpec formationSpec
    ) throws SQLException {
        Set<Long> uniqueIds = new HashSet<>();
        uniqueIds.addAll(titularesIds);
        uniqueIds.addAll(reservasIds);
        Map<Long, OwnedPlayerRef> ownedPlayers = loadOwnedPlayersByIds(conn, idLiga, idUsuario, uniqueIds);
        if (ownedPlayers.size() != uniqueIds.size()) {
            throw new IllegalArgumentException("Alguno de los jugadores enviados no pertenece al usuario en esta liga");
        }

        List<LineupEntry> xi = new ArrayList<>();
        for (Long id : titularesIds) {
            OwnedPlayerRef ref = ownedPlayers.get(id);
            xi.add(new LineupEntry(ref.idLigaJugador(), ref.posicion(), ref.valor()));
        }

        ArrayDeque<Long> overflow = new ArrayDeque<>();

        while (xi.size() > STARTERS_TOTAL) {
            LineupEntry removed = xi.remove(xi.size() - 1);
            overflow.addFirst(removed.idLigaJugador());
        }

        while (true) {
            if (countByPosition(xi, "POR") <= formationSpec.goalkeepers()
                    && countByPosition(xi, "DEF") <= formationSpec.defenders()
                    && countByPosition(xi, "MED") <= formationSpec.midfielders()
                    && countByPosition(xi, "DEL") <= formationSpec.forwards()) {
                break;
            }
            boolean removedOne = false;
            for (int i = xi.size() - 1; i >= 0; i--) {
                LineupEntry e = xi.get(i);
                if (isPositionOverCap(xi, e.posicion(), formationSpec)) {
                    xi.remove(i);
                    overflow.addFirst(e.idLigaJugador());
                    removedOne = true;
                    break;
                }
            }
            if (!removedOne) {
                break;
            }
        }

        LinkedHashSet<Long> bench = new LinkedHashSet<>();
        for (Long id : overflow) {
            bench.add(id);
        }
        for (Long id : reservasIds) {
            bench.add(id);
        }
        for (LineupEntry e : xi) {
            bench.remove(e.idLigaJugador());
        }

        List<Long> newRes = new ArrayList<>();
        for (Long id : bench) {
            newRes.add(id);
            if (newRes.size() >= MAX_RESERVES_TOTAL) {
                break;
            }
        }

        List<Long> newTit = new ArrayList<>();
        for (LineupEntry e : xi) {
            newTit.add(e.idLigaJugador());
        }
        return new AdjustedLineupIds(newTit, newRes);
    }

    private boolean isPositionOverCap(List<LineupEntry> xi, String posicion, FormationSpec formationSpec) {
        int cap = switch (posicion) {
            case "POR" -> formationSpec.goalkeepers();
            case "DEF" -> formationSpec.defenders();
            case "MED" -> formationSpec.midfielders();
            case "DEL" -> formationSpec.forwards();
            default -> 0;
        };
        return countByPosition(xi, posicion) > cap;
    }

    private Map<Long, OwnedPlayerRef> loadOwnedPlayersByIds(Connection conn, Long idLiga, Long idUsuario, Set<Long> ids) throws SQLException {
        if (ids.isEmpty()) {
            return Map.of();
        }

        StringBuilder sql = new StringBuilder("""
                SELECT lj.id AS id_liga_jugador,
                       j.posicion,
                       lj.valor
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                  AND lj.id IN (
                """);
        appendInClause(sql, ids.size());
        sql.append(")");

        Map<Long, OwnedPlayerRef> rows = new LinkedHashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int index = 1;
            ps.setLong(index++, idLiga);
            ps.setLong(index++, idUsuario);
            for (Long id : ids) {
                ps.setLong(index++, id);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.put(
                            rs.getLong("id_liga_jugador"),
                            new OwnedPlayerRef(
                                    rs.getLong("id_liga_jugador"),
                                    rs.getString("posicion"),
                                    rs.getLong("valor")
                            )
                    );
                }
            }
        }

        return rows;
    }

    private void persistLineup(Connection conn, Long idLigaParticipante, Long idJornada, LineupSnapshot snapshot) throws SQLException {
        deleteLineupForRound(conn, idLigaParticipante, idJornada);

        String insertSql = """
                INSERT INTO alineacion_jornada_participante (
                    id_jornada,
                    id_liga_participante,
                    id_liga_jugador,
                    titular,
                    reserva,
                    capitan
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            for (LineupEntry starter : snapshot.titulares()) {
                ps.setLong(1, idJornada);
                ps.setLong(2, idLigaParticipante);
                ps.setLong(3, starter.idLigaJugador());
                ps.setBoolean(4, true);
                ps.setBoolean(5, false);
                ps.setBoolean(6, Objects.equals(snapshot.idCapitan(), starter.idLigaJugador()));
                ps.addBatch();
            }

            for (LineupEntry reserve : snapshot.reservas()) {
                ps.setLong(1, idJornada);
                ps.setLong(2, idLigaParticipante);
                ps.setLong(3, reserve.idLigaJugador());
                ps.setBoolean(4, false);
                ps.setBoolean(5, true);
                ps.setBoolean(6, false);
                ps.addBatch();
            }

            ps.executeBatch();
        }

        syncLineupArtifactsForRound(conn, idJornada, idLigaParticipante, snapshot);
    }

    private void deleteLineupForRound(Connection conn, Long idLigaParticipante, Long idJornada) throws SQLException {
        String deleteSql = """
                DELETE FROM alineacion_jornada_participante
                WHERE id_jornada = ?
                  AND id_liga_participante = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private LineupSnapshot loadExactSavedLineupForRound(
            Connection conn,
            Long idLigaParticipante,
            Long idJornada
    ) throws SQLException {
        String sql = """
                SELECT ajp.id_liga_jugador,
                       ajp.titular,
                       ajp.reserva,
                       ajp.capitan,
                       j.posicion,
                       lj.valor
                FROM alineacion_jornada_participante ajp
                INNER JOIN liga_jugadores lj ON lj.id = ajp.id_liga_jugador
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE ajp.id_liga_participante = ?
                  AND ajp.id_jornada = ?
                ORDER BY ajp.titular DESC, ajp.reserva DESC, ajp.id ASC
                """;

        List<LineupEntry> titulares = new ArrayList<>();
        List<LineupEntry> reservas = new ArrayList<>();
        Long idCapitan = null;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idJornada);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LineupEntry entry = new LineupEntry(
                            rs.getLong("id_liga_jugador"),
                            rs.getString("posicion"),
                            rs.getLong("valor")
                    );

                    if (rs.getBoolean("titular")) {
                        titulares.add(entry);
                    }
                    if (rs.getBoolean("reserva")) {
                        reservas.add(entry);
                    }
                    if (rs.getBoolean("capitan")) {
                        idCapitan = entry.idLigaJugador();
                    }
                }
            }
        }

        if (titulares.isEmpty() && reservas.isEmpty() && idCapitan == null) {
            return null;
        }

        return new LineupSnapshot(titulares, reservas, idCapitan);
    }

    private LineupSnapshot loadLastReusableLineupBeforeRound(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Integer numeroObjetivo
    ) throws SQLException {
        Long savedRoundId = findLatestSavedRoundIdBeforeNumber(conn, idLiga, idLigaParticipante, numeroObjetivo);
        if (savedRoundId == null) {
            return null;
        }

        return loadExactSavedLineupForRound(conn, idLigaParticipante, savedRoundId);
    }

    private LineupSnapshot loadLatestSavedLineupUpToRoundLegacy(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Integer numeroObjetivo
    ) throws SQLException {
        Long savedRoundId = findLatestSavedRoundIdUpToNumber(conn, idLiga, idLigaParticipante, numeroObjetivo);
        if (savedRoundId == null) {
            return null;
        }

        return loadExactSavedLineupForRound(conn, idLigaParticipante, savedRoundId);
    }

    private Long findLatestSavedRoundIdBeforeNumber(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Integer numeroObjetivo
    ) throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                WHERE j.id_liga = ?
                  AND j.numero = (
                      SELECT MAX(j2.numero)
                      FROM alineacion_jornada_participante ajp
                      INNER JOIN jornadas j2 ON j2.id = ajp.id_jornada
                      WHERE ajp.id_liga_participante = ?
                        AND j2.id_liga = ?
                        AND j2.numero < ?
                  )
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaParticipante);
            ps.setLong(3, idLiga);
            ps.setInt(4, numeroObjetivo);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private Long findLatestSavedRoundIdUpToNumber(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Integer numeroObjetivo
    ) throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                WHERE j.id_liga = ?
                  AND j.numero = (
                      SELECT MAX(j2.numero)
                      FROM alineacion_jornada_participante ajp
                      INNER JOIN jornadas j2 ON j2.id = ajp.id_jornada
                      WHERE ajp.id_liga_participante = ?
                        AND j2.id_liga = ?
                        AND j2.numero <= ?
                  )
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaParticipante);
            ps.setLong(3, idLiga);
            ps.setInt(4, numeroObjetivo);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    private LineupSnapshot buildDefaultSnapshot(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            FormationSpec formationSpec
    ) throws SQLException {
        List<OwnedPlayerRef> squad = loadOwnedSquad(conn, idLiga, idUsuario);
        List<OwnedPlayerRef> available = new ArrayList<>(squad);

        List<LineupEntry> titulares = new ArrayList<>();
        titulares.addAll(pickPlayersByPosition(available, "POR", formationSpec.goalkeepers()));
        titulares.addAll(pickPlayersByPosition(available, "DEF", formationSpec.defenders()));
        titulares.addAll(pickPlayersByPosition(available, "MED", formationSpec.midfielders()));
        titulares.addAll(pickPlayersByPosition(available, "DEL", formationSpec.forwards()));

        List<LineupEntry> reservas = new ArrayList<>();
        for (int i = 0; i < Math.min(MAX_RESERVES_TOTAL, available.size()); i++) {
            OwnedPlayerRef reserve = available.get(i);
            reservas.add(new LineupEntry(reserve.idLigaJugador(), reserve.posicion(), reserve.valor()));
        }

        LineupSnapshot snapshot = new LineupSnapshot(
                titulares,
                reservas,
                resolveDefaultCaptainId(titulares)
        );

        return snapshot;
    }

    private Long resolveDefaultCaptainId(List<LineupEntry> titulares) {
        Long idCapitan = null;
        long bestValue = Long.MIN_VALUE;

        for (LineupEntry titular : titulares) {
            if (titular.valor() > bestValue) {
                bestValue = titular.valor();
                idCapitan = titular.idLigaJugador();
            }
        }

        return idCapitan;
    }

    private List<LineupEntry> pickPlayersByPosition(List<OwnedPlayerRef> source, String posicion, int count) {
        List<LineupEntry> selected = new ArrayList<>();
        List<OwnedPlayerRef> toRemove = new ArrayList<>();

        for (OwnedPlayerRef player : source) {
            if (!posicion.equals(player.posicion())) {
                continue;
            }
            selected.add(new LineupEntry(player.idLigaJugador(), player.posicion(), player.valor()));
            toRemove.add(player);
            if (selected.size() == count) {
                break;
            }
        }

        source.removeAll(toRemove);
        return selected;
    }

    private List<OwnedPlayerRef> loadOwnedSquad(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT lj.id AS id_liga_jugador,
                       j.posicion,
                       lj.valor,
                       j.nombre
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
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

        List<OwnedPlayerRef> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    players.add(new OwnedPlayerRef(
                            rs.getLong("id_liga_jugador"),
                            rs.getString("posicion"),
                            rs.getLong("valor")
                    ));
                }
            }
        }

        return players;
    }

    private boolean isStructurallyValid(LineupSnapshot snapshot, FormationSpec formationSpec) {
        if (snapshot == null) {
            return false;
        }

        if (snapshot.titulares().size() > STARTERS_TOTAL) {
            return false;
        }

        if (snapshot.reservas().size() > MAX_RESERVES_TOTAL) {
            return false;
        }

        Set<Long> ids = new HashSet<>();
        ids.addAll(extractIds(snapshot.titulares()));
        ids.addAll(extractIds(snapshot.reservas()));

        if (ids.size() != snapshot.titulares().size() + snapshot.reservas().size()) {
            return false;
        }

        if (snapshot.idCapitan() != null && !extractIds(snapshot.titulares()).contains(snapshot.idCapitan())) {
            return false;
        }

        return countByPosition(snapshot.titulares(), "POR") <= formationSpec.goalkeepers()
                && countByPosition(snapshot.titulares(), "DEF") <= formationSpec.defenders()
                && countByPosition(snapshot.titulares(), "MED") <= formationSpec.midfielders()
                && countByPosition(snapshot.titulares(), "DEL") <= formationSpec.forwards();
    }

    private int countByPosition(List<LineupEntry> entries, String posicion) {
        int total = 0;
        for (LineupEntry entry : entries) {
            if (posicion.equals(entry.posicion())) {
                total++;
            }
        }
        return total;
    }

    private List<Long> extractIds(List<LineupEntry> entries) {
        List<Long> ids = new ArrayList<>();
        for (LineupEntry entry : entries) {
            ids.add(entry.idLigaJugador());
        }
        return ids;
    }

    private EditableRoundData findEditableRound(Connection conn, Long idLiga) throws SQLException {
    String sql = """
            SELECT j.id AS id_jornada,
                   j.numero,
                   MIN(pj.inicio_en) AS editable_hasta,
                   COALESCE(MAX(CASE
                       WHEN pj.estado IN ('EN_JUEGO', 'FINALIZADO') THEN 1
                       ELSE 0
                   END), 0) AS jornada_iniciada
            FROM jornadas j
            INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id
            WHERE j.id_liga = ?
              AND j.estado NOT IN ('EN_CURSO', 'FINALIZADA')
            GROUP BY j.id, j.numero
            HAVING jornada_iniciada = 0
               AND MIN(pj.inicio_en) > NOW()
            ORDER BY j.numero ASC
            LIMIT 1
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLiga);
        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }

            Timestamp editableHastaTs = rs.getTimestamp("editable_hasta");
            Instant editableHasta = editableHastaTs == null ? null : editableHastaTs.toInstant();

            return new EditableRoundData(
                    rs.getLong("id_jornada"),
                    rs.getInt("numero"),
                    editableHasta
            );
        }
    }
    }

    private Integer findRoundNumber(Connection conn, Long idLiga, Long idJornada) throws SQLException {
        String sql = """
                SELECT numero
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
                return rs.getInt("numero");
            }
        }
    }

    private boolean isSnapshotUsableForUser(
        Connection conn,
        Long idLiga,
        Long idUsuario,
        LineupSnapshot snapshot,
        FormationSpec formationSpec
) throws SQLException {
    if (!isStructurallyValid(snapshot, formationSpec)) {
        return false;
    }

    Set<Long> ids = new HashSet<>();
    ids.addAll(extractIds(snapshot.titulares()));
    ids.addAll(extractIds(snapshot.reservas()));

    if (ids.size() != snapshot.titulares().size() + snapshot.reservas().size()) {
        return false;
    }

    return loadOwnedPlayersByIds(conn, idLiga, idUsuario, ids).size() == ids.size();
    }

    private Long findLeagueParticipantId(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
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

    private Long findParticipantUserId(Connection conn, Long idLiga, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT id_usuario
                FROM liga_participantes
                WHERE id = ?
                  AND id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id_usuario");
            }
        }
    }

    private void ensureParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
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
                if (rs.getInt("total") <= 0) {
                    throw new IllegalArgumentException("No perteneces a esta liga");
                }
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

    private static int positionSortKey(String posicion) {
        if (posicion == null) {
            return 99;
        }
        return switch (posicion) {
            case "POR" -> 1;
            case "DEF" -> 2;
            case "MED" -> 3;
            case "DEL" -> 4;
            default -> 5;
        };
    }

    /** Verdadero si el primer partido de la jornada ya ha empezado. */
    /** Verdadero si la jornada ya ha empezado por hora o por estado real de alguno de sus partidos. */
private boolean isRoundKickoffStarted(Connection conn, Long idJornada) throws SQLException {
    String sql = """
            SELECT
                COALESCE(MAX(CASE
                    WHEN pj.estado IN ('EN_JUEGO', 'FINALIZADO') THEN 1
                    ELSE 0
                END), 0) AS jornada_iniciada,
                MIN(pj.inicio_en) AS primer_inicio
            FROM partidos_jornada pj
            WHERE pj.id_jornada = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idJornada);

        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return false;
            }

            if (rs.getInt("jornada_iniciada") > 0) {
                return true;
            }

            Timestamp ts = rs.getTimestamp("primer_inicio");
            if (ts == null) {
                return false;
            }

            return !ts.toInstant().isAfter(Instant.now());
        }
    }
    }

    private int countFrozenLineupRows(Connection conn, Long idLigaParticipante, Long idJornada) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS c
                FROM alineacion_jornada_participante
                WHERE id_liga_participante = ?
                  AND id_jornada = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return 0;
                }
                return rs.getInt("c");
            }
        }
    }

    private record EditableRoundData(Long idJornada, Integer numero, Instant editableHasta) {
    }

    private record OwnedPlayerRef(Long idLigaJugador, String posicion, Long valor) {
    }

    private record LineupEntry(Long idLigaJugador, String posicion, Long valor) {
    }

    private record LineupSnapshot(List<LineupEntry> titulares, List<LineupEntry> reservas, Long idCapitan) {
    }

    private record FantasyPlayersComputation(int puntosJugadores, Set<Long> titularesDescartados, Set<Long> banquilloPorSuplencia) {
    }

    private record PlayerRoundStat(
            Long idLigaJugador,
            Integer puntos,
            Integer minutosJugados,
            FantasyPointsBreakdownCalculator.Breakdown puntosDesglose
    ) {
    }

    private record ParticipantRow(Long idLigaParticipante, Long idUsuario) {
    }

    /** Filas mínimas de {@code alineacion_jornada_participante_config} para puntos de entrenador. */
    private record AjpcCoachRow(
            Long idEntrenadorUsado,
            Boolean entrenadorActivo,
            Integer entrenadorIdEquipoSnapshot,
            Integer bonusEntrenadorPorJugador
    ) {
    }

    private record RoundEstadoRow(Long idJornada, Integer numero, String estado) {
    }

    private record LineupConfigSnapshot(
            Long idEntrenadorUsado,
            boolean entrenadorActivo,
            String entrenadorNombreSnapshot,
            String entrenadorPilaSnapshot,
            String entrenadorFotoSnapshot,
            Long entrenadorIdEquipoSnapshot,
            String entrenadorEquipoNombreSnapshot,
            String formacionEfectiva,
            int bonusEntrenadorPorJugador
    ) {
        private static LineupConfigSnapshot defaultSnapshot() {
            return new LineupConfigSnapshot(
                    null,
                    false,
                    null,
                    null,
                    null,
                    null,
                    null,
                    DEFAULT_FORMATION,
                    0
            );
        }
    }

    private record FormationSpec(
            int goalkeepers,
            int defenders,
            int midfielders,
            int forwards
    ) {
        private static FormationSpec default433() {
            return parseOrDefault(DEFAULT_FORMATION);
        }

        private static FormationSpec parseOrDefault(String value) {
            if (value == null || value.isBlank()) {
                return new FormationSpec(1, 4, 3, 3);
            }

            String[] parts = value.trim().split("-");
            if (parts.length != 3) {
                return new FormationSpec(1, 4, 3, 3);
            }

            try {
                int def = Integer.parseInt(parts[0].trim());
                int med = Integer.parseInt(parts[1].trim());
                int del = Integer.parseInt(parts[2].trim());
                if (def < 0 || med < 0 || del < 0) {
                    return new FormationSpec(1, 4, 3, 3);
                }
                if (def + med + del != 10) {
                    return new FormationSpec(1, 4, 3, 3);
                }
                return new FormationSpec(1, def, med, del);
            } catch (NumberFormatException e) {
                return new FormationSpec(1, 4, 3, 3);
            }
        }

        private String value() {
            return defenders + "-" + midfielders + "-" + forwards;
        }
    }
}