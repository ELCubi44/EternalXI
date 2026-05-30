package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.NightMarketBidRequest;
import com.eternalxi.eternalxi_api.dto.league.NightMarketItemResponse;
import com.eternalxi.eternalxi_api.dto.league.NightMarketResponse;
import org.springframework.stereotype.Service;
import com.eternalxi.eternalxi_api.dto.league.LeagueInstantBuyResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class NightMarketService {

    
    private static final long MARKET_USER_ID = 1L;
    private static final int ITEMS_PER_DAY = 8;
    private static final Logger log = LoggerFactory.getLogger(NightMarketService.class);

private final NightMarketNotificationService nightMarketNotificationService;
private final LeagueMarketHistoryService leagueMarketHistoryService;
private final AccountProgressService accountProgressService;

public NightMarketService(
        NightMarketNotificationService nightMarketNotificationService,
        LeagueMarketHistoryService leagueMarketHistoryService,
        AccountProgressService accountProgressService
) {
    this.nightMarketNotificationService = nightMarketNotificationService;
    this.leagueMarketHistoryService = leagueMarketHistoryService;
    this.accountProgressService = accountProgressService;
}

    public NightMarketResponse getNightMarket(Long idLiga, Long idUsuario) throws SQLException {
    if (idLiga == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        ensureParticipant(conn, idLiga, idUsuario);

        ensureTodayMarketExists(conn, idLiga);

        LocalDate today = loadCurrentDbDate(conn);
        long saldoDisponible = loadParticipantMoney(conn, idLiga, idUsuario);
        long saldoRetenido = loadReservedMoney(conn, idLiga, idUsuario, today);
        List<NightMarketItemResponse> items = loadNightMarketItems(conn, idLiga, idUsuario, today);

        return new NightMarketResponse(
                idLiga,
                idUsuario,
                today,
                saldoDisponible,
                saldoRetenido,
                items.size(),
                items
        );
    }
}

    public LeagueInstantBuyResponse buyPlayerNow(Long idLiga, Long idLigaJugador, Long idUsuario) throws SQLException {
    if (idLiga == null || idLigaJugador == null || idUsuario == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);

        try {
            ensureParticipant(conn, idLiga, idUsuario);

            MarketOwnedPlayerRow player = lockMarketOwnedPlayer(conn, idLiga, idLigaJugador);
            if (player == null) {
                throw new IllegalArgumentException("El jugador no está disponible en el mercado");
            }

            LocalDate today = loadCurrentDbDate(conn);
            if (isPlayerInTodayMarket(conn, idLiga, idLigaJugador, today)) {
                throw new IllegalArgumentException("No se puede comprar ahora porque este jugador está en el mercado de hoy");
            }

            long cantidadCompra = player.valorActual() * 2L;
            long saldoActual = lockParticipantMoney(conn, idLiga, idUsuario);

            if (saldoActual < cantidadCompra) {
                throw new IllegalArgumentException("No tienes saldo suficiente para comprar a este jugador");
            }

            int updated = movePlayerFromMarketToUser(conn, idLigaJugador, idLiga, idUsuario);
            if (updated <= 0) {
                throw new IllegalArgumentException("El jugador ya no está disponible en el mercado");
            }

            addMoneyToParticipant(conn, idLiga, idUsuario, -cantidadCompra);
            leagueMarketHistoryService.recordMarketHistory(
                    conn,
                    idLiga,
                    idLigaJugador,
                    null,
                    idUsuario,
                    null,
                    LeagueMarketHistoryService.TYPE_COMPRA_DIRECTA_DOBLE,
                    cantidadCompra
            );

            long nuevoSaldo = saldoActual - cantidadCompra;

            conn.commit();

            return new LeagueInstantBuyResponse(
                    idLiga,
                    idLigaJugador,
                    idUsuario,
                    player.valorActual(),
                    cantidadCompra,
                    nuevoSaldo
            );
        } catch (Exception e) {
            conn.rollback();

            if (e instanceof IllegalArgumentException iae) {
                throw iae;
            }
            if (e instanceof SQLException sqle) {
                throw sqle;
            }

            throw new SQLException("Error comprando jugador del mercado: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }
}

    private MarketOwnedPlayerRow lockMarketOwnedPlayer(Connection conn, Long idLiga, Long idLigaJugador) throws SQLException {
    String sql = """
            SELECT lj.id,
                   lj.id_liga,
                   lj.id_usuario_dueno,
                   lj.valor
            FROM liga_jugadores lj
            WHERE lj.id = ?
              AND lj.id_liga = ?
            FOR UPDATE
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLigaJugador);
        ps.setLong(2, idLiga);

        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }

            long idUsuarioDueno = rs.getLong("id_usuario_dueno");
            if (idUsuarioDueno != MARKET_USER_ID) {
                return null;
            }

            return new MarketOwnedPlayerRow(
                    rs.getLong("id"),
                    rs.getLong("id_liga"),
                    idUsuarioDueno,
                    rs.getLong("valor")
            );
        }
    }
}

    public void upsertBid(Long idLiga, Long idMercadoDiario, NightMarketBidRequest request) throws SQLException {
        if (idLiga == null || idMercadoDiario == null || request == null
                || request.idUsuario() == null || request.cantidad() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        if (request.cantidad() <= 0) {
            throw new IllegalArgumentException("La puja debe ser mayor que 0");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, request.idUsuario());

                LocalDate today = loadCurrentDbDate(conn);
                MarketRow marketRow = lockMarketRow(conn, idLiga, idMercadoDiario);

                if (marketRow == null) {
                    throw new IllegalArgumentException("Elemento de mercado no encontrado");
                }

                if (marketRow.resuelto()) {
                    throw new IllegalArgumentException("Este jugador ya no admite pujas");
                }

                if (!today.equals(marketRow.fecha())) {
                    throw new IllegalArgumentException("Solo se puede pujar en el mercado del día actual");
                }

                if (request.cantidad() < marketRow.precioMinimoPuja()) {
                    throw new IllegalArgumentException(
                            "La puja no puede ser inferior al valor actual del jugador en la liga"
                    );
                }

                long saldoActual = lockParticipantMoney(conn, idLiga, request.idUsuario());
                UserBid existingBid = lockUserBid(conn, idMercadoDiario, request.idUsuario());

                long oldAmount = existingBid == null ? 0L : existingBid.cantidad();
                long delta = request.cantidad() - oldAmount;

                if (delta > 0 && saldoActual < delta) {
                    throw new IllegalArgumentException("No tienes saldo suficiente para esa puja");
                }

                if (existingBid == null) {
                    insertBid(conn, idMercadoDiario, request.idUsuario(), request.cantidad());
                } else {
                    updateBid(conn, existingBid.id(), request.cantidad());
                }

                if (delta != 0) {
                    addMoneyToParticipant(conn, idLiga, request.idUsuario(), -delta);
                }

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException iae) {
                    throw iae;
                }
                if (e instanceof SQLException sqle) {
                    throw sqle;
                }

                throw new SQLException("Error guardando puja: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public void deleteBid(Long idLiga, Long idMercadoDiario, Long idUsuario) throws SQLException {
        if (idLiga == null || idMercadoDiario == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, idUsuario);

                LocalDate today = loadCurrentDbDate(conn);
                MarketRow marketRow = lockMarketRow(conn, idLiga, idMercadoDiario);

                if (marketRow == null) {
                    throw new IllegalArgumentException("Elemento de mercado no encontrado");
                }

                if (marketRow.resuelto()) {
                    throw new IllegalArgumentException("Este jugador ya está resuelto");
                }

                if (!today.equals(marketRow.fecha())) {
                    throw new IllegalArgumentException("Solo puedes borrar pujas del mercado actual");
                }

                UserBid existingBid = lockUserBid(conn, idMercadoDiario, idUsuario);
                if (existingBid == null) {
                    throw new IllegalArgumentException("No existe una puja tuya para ese jugador");
                }

                deleteBidRow(conn, existingBid.id());
                addMoneyToParticipant(conn, idLiga, idUsuario, existingBid.cantidad());

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException iae) {
                    throw iae;
                }
                if (e instanceof SQLException sqle) {
                    throw sqle;
                }

                throw new SQLException("Error eliminando puja: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public ProcessResult processNightMarketNow() throws SQLException {
    ProcessResult result;

    try (Connection conn = DBConnection.getConnection()) {
        conn.setAutoCommit(false);

        try {
            LocalDate today = loadCurrentDbDate(conn);

            ResolvePendingResult resolveResult = resolvePendingMarketsBeforeToday(conn, today);
            int generated = generateTodayMarkets(conn, today);

            conn.commit();

            result = new ProcessResult(
                    today,
                    resolveResult.resolvedItems(),
                    generated,
                    resolveResult.awards()
            );
        } catch (Exception e) {
            conn.rollback();

            if (e instanceof SQLException sqle) {
                throw sqle;
            }

            throw new SQLException("Error procesando mercado nocturno: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }

    try {
        nightMarketNotificationService.notifyAwards(result.awards());
    } catch (Exception e) {
        log.error("Error enviando notificaciones del mercado nocturno: {}", e.getMessage(), e);
    }

    return result;
}

    public CleanupCorruptMarketResult cleanupCorruptDailyMarketItems() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                List<MarketResolveRow> corruptRows = lockCorruptMarketRows(conn);

                int refundedBids = 0;
                int deletedBids = 0;
                int deletedItems = 0;

                for (MarketResolveRow row : corruptRows) {
                    refundedBids += refundAllBids(conn, row.idMercadoDiario(), row.idLiga());
                    deletedBids += deleteBidsByMarketItem(conn, row.idMercadoDiario());
                    deletedItems += deleteMarketItem(conn, row.idMercadoDiario());
                }

                conn.commit();
                return new CleanupCorruptMarketResult(
                        corruptRows.size(),
                        refundedBids,
                        deletedBids,
                        deletedItems
                );
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof SQLException sqle) {
                    throw sqle;
                }

                throw new SQLException("Error limpiando mercado diario corrupto: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private ResolvePendingResult resolvePendingMarketsBeforeToday(Connection conn, LocalDate today) throws SQLException {
    String sql = """
            SELECT id, id_liga, id_liga_jugador
            FROM mercado_diario
            WHERE resuelto = 0
              AND fecha < ?
            ORDER BY fecha ASC, id_liga ASC, id ASC
            """;

    List<MarketResolveRow> rows = new ArrayList<>();
    List<MarketAward> awards = new ArrayList<>();

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setDate(1, Date.valueOf(today));

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new MarketResolveRow(
                        rs.getLong("id"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_liga_jugador")
                ));
            }
        }
    }

    int resolvedItems = 0;

    for (MarketResolveRow row : rows) {
        MarketAward award = resolveSingleMarketRow(conn, row);
        resolvedItems++;

        if (award != null) {
            awards.add(award);
        }
    }

    return new ResolvePendingResult(resolvedItems, awards);
}

    private MarketAward resolveSingleMarketRow(Connection conn, MarketResolveRow row) throws SQLException {
    if (!isPlayerStillMarketOwned(conn, row.idLigaJugador(), row.idLiga())) {
        log.warn(
                "Mercado inconsistente. Se resuelve sin ganador. idMercadoDiario={}, idLiga={}, idLigaJugador={}",
                row.idMercadoDiario(),
                row.idLiga(),
                row.idLigaJugador()
        );

        refundAllBids(conn, row.idMercadoDiario(), row.idLiga());
        markMarketResolved(conn, row.idMercadoDiario(), null, null);
        return null;
    }

    WinnerBid winner = loadWinnerBid(conn, row.idMercadoDiario());

    if (winner != null && !isLeagueParticipant(conn, row.idLiga(), winner.idUsuario())) {
        log.warn(
                "Ganador de mercado nocturno ya no pertenece a la liga; se resuelve sin adjudicación. "
                        + "idMercadoDiario={}, idLiga={}, idLigaJugador={}, idUsuarioGanador={}",
                row.idMercadoDiario(),
                row.idLiga(),
                row.idLigaJugador(),
                winner.idUsuario()
        );
        refundAllBids(conn, row.idMercadoDiario(), row.idLiga());
        markMarketResolved(conn, row.idMercadoDiario(), null, null);
        return null;
    }

    if (winner != null) {
        refundLoserBids(conn, row.idMercadoDiario(), row.idLiga(), winner.idUsuario());

        MarketAwardInfo info = loadMarketAwardInfo(conn, row.idLigaJugador());

        int moved = movePlayerFromMarketToUser(conn, row.idLigaJugador(), row.idLiga(), winner.idUsuario());
        if (moved <= 0) {
            log.warn(
                    "No se pudo mover el jugador al ganador. Se devuelve su puja y se resuelve sin ganador. idMercadoDiario={}, idLiga={}, idLigaJugador={}, idUsuarioGanador={}",
                    row.idMercadoDiario(),
                    row.idLiga(),
                    row.idLigaJugador(),
                    winner.idUsuario()
            );

            addMoneyToParticipant(conn, row.idLiga(), winner.idUsuario(), winner.cantidad());
            markMarketResolved(conn, row.idMercadoDiario(), null, null);
            return null;
        }

        markMarketResolved(conn, row.idMercadoDiario(), winner.idUsuario(), winner.cantidad());
        leagueMarketHistoryService.recordMarketHistory(
                conn,
                row.idLiga(),
                row.idLigaJugador(),
                null,
                winner.idUsuario(),
                null,
                LeagueMarketHistoryService.TYPE_ADJUDICACION_MERCADO,
                winner.cantidad()
        );
        accountProgressService.onMarketAdjudication(
                conn,
                winner.idUsuario(),
                row.idLiga(),
                row.idMercadoDiario(),
                winner.cantidad()
        );

        return new MarketAward(
                row.idLiga(),
                winner.idUsuario(),
                row.idLigaJugador(),
                info.nombreJugador(),
                info.pilaJugador(),
                buildPlayerDisplayName(info.nombreJugador(), info.pilaJugador()),
                info.nombreEquipo()
        );
    } else {
        markMarketResolved(conn, row.idMercadoDiario(), null, null);
        return null;
    }
}

    private MarketAwardInfo loadMarketAwardInfo(Connection conn, Long idLigaJugador) throws SQLException {
    String sql = """
            SELECT j.nombre AS nombre_jugador,
                   j.pila AS pila_jugador,
                   e.nombre AS nombre_equipo
            FROM liga_jugadores lj
            INNER JOIN jugadores j ON j.id = lj.id_jugador
            INNER JOIN equipos e ON e.id = lj.id_equipo
            WHERE lj.id = ?
            LIMIT 1
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLigaJugador);

        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                throw new SQLException("No se pudo cargar la info del jugador adjudicado");
            }

            return new MarketAwardInfo(
                    rs.getString("nombre_jugador"),
                    rs.getString("pila_jugador"),
                    rs.getString("nombre_equipo")
            );
        }
    }
}

    private int generateTodayMarkets(Connection conn, LocalDate today) throws SQLException {
        String sqlLeagues = """
                SELECT l.id
                FROM ligas l
                WHERE l.cerrada_en IS NULL
                  AND EXISTS (
                      SELECT 1
                      FROM liga_participantes lp
                      WHERE lp.id_liga = l.id
                  )
                ORDER BY l.id ASC
                """;

        List<Long> idsLiga = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sqlLeagues);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                idsLiga.add(rs.getLong("id"));
            }
        }

        int generated = 0;
        for (Long idLiga : idsLiga) {
            generated += generateTodayMarketForLeague(conn, idLiga, today);
        }

        return generated;
    }

    private int generateTodayMarketForLeague(Connection conn, Long idLiga, LocalDate today) throws SQLException {
        String sqlExists = """
                SELECT COUNT(*) AS total
                FROM mercado_diario
                WHERE id_liga = ?
                  AND fecha = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlExists)) {
            ps.setLong(1, idLiga);
            ps.setDate(2, Date.valueOf(today));

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (rs.getInt("total") > 0) {
                    return 0;
                }
            }
        }

        String sqlCandidates = """
                SELECT lj.id, lj.valor
                FROM liga_jugadores lj
                WHERE lj.id_liga = ?
                  AND lj.id_usuario_dueno = ?
                ORDER BY RAND()
                LIMIT ?
                """;

        List<PlayerCandidate> candidates = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sqlCandidates)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, MARKET_USER_ID);
            ps.setInt(3, ITEMS_PER_DAY);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    candidates.add(new PlayerCandidate(
                            rs.getLong("id"),
                            rs.getLong("valor")
                    ));
                }
            }
        }

        if (candidates.isEmpty()) {
            return 0;
        }

        String sqlInsert = """
                INSERT INTO mercado_diario (
                    id_liga,
                    fecha,
                    id_liga_jugador,
                    precio_salida,
                    resuelto,
                    id_usuario_ganador,
                    puja_ganadora,
                    resuelto_en
                )
                VALUES (?, ?, ?, ?, 0, NULL, NULL, NULL)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sqlInsert)) {
            for (PlayerCandidate candidate : candidates) {
                ps.setLong(1, idLiga);
                ps.setDate(2, Date.valueOf(today));
                ps.setLong(3, candidate.idLigaJugador());
                ps.setLong(4, candidate.valor());
                ps.addBatch();
            }

            ps.executeBatch();
        }

        return candidates.size();
    }

    private List<NightMarketItemResponse> loadNightMarketItems(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            LocalDate fecha
    ) throws SQLException {
        String sql = """
                SELECT md.id AS id_mercado_diario,
                       md.id_liga,
                       md.fecha,
                       md.resuelto,
                       md.resuelto_en,
                       md.id_usuario_ganador,
                       md.puja_ganadora,
                       md.id_liga_jugador,
                       lj.id_jugador,
                       j.nombre,
                       j.pila,
                       j.posicion,
                       j.foto AS foto_jugador,
                       lj.id_equipo,
                       e.nombre AS nombre_equipo,
                       e.foto AS foto_equipo,
                       lj.estado,
                       lj.cansancio,
                       lj.valor,
                       CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED) AS valoracion,
                       (
                           SELECT p.cantidad
                           FROM pujas p
                           WHERE p.id_mercado_diario = md.id
                             AND p.id_usuario = ?
                           LIMIT 1
                       ) AS mi_puja,
                       (
                           SELECT MAX(p2.cantidad)
                           FROM pujas p2
                           WHERE p2.id_mercado_diario = md.id
                       ) AS puja_mas_alta,
                       (
                           SELECT COUNT(*)
                           FROM pujas p3
                           WHERE p3.id_mercado_diario = md.id
                       ) AS total_pujas
                FROM mercado_diario md
                INNER JOIN liga_jugadores lj ON lj.id = md.id_liga_jugador
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = lj.id_equipo
                WHERE md.id_liga = ?
                  AND md.fecha = ?
                ORDER BY md.id ASC
                """;

        List<NightMarketItemResponse> items = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idLiga);
            ps.setDate(3, Date.valueOf(fecha));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp resolvedTs = rs.getTimestamp("resuelto_en");
                    Instant resolvedAt = resolvedTs == null ? null : resolvedTs.toInstant();

                    items.add(new NightMarketItemResponse(
                            rs.getLong("id_mercado_diario"),
                            rs.getLong("id_liga"),
                            rs.getDate("fecha").toLocalDate(),
                            rs.getBoolean("resuelto"),
                            resolvedAt,
                            getNullableLong(rs, "id_usuario_ganador"),
                            getNullableLong(rs, "puja_ganadora"),

                            rs.getLong("id_liga_jugador"),
                            rs.getLong("id_jugador"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            buildPlayerDisplayName(rs.getString("nombre"), rs.getString("pila")),
                            rs.getString("posicion"),
                            LeagueAssetUrls.player(rs.getLong("id_jugador")),

                            rs.getLong("id_equipo"),
                            rs.getString("nombre_equipo"),
                            LeagueAssetUrls.team(rs.getLong("id_equipo")),

                            rs.getString("estado"),
                            rs.getInt("cansancio"),
                            rs.getLong("valor"),
                            rs.getInt("valoracion"),
                            rs.getLong("valor"),

                            getNullableLong(rs, "mi_puja"),
                            getNullableLong(rs, "puja_mas_alta"),
                            rs.getInt("total_pujas")
                    ));
                }
            }
        }

        return items;
    }

    private LocalDate loadCurrentDbDate(Connection conn) throws SQLException {
        String sql = "SELECT CURDATE() AS today";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getDate("today").toLocalDate();
        }
    }

    private long loadParticipantMoney(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT dinero
                FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("No perteneces a esta liga");
                }
                return rs.getLong("dinero");
            }
        }
    }

    private long lockParticipantMoney(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT dinero
                FROM liga_participantes
                WHERE id_liga = ?
                  AND id_usuario = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("No perteneces a esta liga");
                }
                return rs.getLong("dinero");
            }
        }
    }

    private long loadReservedMoney(Connection conn, Long idLiga, Long idUsuario, LocalDate fecha) throws SQLException {
        String sql = """
                SELECT COALESCE(SUM(p.cantidad), 0) AS total
                FROM pujas p
                INNER JOIN mercado_diario md ON md.id = p.id_mercado_diario
                WHERE md.id_liga = ?
                  AND md.fecha = ?
                  AND md.resuelto = 0
                  AND p.id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setDate(2, Date.valueOf(fecha));
            ps.setLong(3, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong("total");
            }
        }
    }

    private boolean isPlayerInTodayMarket(Connection conn, Long idLiga, Long idLigaJugador, LocalDate today) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM mercado_diario
                WHERE id_liga = ?
                  AND id_liga_jugador = ?
                  AND fecha = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            ps.setDate(3, Date.valueOf(today));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total") > 0;
            }
        }
    }

    private MarketRow lockMarketRow(Connection conn, Long idLiga, Long idMercadoDiario) throws SQLException {
        String sql = """
                SELECT md.id,
                       md.id_liga,
                       md.fecha,
                       md.id_liga_jugador,
                       lj.valor AS valor_actual_puja_minima,
                       md.resuelto
                FROM mercado_diario md
                INNER JOIN liga_jugadores lj ON lj.id = md.id_liga_jugador
                  AND lj.id_liga = md.id_liga
                WHERE md.id = ?
                  AND md.id_liga = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);
            ps.setLong(2, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new MarketRow(
                        rs.getLong("id"),
                        rs.getLong("id_liga"),
                        rs.getDate("fecha").toLocalDate(),
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("valor_actual_puja_minima"),
                        rs.getBoolean("resuelto")
                );
            }
        }
    }

    private UserBid lockUserBid(Connection conn, Long idMercadoDiario, Long idUsuario) throws SQLException {
        String sql = """
                SELECT id, cantidad
                FROM pujas
                WHERE id_mercado_diario = ?
                  AND id_usuario = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new UserBid(
                        rs.getLong("id"),
                        rs.getLong("cantidad")
                );
            }
        }
    }

    private void insertBid(Connection conn, Long idMercadoDiario, Long idUsuario, Long cantidad) throws SQLException {
        String sql = """
                INSERT INTO pujas (id_mercado_diario, id_usuario, cantidad, fecha)
                VALUES (?, ?, ?, NOW())
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);
            ps.setLong(2, idUsuario);
            ps.setLong(3, cantidad);
            ps.executeUpdate();
        }
    }

    private void updateBid(Connection conn, Long idPuja, Long cantidad) throws SQLException {
        String sql = """
                UPDATE pujas
                SET cantidad = ?,
                    fecha = NOW()
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, cantidad);
            ps.setLong(2, idPuja);
            ps.executeUpdate();
        }
    }

    private void deleteBidRow(Connection conn, Long idPuja) throws SQLException {
        String sql = """
                DELETE FROM pujas
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idPuja);
            ps.executeUpdate();
        }
    }

    private void addMoneyToParticipant(Connection conn, Long idLiga, Long idUsuario, long delta) throws SQLException {
        String sql = """
                UPDATE liga_participantes
                SET dinero = dinero + ?
                WHERE id_liga = ?
                  AND id_usuario = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, delta);
            ps.setLong(2, idLiga);
            ps.setLong(3, idUsuario);
            ps.executeUpdate();
        }
    }

    private WinnerBid loadWinnerBid(Connection conn, Long idMercadoDiario) throws SQLException {
        String sql = """
                SELECT id_usuario, cantidad, fecha, id
                FROM pujas
                WHERE id_mercado_diario = ?
                ORDER BY cantidad DESC, fecha ASC, id ASC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new WinnerBid(
                        rs.getLong("id_usuario"),
                        rs.getLong("cantidad")
                );
            }
        }
    }

    private void refundLoserBids(Connection conn, Long idMercadoDiario, Long idLiga, Long winnerUserId) throws SQLException {
        String sql = """
                SELECT id_usuario, cantidad
                FROM pujas
                WHERE id_mercado_diario = ?
                  AND id_usuario <> ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);
            ps.setLong(2, winnerUserId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    addMoneyToParticipant(
                            conn,
                            idLiga,
                            rs.getLong("id_usuario"),
                            rs.getLong("cantidad")
                    );
                }
            }
        }
    }

    private int movePlayerFromMarketToUser(Connection conn, Long idLigaJugador, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?,
                    adquirido_en = NOW()
                WHERE id = ?
                  AND id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, idLiga);
            ps.setLong(4, MARKET_USER_ID);
            return ps.executeUpdate();
        }
    }

    private void markMarketResolved(Connection conn, Long idMercadoDiario, Long winnerUserId, Long winningBid) throws SQLException {
        String sql = """
                UPDATE mercado_diario
                SET resuelto = 1,
                    resuelto_en = NOW(),
                    id_usuario_ganador = ?,
                    puja_ganadora = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (winnerUserId == null) {
                ps.setNull(1, Types.BIGINT);
            } else {
                ps.setLong(1, winnerUserId);
            }

            if (winningBid == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, winningBid);
            }

            ps.setLong(3, idMercadoDiario);
            ps.executeUpdate();
        }
    }

    /**
     * Cancela mercados diarios no resueltos de jugadores concretos (p. ej. al expulsar dueño):
     * reembolsa todas las pujas y elimina pujas + fila de mercado.
     */
    /**
     * @return pujas reembolsadas al cancelar mercados no resueltos de esos jugadores
     */
    public int cancelUnresolvedMarketsForLeaguePlayers(
            Connection conn,
            Long idLiga,
            List<Long> idLigaJugadores
    ) throws SQLException {
        if (conn == null || idLiga == null || idLigaJugadores == null || idLigaJugadores.isEmpty()) {
            return 0;
        }

        StringBuilder sql = new StringBuilder("""
                SELECT id
                FROM mercado_diario
                WHERE id_liga = ?
                  AND resuelto = 0
                  AND id_liga_jugador IN (
                """);
        sql.append("?,".repeat(idLigaJugadores.size()));
        sql.setLength(sql.length() - 1);
        sql.append(") FOR UPDATE");

        List<Long> marketIds = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idLiga);
            for (int i = 0; i < idLigaJugadores.size(); i++) {
                ps.setLong(i + 2, idLigaJugadores.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    marketIds.add(rs.getLong("id"));
                }
            }
        }

        int totalRefundedBids = 0;
        for (Long idMercadoDiario : marketIds) {
            int refunded = refundAllBids(conn, idMercadoDiario, idLiga);
            totalRefundedBids += refunded;
            deleteBidsByMarketItem(conn, idMercadoDiario);
            deleteMarketItem(conn, idMercadoDiario);
            log.info(
                    "Mercado diario cancelado por salida de jugador de plantilla. idMercadoDiario={}, idLiga={}, pujasReembolsadas={}",
                    idMercadoDiario,
                    idLiga,
                    refunded
            );
        }
        return totalRefundedBids;
    }

    private boolean isLeagueParticipant(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            return false;
        }
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

    private Long getNullableLong(ResultSet rs, String columnName) throws SQLException {
        long value = rs.getLong(columnName);
        return rs.wasNull() ? null : value;
    }

    private String buildPlayerDisplayName(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) return pila;
        if (nombre != null && !nombre.isBlank()) return nombre;
        return null;
    }

    public void ensureTodayMarketExists(Connection conn, Long idLiga) throws SQLException {
    if (conn == null || idLiga == null) {
        throw new IllegalArgumentException("Faltan datos obligatorios");
    }

    LocalDate today = loadCurrentDbDate(conn);
    generateTodayMarketForLeague(conn, idLiga, today);
}

private boolean isPlayerStillMarketOwned(Connection conn, Long idLigaJugador, Long idLiga) throws SQLException {
    String sql = """
            SELECT COUNT(*) AS total
            FROM liga_jugadores
            WHERE id = ?
              AND id_liga = ?
              AND id_usuario_dueno = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idLigaJugador);
        ps.setLong(2, idLiga);
        ps.setLong(3, MARKET_USER_ID);

        try (ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt("total") > 0;
        }
    }
}

private int refundAllBids(Connection conn, Long idMercadoDiario, Long idLiga) throws SQLException {
    String sql = """
            SELECT id_usuario, cantidad
            FROM pujas
            WHERE id_mercado_diario = ?
            """;

    int refunded = 0;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idMercadoDiario);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                addMoneyToParticipant(
                        conn,
                        idLiga,
                        rs.getLong("id_usuario"),
                        rs.getLong("cantidad")
                );
                refunded++;
            }
        }
    }

    return refunded;
}

private List<MarketResolveRow> lockCorruptMarketRows(Connection conn) throws SQLException {
    String sql = """
            SELECT md.id AS id_mercado_diario,
                   md.id_liga,
                   md.id_liga_jugador
            FROM mercado_diario md
            INNER JOIN liga_jugadores lj ON lj.id = md.id_liga_jugador
            WHERE lj.id_usuario_dueno <> ?
            ORDER BY md.id ASC
            FOR UPDATE
            """;

    List<MarketResolveRow> rows = new ArrayList<>();
    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, MARKET_USER_ID);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new MarketResolveRow(
                        rs.getLong("id_mercado_diario"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_liga_jugador")
                ));
            }
        }
    }

    return rows;
}

private int deleteBidsByMarketItem(Connection conn, Long idMercadoDiario) throws SQLException {
    String sql = """
            DELETE FROM pujas
            WHERE id_mercado_diario = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idMercadoDiario);
        return ps.executeUpdate();
    }
}

private int deleteMarketItem(Connection conn, Long idMercadoDiario) throws SQLException {
    String sql = """
            DELETE FROM mercado_diario
            WHERE id = ?
            """;

    try (PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, idMercadoDiario);
        return ps.executeUpdate();
    }
}

    public record ProcessResult(
        LocalDate fecha,
        int resolvedItems,
        int generatedItems,
        List<MarketAward> awards
) {
}

public record MarketAward(
        Long idLiga,
        Long idUsuario,
        Long idLigaJugador,
        String nombreJugador,
        String pilaJugador,
        String nombreMostradoJugador,
        String nombreEquipo
) {
}

private record MarketAwardInfo(
        String nombreJugador,
        String pilaJugador,
        String nombreEquipo
) {
}
    private record MarketResolveRow(
            Long idMercadoDiario,
            Long idLiga,
            Long idLigaJugador
    ) {
    }

    private record PlayerCandidate(
            Long idLigaJugador,
            Long valor
    ) {
    }

    private record WinnerBid(
            Long idUsuario,
            Long cantidad
    ) {
    }

    private record UserBid(
            Long id,
            Long cantidad
    ) {
    }

    /** {@code valorActualMercado}: mínimo de puja (= {@code liga_jugadores.valor} en el momento del bloqueo). */
    private record MarketRow(
            Long id,
            Long idLiga,
            LocalDate fecha,
            Long idLigaJugador,
            Long precioMinimoPuja,
            boolean resuelto
    ) {
    }

    private record ResolvePendingResult(
        int resolvedItems,
        List<MarketAward> awards
) {
}

    public record CleanupCorruptMarketResult(
            int corruptItems,
            int refundedBids,
            int deletedBids,
            int deletedItems
    ) {
    }

    private record MarketOwnedPlayerRow(
        Long idLigaJugador,
        Long idLiga,
        Long idUsuarioDueno,
        Long valorActual
) {
}

}