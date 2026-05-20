package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueMarketHistoryResponse;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class LeagueMarketHistoryService {

    public static final String TYPE_ADJUDICACION_MERCADO = "ADJUDICACION_MERCADO";
    public static final String TYPE_COMPRA_DIRECTA_DOBLE = "COMPRA_DIRECTA_DOBLE";
    public static final String TYPE_ACUERDO_USUARIOS = "ACUERDO_USUARIOS";
    public static final String TYPE_VENTA_MERCADO = "VENTA_MERCADO";
    private static final long MARKET_USER_ID = 1L;
    private static final String MARKET_SNAPSHOT_NAME = "Mercado";

    public List<LeagueMarketHistoryResponse> getMarketHistory(long idLiga, long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT id,
                           id_liga,
                           id_liga_jugador,
                           id_jugador,
                           id_usuario_comprador,
                           comprador_nombre_snapshot,
                           id_usuario_vendedor,
                           vendedor_nombre_snapshot,
                           tipo,
                           precio,
                           jugador_nombre_snapshot,
                           descripcion,
                           creado_en
                    FROM liga_mercado_historial
                    WHERE id_liga = ?
                    ORDER BY creado_en DESC, id DESC
                    LIMIT 100
                    """;

            List<LeagueMarketHistoryResponse> rows = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp createdAtTs = rs.getTimestamp("creado_en");
                        rows.add(new LeagueMarketHistoryResponse(
                                rs.getLong("id"),
                                rs.getLong("id_liga"),
                                rs.getLong("id_liga_jugador"),
                                getNullableLong(rs, "id_jugador"),
                                rs.getLong("id_usuario_comprador"),
                                rs.getString("comprador_nombre_snapshot"),
                                getNullableLong(rs, "id_usuario_vendedor"),
                                rs.getString("vendedor_nombre_snapshot"),
                                rs.getString("tipo"),
                                rs.getLong("precio"),
                                rs.getString("jugador_nombre_snapshot"),
                                rs.getString("descripcion"),
                                createdAtTs == null ? null : createdAtTs.toInstant()
                        ));
                    }
                }
            }

            return rows;
        }
    }

    public void recordMarketHistory(
            Connection conn,
            long idLiga,
            long idLigaJugador,
            Long idJugador,
            long idUsuarioComprador,
            Long idUsuarioVendedor,
            String tipo,
            long precio
    ) throws SQLException {
        if (conn == null) {
            throw new IllegalArgumentException("Conexión no disponible para registrar historial");
        }

        MarketHistoryContext context = loadContext(
                conn,
                idLiga,
                idLigaJugador,
                idJugador,
                idUsuarioComprador,
                idUsuarioVendedor
        );

        String descripcion = buildDescription(
                tipo,
                context.compradorNombre(),
                context.vendedorNombre(),
                context.jugadorNombre(),
                precio
        );

        String sql = """
                INSERT INTO liga_mercado_historial (
                    id_liga,
                    id_liga_jugador,
                    id_jugador,
                    id_usuario_comprador,
                    id_usuario_vendedor,
                    tipo,
                    precio,
                    comprador_nombre_snapshot,
                    vendedor_nombre_snapshot,
                    jugador_nombre_snapshot,
                    descripcion
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            if (context.idJugador() == null) {
                ps.setNull(3, java.sql.Types.BIGINT);
            } else {
                ps.setLong(3, context.idJugador());
            }
            ps.setLong(4, idUsuarioComprador);
            if (idUsuarioVendedor == null) {
                ps.setNull(5, java.sql.Types.BIGINT);
            } else {
                ps.setLong(5, idUsuarioVendedor);
            }
            ps.setString(6, tipo);
            ps.setLong(7, precio);
            ps.setString(8, context.compradorNombre());
            ps.setString(9, context.vendedorNombre());
            ps.setString(10, context.jugadorNombre());
            ps.setString(11, descripcion);
            ps.executeUpdate();
        }
    }

    private MarketHistoryContext loadContext(
            Connection conn,
            long idLiga,
            long idLigaJugador,
            Long idJugador,
            long idUsuarioComprador,
            Long idUsuarioVendedor
    ) throws SQLException {
        String sql = """
                SELECT lj.id_jugador,
                       j.nombre AS jugador_nombre,
                       j.pila AS jugador_pila,
                       uc.nickname AS comprador_nombre,
                       uv.nickname AS vendedor_nombre
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN usuarios uc ON uc.id = ?
                LEFT JOIN usuarios uv ON uv.id = ?
                WHERE lj.id = ?
                  AND lj.id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuarioComprador);
            if (idUsuarioVendedor == null) {
                ps.setNull(2, java.sql.Types.BIGINT);
            } else {
                ps.setLong(2, idUsuarioVendedor);
            }
            ps.setLong(3, idLigaJugador);
            ps.setLong(4, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("No se pudo cargar contexto para historial de mercado");
                }

                Long effectiveIdJugador = idJugador == null ? rs.getLong("id_jugador") : idJugador;
                String jugadorNombre = buildPlayerSnapshotName(
                        rs.getString("jugador_nombre"),
                        rs.getString("jugador_pila"),
                        idLigaJugador
                );
                String compradorNombre = normalizeBuyerSnapshotName(
                        rs.getString("comprador_nombre"),
                        idUsuarioComprador
                );
                String vendedorNombre = idUsuarioVendedor == null
                        ? null
                        : normalizeSellerSnapshotName(rs.getString("vendedor_nombre"), idUsuarioVendedor);

                return new MarketHistoryContext(
                        effectiveIdJugador,
                        compradorNombre,
                        vendedorNombre,
                        jugadorNombre
                );
            }
        }
    }

    private String buildDescription(
            String tipo,
            String compradorNombre,
            String vendedorNombre,
            String jugadorNombre,
            long precio
    ) {
        String precioFormateado = formatEuro(precio);
        return switch (tipo) {
            case TYPE_ADJUDICACION_MERCADO ->
                    compradorNombre + " se ha llevado del mercado a " + jugadorNombre + " por " + precioFormateado;
            case TYPE_COMPRA_DIRECTA_DOBLE ->
                    compradorNombre + " se ha llevado a " + jugadorNombre + " del mercado pagando el doble por " + precioFormateado;
            case TYPE_ACUERDO_USUARIOS ->
                    compradorNombre + " ha llegado a un acuerdo con " + vendedorNombre + " por " + jugadorNombre + " por " + precioFormateado;
            case TYPE_VENTA_MERCADO ->
                    vendedorNombre + " ha vendido a " + jugadorNombre + " al mercado por " + precioFormateado;
            default -> throw new IllegalArgumentException("Tipo de historial de mercado no soportado: " + tipo);
        };
    }

    private String formatEuro(long precio) {
        return String.format(Locale.ROOT, "%,d", precio).replace(',', '.') + " €";
    }

    private String buildPlayerSnapshotName(String nombre, String pila, long idLigaJugador) {
        if (nombre != null && !nombre.isBlank()) {
            return nombre;
        }
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        return "Jugador " + idLigaJugador;
    }

    private String normalizeBuyerSnapshotName(String value, long idUsuarioComprador) {
        if (idUsuarioComprador == MARKET_USER_ID) {
            return MARKET_SNAPSHOT_NAME;
        }
        if (value == null || value.isBlank()) {
            return "Usuario " + idUsuarioComprador;
        }
        return value;
    }

    private String normalizeSellerSnapshotName(String value, long idUsuarioVendedor) {
        if (value == null || value.isBlank()) {
            return "Usuario " + idUsuarioVendedor;
        }
        return value;
    }

    private void ensureParticipant(Connection conn, long idLiga, long idUsuario) throws SQLException {
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

    private Long getNullableLong(ResultSet rs, String columnName) throws SQLException {
        long value = rs.getLong(columnName);
        return rs.wasNull() ? null : value;
    }

    private record MarketHistoryContext(
            Long idJugador,
            String compradorNombre,
            String vendedorNombre,
            String jugadorNombre
    ) {
    }
}
