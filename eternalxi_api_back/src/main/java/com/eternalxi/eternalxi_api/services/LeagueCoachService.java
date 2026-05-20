package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachActiveToggleRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachAssignmentResponse;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachAssignmentUpsertRequest;
import com.eternalxi.eternalxi_api.dto.league.LeagueCoachInventoryResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class LeagueCoachService {

    public LeagueCoachAssignmentResponse assignCoach(
            Long idLiga,
            Long idLigaParticipante,
            LeagueCoachAssignmentUpsertRequest request
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || request == null
                || request.idUsuarioSolicitante() == null || request.idEntrenador() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ParticipantContext participant = loadParticipantContext(conn, idLiga, idLigaParticipante);
                ensureCanManageParticipant(participant, request.idUsuarioSolicitante());

                CoachContext coach = loadCoach(conn, request.idEntrenador());
                if (!coach.activo()) {
                    throw new IllegalArgumentException("El entrenador no está activo");
                }
                if (!participant.idTemporada().equals(coach.idTemporada().longValue())) {
                    throw new IllegalArgumentException("El entrenador no pertenece a la temporada de la liga");
                }

                insertCoachIntoInventory(conn, idLigaParticipante, request.idEntrenador());
                LeagueCoachAssignmentResponse response =
                        loadAssignmentRow(conn, idLiga, idLigaParticipante, request.idEntrenador());
                if (response == null) {
                    throw new SQLException("No se pudo recuperar la fila de inventario del entrenador");
                }

                conn.commit();
                return response;
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }
                throw new SQLException("Error asignando entrenador: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /**
     * activo=false: ningún entrenador equipado (todos activo=0). Formación efectiva vuelve a 4-3-3 en capas superiores.
     * activo=true sin idEntrenador: mantiene el equipado actual si hay exactamente uno; si no hay ninguno, error (hay que elegir).
     * activo=true con idEntrenador: valida posesión, desequipa todos y equipa el elegido.
     */
    public LeagueCoachAssignmentResponse toggleCoachActive(
            Long idLiga,
            Long idLigaParticipante,
            LeagueCoachActiveToggleRequest request
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || request == null
                || request.idUsuarioSolicitante() == null || request.activo() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ParticipantContext participant = loadParticipantContext(conn, idLiga, idLigaParticipante);
                ensureCanManageParticipant(participant, request.idUsuarioSolicitante());

                if (!hasAnyCoachInInventory(conn, idLigaParticipante)) {
                    throw new IllegalArgumentException("El participante no tiene entrenadores en el inventario");
                }

                if (!Boolean.TRUE.equals(request.activo())) {
                    deactivateAllCoaches(conn, idLigaParticipante);
                    conn.commit();
                    return null;
                }

                if (request.idEntrenador() != null) {
                    if (!participantOwnsCoach(conn, idLigaParticipante, request.idEntrenador())) {
                        throw new IllegalArgumentException("El participante no tiene ese entrenador en su inventario");
                    }
                    equipCoach(conn, idLigaParticipante, request.idEntrenador());
                } else {
                    int equippedCount = countEquippedCoaches(conn, idLigaParticipante);
                    if (equippedCount == 0) {
                        throw new IllegalArgumentException(
                                "Indica idEntrenador para equipar un entrenador, o primero añade uno al inventario");
                    }
                    if (equippedCount > 1) {
                        throw new IllegalArgumentException(
                                "Hay más de un entrenador marcado como equipado; indica idEntrenador para corregirlo");
                    }
                }

                LeagueCoachAssignmentResponse equipped =
                        loadEquippedCoachAssignment(conn, idLiga, idLigaParticipante).orElse(null);
                conn.commit();
                return equipped;
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }
                throw new SQLException("Error actualizando estado del entrenador: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public Optional<LeagueCoachAssignmentResponse> getEquippedCoachAssignment(
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuarioSolicitante
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || idUsuarioSolicitante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ParticipantContext participant = loadParticipantContext(conn, idLiga, idLigaParticipante);
            ensureCanManageParticipant(participant, idUsuarioSolicitante);

            return loadEquippedCoachAssignment(conn, idLiga, idLigaParticipante);
        }
    }

    public LeagueCoachInventoryResponse listCoachInventory(
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuarioSolicitante
    ) throws SQLException {
        if (idLiga == null || idLigaParticipante == null || idUsuarioSolicitante == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ParticipantContext participant = loadParticipantContext(conn, idLiga, idLigaParticipante);
            ensureCanManageParticipant(participant, idUsuarioSolicitante);

            return new LeagueCoachInventoryResponse(loadAllAssignments(conn, idLiga, idLigaParticipante));
        }
    }

    private ParticipantContext loadParticipantContext(Connection conn, Long idLiga, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lp.id,
                       lp.id_liga,
                       lp.id_usuario,
                       l.id_administrador,
                       l.id_temporada
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                WHERE lp.id = ?
                  AND lp.id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Participante no encontrado en la liga");
                }
                return new ParticipantContext(
                        rs.getLong("id"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_usuario"),
                        rs.getLong("id_administrador"),
                        rs.getLong("id_temporada")
                );
            }
        }
    }

    private CoachContext loadCoach(Connection conn, Long idEntrenador) throws SQLException {
        String sql = """
                SELECT e.id,
                       e.nombre,
                       e.pila,
                       e.formacion,
                       e.foto,
                       e.id_equipo,
                       eq.nombre AS equipo_nombre,
                       e.id_temporada,
                       e.bonus_puntos,
                       e.activo
                FROM entrenadores e
                INNER JOIN equipos eq ON eq.id = e.id_equipo
                WHERE e.id = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEntrenador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Entrenador no encontrado");
                }
                return new CoachContext(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getString("pila"),
                        rs.getString("formacion"),
                        rs.getString("foto"),
                        rs.getInt("id_equipo"),
                        rs.getString("equipo_nombre"),
                        rs.getInt("id_temporada"),
                        rs.getInt("bonus_puntos"),
                        rs.getBoolean("activo")
                );
            }
        }
    }

    private void insertCoachIntoInventory(Connection conn, Long idLigaParticipante, Long idEntrenador) throws SQLException {
        String sql = """
                INSERT INTO liga_participante_entrenador (
                  id_liga_participante,
                  id_entrenador,
                  activo
                ) VALUES (?, ?, FALSE)
                ON DUPLICATE KEY UPDATE
                  actualizado_en = CURRENT_TIMESTAMP
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idEntrenador);
            ps.executeUpdate();
        }
    }

    private boolean hasAnyCoachInInventory(Connection conn, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT 1
                FROM liga_participante_entrenador
                WHERE id_liga_participante = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean participantOwnsCoach(Connection conn, Long idLigaParticipante, Long idEntrenador) throws SQLException {
        String sql = """
                SELECT 1
                FROM liga_participante_entrenador
                WHERE id_liga_participante = ?
                  AND id_entrenador = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idEntrenador);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private int countEquippedCoaches(Connection conn, Long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM liga_participante_entrenador
                WHERE id_liga_participante = ?
                  AND activo = TRUE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total");
            }
        }
    }

    private void deactivateAllCoaches(Connection conn, Long idLigaParticipante) throws SQLException {
        String sql = """
                UPDATE liga_participante_entrenador
                SET activo = FALSE,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE id_liga_participante = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private void equipCoach(Connection conn, Long idLigaParticipante, Long idEntrenador) throws SQLException {
        deactivateAllCoaches(conn, idLigaParticipante);

        String sql = """
                UPDATE liga_participante_entrenador
                SET activo = TRUE,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE id_liga_participante = ?
                  AND id_entrenador = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idEntrenador);
            int updated = ps.executeUpdate();
            if (updated != 1) {
                throw new IllegalArgumentException("No se pudo equipar el entrenador indicado");
            }
        }
    }

    private Optional<LeagueCoachAssignmentResponse> loadEquippedCoachAssignment(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante
    ) throws SQLException {
        String sql = """
                SELECT lpe.id_liga_participante,
                       lp.id_usuario,
                       lpe.id_entrenador,
                       lpe.activo,
                       e.nombre,
                       e.pila,
                       e.formacion,
                       e.foto,
                       e.id_equipo,
                       eq.nombre AS equipo_nombre,
                       e.bonus_puntos
                FROM liga_participante_entrenador lpe
                INNER JOIN liga_participantes lp ON lp.id = lpe.id_liga_participante
                INNER JOIN entrenadores e ON e.id = lpe.id_entrenador
                INNER JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpe.id_liga_participante = ?
                  AND lpe.activo = TRUE
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRowToResponse(idLiga, rs));
            }
        }
    }

    private LeagueCoachAssignmentResponse loadAssignmentRow(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idEntrenador
    ) throws SQLException {
        String sql = """
                SELECT lpe.id_liga_participante,
                       lp.id_usuario,
                       lpe.id_entrenador,
                       lpe.activo,
                       e.nombre,
                       e.pila,
                       e.formacion,
                       e.foto,
                       e.id_equipo,
                       eq.nombre AS equipo_nombre,
                       e.bonus_puntos
                FROM liga_participante_entrenador lpe
                INNER JOIN liga_participantes lp ON lp.id = lpe.id_liga_participante
                INNER JOIN entrenadores e ON e.id = lpe.id_entrenador
                INNER JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpe.id_liga_participante = ?
                  AND lpe.id_entrenador = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idEntrenador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return mapRowToResponse(idLiga, rs);
            }
        }
    }

    private List<LeagueCoachAssignmentResponse> loadAllAssignments(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante
    ) throws SQLException {
        String sql = """
                SELECT lpe.id_liga_participante,
                       lp.id_usuario,
                       lpe.id_entrenador,
                       lpe.activo,
                       e.nombre,
                       e.pila,
                       e.formacion,
                       e.foto,
                       e.id_equipo,
                       eq.nombre AS equipo_nombre,
                       e.bonus_puntos
                FROM liga_participante_entrenador lpe
                INNER JOIN liga_participantes lp ON lp.id = lpe.id_liga_participante
                INNER JOIN entrenadores e ON e.id = lpe.id_entrenador
                INNER JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpe.id_liga_participante = ?
                ORDER BY lpe.activo DESC, e.nombre ASC, lpe.id_entrenador ASC
                """;

        List<LeagueCoachAssignmentResponse> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRowToResponse(idLiga, rs));
                }
            }
        }
        return list;
    }

    private LeagueCoachAssignmentResponse mapRowToResponse(Long idLiga, ResultSet rs) throws SQLException {
        return new LeagueCoachAssignmentResponse(
                idLiga,
                rs.getLong("id_liga_participante"),
                rs.getLong("id_usuario"),
                rs.getLong("id_entrenador"),
                rs.getString("nombre"),
                rs.getString("pila"),
                rs.getString("formacion"),
                LeagueAssetUrls.manager(rs.getLong("id_entrenador")),
                rs.getInt("id_equipo"),
                rs.getString("equipo_nombre"),
                rs.getInt("bonus_puntos"),
                rs.getBoolean("activo")
        );
    }

    private void ensureCanManageParticipant(ParticipantContext participant, Long idUsuarioSolicitante) {
        if (!participant.idUsuario().equals(idUsuarioSolicitante)
                && !participant.idAdministradorLiga().equals(idUsuarioSolicitante)) {
            throw new IllegalArgumentException("No tienes permisos para gestionar el entrenador de este participante");
        }
    }

    private record ParticipantContext(
            Long idLigaParticipante,
            Long idLiga,
            Long idUsuario,
            Long idAdministradorLiga,
            Long idTemporada
    ) {
    }

    private record CoachContext(
            Long idEntrenador,
            String nombre,
            String pila,
            String formacion,
            String foto,
            Integer idEquipo,
            String equipoNombre,
            Integer idTemporada,
            Integer bonusPuntos,
            Boolean activo
    ) {
    }
}
