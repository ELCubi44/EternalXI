package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class LeagueLineupAvailabilityNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueLineupAvailabilityNotificationService.class);

    private final UserNotificationService userNotificationService;

    public LeagueLineupAvailabilityNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    public int processLiveMatchNotifications() {
        int sent = 0;
        try (Connection conn = DBConnection.getConnection()) {
            List<LiveAvailabilityEvent> events = loadNewlyVisibleAvailabilityEvents(conn);
            Map<Long, Long> editableJornadaByLiga = new HashMap<>();
            for (LiveAvailabilityEvent event : events) {
                Long idJornadaEditable = editableJornadaByLiga.computeIfAbsent(
                        event.idLiga(),
                        idLiga -> {
                            try {
                                return findEditableJornadaId(conn, idLiga);
                            } catch (SQLException e) {
                                return null;
                            }
                        }
                );
                if (idJornadaEditable == null) {
                    continue;
                }
                sent += notifyLineupOwners(
                        conn,
                        event.idLiga(),
                        idJornadaEditable,
                        event.idPartido(),
                        event.idLigaJugador(),
                        event.idJugador(),
                        event.playerName(),
                        event.estado()
                );
            }
        } catch (Exception e) {
            log.warn("Error procesando notificaciones live de bajas en alineación: {}", e.getMessage());
        }
        return sent;
    }

    public void notifyLineupOwnersAfterFinalization(
            Connection conn,
            Long idLiga,
            Long idPartido,
            Long idLigaJugador,
            String estadoFinal
    ) {
        if (conn == null || idLiga == null || idPartido == null || idLigaJugador == null) {
            return;
        }
        if (!"LESIONADO".equals(estadoFinal) && !"SANCIONADO".equals(estadoFinal)) {
            return;
        }
        try {
            PlayerRef player = loadPlayerRef(conn, idLigaJugador);
            if (player == null) {
                return;
            }
            Long idJornadaEditable = findEditableJornadaId(conn, idLiga);
            if (idJornadaEditable == null) {
                return;
            }
            notifyLineupOwners(
                    conn,
                    idLiga,
                    idJornadaEditable,
                    idPartido,
                    idLigaJugador,
                    player.idJugador(),
                    player.playerName(),
                    estadoFinal
            );
        } catch (Exception e) {
            log.warn(
                    "No se pudieron enviar notificaciones de baja en alineación. liga={}, jugador={}: {}",
                    idLiga,
                    idLigaJugador,
                    e.getMessage()
            );
        }
    }

    private int notifyLineupOwners(
            Connection conn,
            Long idLiga,
            Long idJornadaEditable,
            Long idPartido,
            Long idLigaJugador,
            Long idJugador,
            String playerName,
            String estado
    ) throws SQLException {
        if (!"LESIONADO".equals(estado) && !"SANCIONADO".equals(estado)) {
            return 0;
        }
        List<Long> owners = loadLineupOwners(conn, idJornadaEditable, idLigaJugador);
        if (owners.isEmpty()) {
            return 0;
        }
        String tipo = "LESIONADO".equals(estado) ? "LINEUP_PLAYER_INJURED" : "LINEUP_PLAYER_SANCTIONED";
        String titulo = "LESIONADO".equals(estado)
                ? "Jugador lesionado en tu 11"
                : "Jugador sancionado en tu 11";
        String nombre = playerName == null || playerName.isBlank() ? "Un jugador de tu 11" : playerName;
        String mensaje = "LESIONADO".equals(estado)
                ? nombre + " se ha lesionado. Entra a cambiar tu alineación."
                : nombre + " ha sido sancionado. Entra a cambiar tu alineación.";
        String playerPhoto = LeagueAssetUrls.player(idJugador);
        Map<String, Object> datos = userNotificationService.datosBase(
                idLigaJugador,
                idJugador,
                nombre,
                playerPhoto,
                null,
                null,
                null,
                null,
                null,
                "squad",
                1
        );
        int sent = 0;
        for (Long idUsuario : owners) {
            String key = userNotificationService.idempotencyKey(
                    tipo,
                    String.valueOf(idLiga),
                    String.valueOf(idJornadaEditable),
                    String.valueOf(idLigaJugador),
                    String.valueOf(idUsuario),
                    idPartido == null ? "live" : String.valueOf(idPartido)
            );
            userNotificationService.notifyUser(
                    idUsuario,
                    idLiga,
                    tipo,
                    titulo,
                    mensaje,
                    datos,
                    key,
                    userNotificationService.pushDataFromDatos(datos, tipo, idLiga)
            );
            sent++;
        }
        return sent;
    }

    private List<LiveAvailabilityEvent> loadNewlyVisibleAvailabilityEvents(Connection conn) throws SQLException {
        String sql = """
                SELECT jo.id_liga,
                       pe.id_liga_jugador,
                       lj.id_jugador,
                       COALESCE(NULLIF(j.pila, ''), j.nombre) AS nombre_jugador,
                       pe.estado_final,
                       pj.id AS id_partido
                FROM partido_efectos_jugador pe
                INNER JOIN partidos_jornada pj ON pj.id = pe.id_partido_jornada
                INNER JOIN jornadas jo ON jo.id = pj.id_jornada
                INNER JOIN liga_jugadores lj ON lj.id = pe.id_liga_jugador AND lj.id_liga = jo.id_liga
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE pj.estado = 'EN_JUEGO'
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
        List<LiveAvailabilityEvent> out = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                out.add(new LiveAvailabilityEvent(
                        rs.getLong("id_liga"),
                        rs.getLong("id_partido"),
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_jugador"),
                        rs.getString("nombre_jugador"),
                        rs.getString("estado_final")
                ));
            }
        }
        return out;
    }

    private List<Long> loadLineupOwners(Connection conn, Long idJornada, Long idLigaJugador) throws SQLException {
        String sql = """
                SELECT DISTINCT lp.id_usuario
                FROM alineacion_jornada_participante ajp
                INNER JOIN liga_participantes lp ON lp.id = ajp.id_liga_participante
                WHERE ajp.id_jornada = ?
                  AND ajp.id_liga_jugador = ?
                  AND ajp.titular = 1
                """;
        List<Long> out = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJornada);
            ps.setLong(2, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(rs.getLong("id_usuario"));
                }
            }
        }
        return out;
    }

    private Long findEditableJornadaId(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT j.id
                FROM jornadas j
                INNER JOIN partidos_jornada pj ON pj.id_jornada = j.id
                WHERE j.id_liga = ?
                  AND j.estado NOT IN ('EN_CURSO', 'FINALIZADA')
                GROUP BY j.id, j.numero
                HAVING COALESCE(MAX(CASE
                           WHEN pj.estado IN ('EN_JUEGO', 'FINALIZADO') THEN 1
                           ELSE 0
                       END), 0) = 0
                   AND MIN(pj.inicio_en) > NOW()
                ORDER BY j.numero ASC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    private PlayerRef loadPlayerRef(Connection conn, Long idLigaJugador) throws SQLException {
        String sql = """
                SELECT lj.id_jugador,
                       COALESCE(NULLIF(j.pila, ''), j.nombre) AS nombre_jugador
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new PlayerRef(rs.getLong("id_jugador"), rs.getString("nombre_jugador"));
            }
        }
    }

    private record LiveAvailabilityEvent(
            Long idLiga,
            Long idPartido,
            Long idLigaJugador,
            Long idJugador,
            String playerName,
            String estado
    ) {
    }

    private record PlayerRef(Long idJugador, String playerName) {
    }
}
