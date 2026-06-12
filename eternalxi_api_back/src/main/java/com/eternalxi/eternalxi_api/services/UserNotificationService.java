package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.user.UserNotificationItemResponse;
import com.eternalxi.eternalxi_api.dto.user.UserNotificationsListResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class UserNotificationService {

    private static final Logger log = LoggerFactory.getLogger(UserNotificationService.class);
    private static final int DEFAULT_LIST_LIMIT = 40;
    private static final ObjectMapper JSON = new ObjectMapper();

    private final PushNotificationService pushNotificationService;

    public UserNotificationService(PushNotificationService pushNotificationService) {
        this.pushNotificationService = pushNotificationService;
    }

    public UserNotificationsListResponse listForUser(Long idUsuario, Long idLiga, Integer limit) throws SQLException {
        if (idUsuario == null || idUsuario <= 0) {
            throw new IllegalArgumentException("Usuario no válido");
        }
        int safeLimit = limit == null || limit <= 0 ? DEFAULT_LIST_LIMIT : Math.min(limit, 100);

        try (Connection conn = DBConnection.getConnection()) {
            int unread = countUnread(conn, idUsuario, idLiga);
            List<UserNotificationItemResponse> items = loadItems(conn, idUsuario, idLiga, safeLimit);
            return new UserNotificationsListResponse(items, unread);
        }
    }

    public int countUnread(Long idUsuario, Long idLiga) throws SQLException {
        if (idUsuario == null || idUsuario <= 0) {
            return 0;
        }
        try (Connection conn = DBConnection.getConnection()) {
            return countUnread(conn, idUsuario, idLiga);
        }
    }

    public void markRead(Long idUsuario, List<Long> ids, Long idLiga, boolean marcarTodas) throws SQLException {
        if (idUsuario == null || idUsuario <= 0) {
            throw new IllegalArgumentException("Usuario no válido");
        }
        try (Connection conn = DBConnection.getConnection()) {
            if (marcarTodas) {
                String sql = idLiga == null
                        ? """
                        UPDATE usuario_notificaciones
                        SET leida = 1
                        WHERE id_usuario = ? AND leida = 0
                        """
                        : """
                        UPDATE usuario_notificaciones
                        SET leida = 1
                        WHERE id_usuario = ? AND id_liga = ? AND leida = 0
                        """;
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, idUsuario);
                    if (idLiga != null) {
                        ps.setLong(2, idLiga);
                    }
                    ps.executeUpdate();
                }
                return;
            }
            if (ids == null || ids.isEmpty()) {
                return;
            }
            List<Long> safeIds = ids.stream().filter(id -> id != null && id > 0).distinct().toList();
            if (safeIds.isEmpty()) {
                return;
            }
            String placeholders = String.join(",", safeIds.stream().map(id -> "?").toList());
            String sql = """
                    UPDATE usuario_notificaciones
                    SET leida = 1
                    WHERE id_usuario = ?
                      AND id IN (%s)
                    """.formatted(placeholders);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idUsuario);
                int idx = 2;
                for (Long id : safeIds) {
                    ps.setLong(idx++, id);
                }
                ps.executeUpdate();
            }
        }
    }

    public void notifyUser(
            Long idUsuario,
            Long idLiga,
            String tipo,
            String titulo,
            String mensaje,
            Map<String, Object> datos,
            String claveIdempotencia,
            Map<String, String> pushData
    ) {
        if (idUsuario == null || idUsuario <= 0 || tipo == null || tipo.isBlank()) {
            return;
        }
        try {
            boolean inserted = persistNotification(
                    idUsuario,
                    idLiga,
                    tipo,
                    titulo,
                    mensaje,
                    datos,
                    claveIdempotencia
            );
            if (!inserted) {
                return;
            }
            Map<String, String> data = pushData == null ? new HashMap<>() : new HashMap<>(pushData);
            data.putIfAbsent("type", tipo);
            if (idLiga != null) {
                data.putIfAbsent("idLiga", String.valueOf(idLiga));
            }
            pushNotificationService.sendToUser(idUsuario, titulo, mensaje, data);
        } catch (Exception e) {
            log.warn("No se pudo crear notificación para usuario {} tipo {}: {}", idUsuario, tipo, e.getMessage());
        }
    }

    private boolean persistNotification(
            Long idUsuario,
            Long idLiga,
            String tipo,
            String titulo,
            String mensaje,
            Map<String, Object> datos,
            String claveIdempotencia
    ) throws SQLException {
        String sql = """
                INSERT INTO usuario_notificaciones (
                    id_usuario, id_liga, tipo, titulo, mensaje, leida, datos_json, clave_idempotencia
                )
                VALUES (?, ?, ?, ?, ?, 0, ?, ?)
                """;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            if (idLiga == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, idLiga);
            }
            ps.setString(3, tipo);
            ps.setString(4, titulo == null ? "" : titulo);
            ps.setString(5, mensaje == null ? "" : mensaje);
            String json = datos == null || datos.isEmpty() ? null : JSON.writeValueAsString(datos);
            if (json == null) {
                ps.setNull(6, Types.VARCHAR);
            } else {
                ps.setString(6, json);
            }
            if (claveIdempotencia == null || claveIdempotencia.isBlank()) {
                ps.setNull(7, Types.VARCHAR);
            } else {
                ps.setString(7, claveIdempotencia);
            }
            return ps.executeUpdate() > 0;
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new SQLException("Error serializando datos de notificación", e);
        }
    }

    private int countUnread(Connection conn, Long idUsuario, Long idLiga) throws SQLException {
        String sql = idLiga == null
                ? """
                SELECT COUNT(*) AS c
                FROM usuario_notificaciones
                WHERE id_usuario = ? AND leida = 0
                """
                : """
                SELECT COUNT(*) AS c
                FROM usuario_notificaciones
                WHERE id_usuario = ? AND id_liga = ? AND leida = 0
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            if (idLiga != null) {
                ps.setLong(2, idLiga);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("c") : 0;
            }
        }
    }

    private List<UserNotificationItemResponse> loadItems(
            Connection conn,
            Long idUsuario,
            Long idLiga,
            int limit
    ) throws SQLException {
        String sql = idLiga == null
                ? """
                SELECT id, id_liga, tipo, titulo, mensaje, leida, datos_json, creada_en
                FROM usuario_notificaciones
                WHERE id_usuario = ?
                ORDER BY creada_en DESC, id DESC
                LIMIT ?
                """
                : """
                SELECT id, id_liga, tipo, titulo, mensaje, leida, datos_json, creada_en
                FROM usuario_notificaciones
                WHERE id_usuario = ? AND id_liga = ?
                ORDER BY creada_en DESC, id DESC
                LIMIT ?
                """;
        List<UserNotificationItemResponse> out = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            if (idLiga != null) {
                ps.setLong(2, idLiga);
                ps.setInt(3, limit);
            } else {
                ps.setInt(2, limit);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(mapRow(conn, rs));
                }
            }
        }
        return out;
    }

    private UserNotificationItemResponse mapRow(Connection conn, ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("creada_en");
        Instant creadaEn = ts == null ? null : ts.toInstant();
        String datosRaw = rs.getString("datos_json");
        Map<String, Object> datos = parseDatos(datosRaw);
        enrichPlayerDatos(conn, datos);
        long idLiga = rs.getLong("id_liga");
        Long idLigaObj = rs.wasNull() ? null : idLiga;
        return new UserNotificationItemResponse(
                rs.getLong("id"),
                idLigaObj,
                rs.getString("tipo"),
                rs.getString("titulo"),
                rs.getString("mensaje"),
                rs.getBoolean("leida"),
                datos,
                creadaEn
        );
    }

    /**
     * Notificaciones antiguas (p. ej. mercado nocturno) pueden tener idLigaJugador sin foto ni idJugador.
     */
    private void enrichPlayerDatos(Connection conn, Map<String, Object> datos) throws SQLException {
        if (datos == null || datos.isEmpty()) {
            return;
        }
        Long idLigaJugador = readDatosLong(datos.get("idLigaJugador"));
        if (idLigaJugador == null || idLigaJugador <= 0) {
            return;
        }
        Long idJugador = readDatosLong(datos.get("idJugador"));
        String playerPhotoUrl = readDatosString(datos.get("playerPhotoUrl"));
        boolean needsId = idJugador == null || idJugador <= 0;
        boolean needsPhoto = playerPhotoUrl == null
                || playerPhotoUrl.isBlank()
                || LeagueAssetUrls.isFilesystemOrLegacyPath(playerPhotoUrl);
        if (!needsId && !needsPhoto) {
            return;
        }
        if (!needsId) {
            datos.put("playerPhotoUrl", LeagueAssetUrls.player(idJugador));
            return;
        }
        String sql = """
                SELECT id_jugador
                FROM liga_jugadores
                WHERE id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return;
                }
                long resolvedId = rs.getLong("id_jugador");
                if (resolvedId <= 0) {
                    return;
                }
                datos.put("idJugador", resolvedId);
                datos.put("playerPhotoUrl", LeagueAssetUrls.player(resolvedId));
            }
        }
    }

    private Long readDatosLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number n) {
            return n.longValue();
        }
        try {
            return Long.parseLong(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String readDatosString(Object value) {
        if (value == null) {
            return null;
        }
        String s = value.toString().trim();
        return s.isEmpty() ? null : s;
    }

    private Map<String, Object> parseDatos(String raw) {
        if (raw == null || raw.isBlank()) {
            return Map.of();
        }
        try {
            return JSON.readValue(raw, new TypeReference<LinkedHashMap<String, Object>>() {});
        } catch (Exception e) {
            return Map.of();
        }
    }

    public Map<String, Object> datosBase(
            Long idLigaJugador,
            Long idJugador,
            String playerName,
            String playerPhotoUrl,
            Long idUsuarioActor,
            String actorName,
            String actorPhotoUrl,
            Long idOferta,
            Long precio,
            String actionTab,
            Integer actionSegment
    ) {
        Map<String, Object> datos = new HashMap<>();
        putIfPresent(datos, "idLigaJugador", idLigaJugador);
        putIfPresent(datos, "idJugador", idJugador);
        putIfPresent(datos, "playerName", playerName);
        putIfPresent(datos, "playerPhotoUrl", playerPhotoUrl);
        putIfPresent(datos, "idUsuarioActor", idUsuarioActor);
        putIfPresent(datos, "actorName", actorName);
        putIfPresent(datos, "actorPhotoUrl", actorPhotoUrl);
        putIfPresent(datos, "idOferta", idOferta);
        putIfPresent(datos, "precio", precio);
        putIfPresent(datos, "actionTab", actionTab);
        putIfPresent(datos, "actionSegment", actionSegment);
        return datos;
    }

    private void putIfPresent(Map<String, Object> map, String key, Object value) {
        if (value == null) {
            return;
        }
        if (value instanceof String s && s.isBlank()) {
            return;
        }
        map.put(key, value);
    }

    public Map<String, String> pushDataFromDatos(Map<String, Object> datos, String tipo, Long idLiga) {
        Map<String, String> data = new HashMap<>();
        data.put("type", tipo);
        if (idLiga != null) {
            data.put("idLiga", String.valueOf(idLiga));
        }
        if (datos == null) {
            return data;
        }
        for (Map.Entry<String, Object> e : datos.entrySet()) {
            if (e.getValue() != null) {
                data.put(e.getKey(), String.valueOf(e.getValue()));
            }
        }
        return data;
    }

    public String idempotencyKey(String... parts) {
        if (parts == null || parts.length == 0) {
            return null;
        }
        return String.join(":", parts);
    }
}
