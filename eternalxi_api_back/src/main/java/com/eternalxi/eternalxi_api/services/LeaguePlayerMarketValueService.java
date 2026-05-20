package com.eternalxi.eternalxi_api.services;

import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * Valor de mercado efectivo (modificadores temporales de recompensa) y utilidades de lectura
 * asociadas (p. ej. protección activa para listados).
 */
@Service
public class LeaguePlayerMarketValueService {

    /**
     * Desactiva modificadores de valor cuya jornada de expiración ya está {@code FINALIZADA}.
     * Idempotente; conviene llamarlo al cerrar jornada y antes de calcular valores efectivos.
     */
    public void refreshExpiredValueModifiers(Connection conn, Long idLiga) throws SQLException {
        if (conn == null || idLiga == null) {
            return;
        }
        String sqlMod = """
                UPDATE liga_jugador_modificadores_valor m
                INNER JOIN jornadas j ON j.id = m.id_jornada_expiracion
                SET m.activo = FALSE
                WHERE m.id_liga = ? AND m.activo = TRUE AND j.estado = 'FINALIZADA'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sqlMod)) {
            ps.setLong(1, idLiga);
            ps.executeUpdate();
        }
    }

    /**
     * Tras {@link #refreshExpiredValueModifiers}, devuelve el mayor {@code porcentaje} activo del jugador
     * (no debería haber más de uno relevante; si hubiera varios, se usa el máximo).
     */
    public double maxActiveModifierPercent(Connection conn, Long idLiga, long idLigaJugador) throws SQLException {
        refreshExpiredValueModifiers(conn, idLiga);
        String sql = """
                SELECT MAX(porcentaje) AS mx
                FROM liga_jugador_modificadores_valor
                WHERE id_liga = ? AND id_liga_jugador = ? AND activo = TRUE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return 0d;
                }
                double v = rs.getBigDecimal("mx") == null ? 0d : rs.getBigDecimal("mx").doubleValue();
                return v > 0d ? v : 0d;
            }
        }
    }

    public Map<Long, Double> batchMaxActiveModifierPercents(Connection conn, Long idLiga, Collection<Long> idLigaJugadores)
            throws SQLException {
        if (conn == null || idLiga == null || idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return Collections.emptyMap();
        }
        refreshExpiredValueModifiers(conn, idLiga);
        StringBuilder in = new StringBuilder();
        for (Long ignored : idLigaJugadores) {
            if (!in.isEmpty()) {
                in.append(',');
            }
            in.append('?');
        }
        String sql = """
                SELECT id_liga_jugador, MAX(porcentaje) AS mx
                FROM liga_jugador_modificadores_valor
                WHERE id_liga = ? AND activo = TRUE AND id_liga_jugador IN (%s)
                GROUP BY id_liga_jugador
                """.formatted(in);
        Map<Long, Double> out = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            ps.setLong(i++, idLiga);
            for (Long idLj : idLigaJugadores) {
                ps.setLong(i++, idLj);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id_liga_jugador");
                    double v = rs.getBigDecimal("mx") == null ? 0d : rs.getBigDecimal("mx").doubleValue();
                    out.put(idLj, v > 0d ? v : 0d);
                }
            }
        }
        return out;
    }

    public long effectiveValueFromBase(long baseValor, double modifierPercent) {
        if (baseValor <= 0L) {
            return 0L;
        }
        if (modifierPercent <= 0d) {
            return baseValor;
        }
        return (long) Math.floor(baseValor * (1.0d + modifierPercent));
    }

    public long effectiveValue(Connection conn, Long idLiga, long idLigaJugador, long baseValor) throws SQLException {
        double p = maxActiveModifierPercent(conn, idLiga, idLigaJugador);
        return effectiveValueFromBase(baseValor, p);
    }

    /**
     * Protección activa coherente con la lógica de recompensas (jornada fin no finalizada o hasta fin de temporada).
     */
    public PlayerProtectionState loadProtectionState(Connection conn, long idLigaJugador) throws SQLException {
        String sql = """
                SELECT p.hasta_fin_temporada, p.id_jornada_fin, p.id_jornada_inicio,
                       (SELECT estado FROM jornadas j WHERE j.id = p.id_jornada_fin) AS est_fin
                FROM liga_jugador_protecciones p
                WHERE p.id_liga_jugador = ? AND p.activo = TRUE
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return new PlayerProtectionState(false, false, null, null, null);
                }
                boolean season = rs.getBoolean("hasta_fin_temporada");
                Long jFin = rs.getObject("id_jornada_fin", Long.class);
                Long jIni = rs.getObject("id_jornada_inicio", Long.class);
                String estFin = rs.getString("est_fin");
                boolean active = season || jFin == null || !"FINALIZADA".equals(estFin);
                if (!active) {
                    return new PlayerProtectionState(false, false, null, null, null);
                }
                return new PlayerProtectionState(true, season, jIni, jFin, estFin);
            }
        }
    }

    public Map<Long, PlayerProtectionState> batchProtectionStates(Connection conn, Collection<Long> idLigaJugadores)
            throws SQLException {
        if (idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return Collections.emptyMap();
        }
        StringBuilder in = new StringBuilder();
        for (Long ignored : idLigaJugadores) {
            if (!in.isEmpty()) {
                in.append(',');
            }
            in.append('?');
        }
        String sql = """
                SELECT p.id_liga_jugador, p.hasta_fin_temporada, p.id_jornada_fin, p.id_jornada_inicio,
                       (SELECT estado FROM jornadas j WHERE j.id = p.id_jornada_fin) AS est_fin
                FROM liga_jugador_protecciones p
                WHERE p.activo = TRUE AND p.id_liga_jugador IN (%s)
                """.formatted(in);
        Map<Long, PlayerProtectionState> out = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            for (Long idLj : idLigaJugadores) {
                ps.setLong(i++, idLj);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id_liga_jugador");
                    boolean season = rs.getBoolean("hasta_fin_temporada");
                    Long jFin = rs.getObject("id_jornada_fin", Long.class);
                    Long jIni = rs.getObject("id_jornada_inicio", Long.class);
                    String estFin = rs.getString("est_fin");
                    boolean active = season || jFin == null || !"FINALIZADA".equals(estFin);
                    if (active) {
                        out.put(idLj, new PlayerProtectionState(true, season, jIni, jFin, estFin));
                    }
                }
            }
        }
        return out;
    }

    public record PlayerProtectionState(
            boolean protegido,
            boolean proteccionHastaFinTemporada,
            Long proteccionJornadaInicio,
            Long proteccionJornadaFin,
            String estadoJornadaFin
    ) {}
}
