package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.league.LeagueInstantSellResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerOfferResponse;
import com.eternalxi.eternalxi_api.dto.league.LeaguePlayerOfferUpsertRequest;
import com.eternalxi.eternalxi_api.dto.league.StarterProbabilityLite;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class LeagueTradeService {

    private static final long MARKET_USER_ID = 1L;

    private final LeagueLineupService leagueLineupService;
    private final LeagueMarketHistoryService leagueMarketHistoryService;
    private final LeagueOfferNotificationService leagueOfferNotificationService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeaguePlayerMarketValueService leaguePlayerMarketValueService;
    private final AccountProgressService accountProgressService;

    public LeagueTradeService(
            LeagueLineupService leagueLineupService,
            LeagueMarketHistoryService leagueMarketHistoryService,
            LeagueOfferNotificationService leagueOfferNotificationService,
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeaguePlayerMarketValueService leaguePlayerMarketValueService,
            AccountProgressService accountProgressService
    ) {
        this.leagueLineupService = leagueLineupService;
        this.leagueMarketHistoryService = leagueMarketHistoryService;
        this.leagueOfferNotificationService = leagueOfferNotificationService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leaguePlayerMarketValueService = leaguePlayerMarketValueService;
        this.accountProgressService = accountProgressService;
    }

    public LeagueInstantSellResponse sellPlayerToMarket(Long idLiga, Long idLigaJugador, Long idUsuario) throws SQLException {
        if (idLiga == null || idLigaJugador == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, idUsuario);

                LockedLeaguePlayer player = lockLeaguePlayer(conn, idLiga, idLigaJugador);
                if (player == null) {
                    throw new IllegalArgumentException("Jugador no encontrado en la liga");
                }

                if (!Objects.equals(player.idUsuarioDueno(), idUsuario)) {
                    throw new IllegalArgumentException("Ese jugador no te pertenece");
                }

                long cantidadVenta = Math.max(0L, (long) Math.floor(player.valor() * 0.90d));

                int moved = sendPlayerToMarket(conn, idLiga, idLigaJugador, idUsuario);
                if (moved <= 0) {
                    throw new SQLException("No se pudo vender el jugador al mercado");
                }

                addMoneyToParticipant(conn, idLiga, idUsuario, cantidadVenta);

                refundAndClosePendingOffersForPlayer(conn, idLiga, idLigaJugador, null, "INVALIDADA");
                leagueMarketHistoryService.recordMarketHistory(
                        conn,
                        idLiga,
                        idLigaJugador,
                        null,
                        MARKET_USER_ID,
                        idUsuario,
                        LeagueMarketHistoryService.TYPE_VENTA_MERCADO,
                        cantidadVenta
                );

                try {
                    leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, idUsuario);
                } catch (IllegalArgumentException ignored) {
                    // La venta no debe bloquearse por no poder recomponer una alineación editable completa.
                }

                long nuevoSaldo = loadParticipantMoneyForUpdate(conn, idLiga, idUsuario);

                accountProgressService.onPlayerSold(conn, idUsuario, idLiga, cantidadVenta);

                conn.commit();

                return new LeagueInstantSellResponse(
                        idLiga,
                        idLigaJugador,
                        idUsuario,
                        player.valor(),
                        cantidadVenta,
                        nuevoSaldo
                );
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error vendiendo jugador al mercado: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /**
     * Misma lógica que {@link #sellPlayerToMarket} pero con multiplicador configurable (p. ej. cartas de recompensa).
     * Usa la conexión externa ya en transacción.
     */
    public long sellLeaguePlayerToMarketWithinTransaction(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuario,
            double sellMultiplier
    ) throws SQLException {
        if (idLiga == null || idLigaJugador == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        ensureParticipant(conn, idLiga, idUsuario);

        LockedLeaguePlayer player = lockLeaguePlayer(conn, idLiga, idLigaJugador);
        if (player == null) {
            throw new IllegalArgumentException("Jugador no encontrado en la liga");
        }

        if (!Objects.equals(player.idUsuarioDueno(), idUsuario)) {
            throw new IllegalArgumentException("Ese jugador no te pertenece");
        }

        long baseValor = player.valor();
        long valorEfectivo = leaguePlayerMarketValueService.effectiveValue(conn, idLiga, idLigaJugador, baseValor);
        long cantidadVenta = Math.max(0L, (long) Math.floor(valorEfectivo * sellMultiplier));

        int moved = sendPlayerToMarket(conn, idLiga, idLigaJugador, idUsuario);
        if (moved <= 0) {
            throw new SQLException("No se pudo vender el jugador al mercado");
        }

        addMoneyToParticipant(conn, idLiga, idUsuario, cantidadVenta);

        refundAndClosePendingOffersForPlayer(conn, idLiga, idLigaJugador, null, "INVALIDADA");
        leagueMarketHistoryService.recordMarketHistory(
                conn,
                idLiga,
                idLigaJugador,
                null,
                MARKET_USER_ID,
                idUsuario,
                LeagueMarketHistoryService.TYPE_VENTA_MERCADO,
                cantidadVenta
        );

        try {
            leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, idUsuario);
        } catch (IllegalArgumentException ignored) {
            // Igual que venta normal: no bloquear por alineación.
        }

        return loadParticipantMoneyForUpdate(conn, idLiga, idUsuario);
    }

    public record DirectClauseResult(
            long valorBaseMercado,
            long valorMercadoEfectivo,
            long buyerPaid,
            long ownerReceived,
            long buyerNewMoney,
            long ownerNewMoney
    ) {}

    /**
     * Fichaje forzado entre usuarios (cláusula). El comprador paga {@code ceil(valorEfectivo * buyerMultiplier)};
     * el vendedor recibe {@code floor(valorEfectivo * ownerCompensationMultiplier)}. El excedente desaparece.
     */
    public DirectClauseResult executeDirectClauseWithinTransaction(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioComprador,
            double buyerMultiplier,
            double ownerCompensationMultiplier,
            Long maxPlayerValueOrNull
    ) throws SQLException {
        if (idLiga == null || idLigaJugador == null || idUsuarioComprador == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }
        ensureParticipant(conn, idLiga, idUsuarioComprador);

        LockedLeaguePlayer player = lockLeaguePlayer(conn, idLiga, idLigaJugador);
        if (player == null) {
            throw new IllegalArgumentException("Jugador no encontrado en la liga");
        }

        long idDueno = player.idUsuarioDueno();
        if (idDueno == MARKET_USER_ID) {
            throw new IllegalArgumentException("No se puede usar cláusula sobre jugadores del mercado");
        }
        if (Objects.equals(idDueno, idUsuarioComprador)) {
            throw new IllegalArgumentException("No puedes usar cláusula sobre tu propio jugador");
        }

        long valorBase = player.valor();
        long valorEfectivo = leaguePlayerMarketValueService.effectiveValue(conn, idLiga, idLigaJugador, valorBase);
        if (maxPlayerValueOrNull != null && valorEfectivo > maxPlayerValueOrNull) {
            throw new IllegalArgumentException("El valor del jugador supera el máximo permitido por esta carta");
        }

        long buyerPay = (long) Math.ceil(valorEfectivo * buyerMultiplier);
        long ownerReceive = (long) Math.floor(valorEfectivo * ownerCompensationMultiplier);

        long buyerId = idUsuarioComprador;
        long sellerId = idDueno;
        long firstUser = Math.min(buyerId, sellerId);
        long secondUser = Math.max(buyerId, sellerId);

        loadParticipantMoneyForUpdate(conn, idLiga, firstUser);
        loadParticipantMoneyForUpdate(conn, idLiga, secondUser);

        long buyerMoney = readParticipantMoney(conn, idLiga, buyerId);
        if (buyerMoney < buyerPay) {
            throw new IllegalArgumentException("No tienes saldo suficiente para ejecutar la cláusula");
        }

        int moved = transferPlayerToBuyer(conn, idLiga, idLigaJugador, sellerId, buyerId);
        if (moved <= 0) {
            throw new SQLException("No se pudo transferir el jugador");
        }

        addMoneyToParticipant(conn, idLiga, buyerId, -buyerPay);
        addMoneyToParticipant(conn, idLiga, sellerId, ownerReceive);

        refundAndClosePendingOffersForPlayer(conn, idLiga, idLigaJugador, null, "INVALIDADA");

        leagueMarketHistoryService.recordMarketHistory(
                conn,
                idLiga,
                idLigaJugador,
                null,
                buyerId,
                sellerId,
                LeagueMarketHistoryService.TYPE_ACUERDO_USUARIOS,
                buyerPay
        );

        try {
            leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, sellerId);
        } catch (IllegalArgumentException ignored) {
            // no bloquear
        }
        try {
            leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, buyerId);
        } catch (IllegalArgumentException ignored) {
            // no bloquear
        }

        long buyerNew = readParticipantMoney(conn, idLiga, buyerId);
        long ownerNew = readParticipantMoney(conn, idLiga, sellerId);
        return new DirectClauseResult(valorBase, valorEfectivo, buyerPay, ownerReceive, buyerNew, ownerNew);
    }

    public void upsertOffer(Long idLiga, Long idLigaJugador, LeaguePlayerOfferUpsertRequest request) throws SQLException {
        if (idLiga == null || idLigaJugador == null || request == null
                || request.idUsuario() == null || request.cantidad() == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        if (request.cantidad() <= 0) {
            throw new IllegalArgumentException("La oferta debe ser un número entero positivo.");
        }
        if (request.cantidad() > 999_999_999_999L) {
            throw new IllegalArgumentException("La cantidad es demasiado grande.");
        }

        LeagueOfferNotificationService.OfferNotificationPayload notificationPayload = null;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, request.idUsuario());

                LockedLeaguePlayer player = lockLeaguePlayer(conn, idLiga, idLigaJugador);
                if (player == null) {
                    throw new IllegalArgumentException("Jugador no encontrado en la liga");
                }

                if (Objects.equals(player.idUsuarioDueno(), request.idUsuario())) {
                    throw new IllegalArgumentException("No puedes ofertar por tu propio jugador");
                }

                if (Objects.equals(player.idUsuarioDueno(), MARKET_USER_ID)) {
                    throw new IllegalArgumentException("No puedes hacer ofertas por jugadores del mercado");
                }

                long valorEfectivo = leaguePlayerMarketValueService.effectiveValue(conn, idLiga, idLigaJugador, player.valor());
                if (request.cantidad() < valorEfectivo) {
                    throw new IllegalArgumentException("La oferta mínima por este jugador es " + formatMoney(valorEfectivo) + ".");
                }

                PendingOffer existing = lockPendingOfferByBuyer(conn, idLiga, idLigaJugador, request.idUsuario());
                long cantidadAnterior = existing == null ? 0L : existing.cantidad();
                long delta = request.cantidad() - cantidadAnterior;

                long saldoActual = loadParticipantMoneyForUpdate(conn, idLiga, request.idUsuario());
                if (delta > 0 && saldoActual < delta) {
                    throw new IllegalArgumentException("No tienes saldo suficiente para esa oferta");
                }

                if (existing == null) {
                    insertOffer(conn, idLiga, idLigaJugador, request.idUsuario(), request.cantidad());
                } else {
                    updateOfferAmount(conn, existing.idOferta(), request.cantidad());
                }

                if (delta != 0) {
                    addMoneyToParticipant(conn, idLiga, request.idUsuario(), -delta);
                }

                PendingOffer savedOffer = lockPendingOfferByBuyer(conn, idLiga, idLigaJugador, request.idUsuario());
                if (savedOffer == null) {
                    throw new SQLException("No se pudo recuperar la oferta guardada");
                }
                notificationPayload = loadOfferNotificationPayload(
                        conn,
                        idLiga,
                        idLigaJugador,
                        savedOffer.idOferta(),
                        request.idUsuario(),
                        player.idUsuarioDueno(),
                        savedOffer.cantidad()
                );

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error guardando oferta: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }

        if (notificationPayload != null) {
            leagueOfferNotificationService.notifyOfferReceived(notificationPayload);
        }
    }

    public List<LeaguePlayerOfferResponse> getSentOffers(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT oj.id AS id_oferta,
                           oj.id_liga,
                           oj.id_liga_jugador,
                           oj.id_usuario_comprador,
                           oj.cantidad,
                           oj.estado,
                           oj.creada_en,
                           oj.actualizada_en,
                           oj.respondida_en,
                           lj.id_jugador,
                           j.nombre,
                           j.pila,
                           j.posicion,
                           j.foto AS foto_jugador,
                           lj.id_equipo,
                           e.nombre AS nombre_equipo,
                           e.foto AS foto_equipo,
                           lj.estado AS estado_jugador,
                           lj.cansancio,
                           lj.valor AS valor_actual,
                           lj.id_usuario_dueno AS id_usuario_dueno_actual,
                           COALESCE(ud.nickname, '') AS nickname_dueno_actual,
                           COALESCE(uc.nickname, '') AS nickname_comprador,
                           COALESCE(uc.foto, '') AS foto_usuario_comprador
                    FROM ofertas_jugador oj
                    INNER JOIN liga_jugadores lj ON lj.id = oj.id_liga_jugador
                    INNER JOIN jugadores j ON j.id = lj.id_jugador
                    INNER JOIN equipos e ON e.id = lj.id_equipo
                    LEFT JOIN usuarios ud ON ud.id = lj.id_usuario_dueno
                    LEFT JOIN usuarios uc ON uc.id = oj.id_usuario_comprador
                    WHERE oj.id_liga = ?
                      AND oj.id_usuario_comprador = ?
                    ORDER BY
                        CASE oj.estado WHEN 'PENDIENTE' THEN 0 ELSE 1 END,
                        oj.actualizada_en DESC,
                        oj.id DESC
                    """;

            List<LeaguePlayerOfferResponse> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idUsuario);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(mapOfferRow(rs));
                    }
                }
            }

            return enrichOffersWithStarterProbabilities(conn, idLiga, rows);
        }
    }

    public List<LeaguePlayerOfferResponse> getReceivedOffers(Long idLiga, Long idUsuario) throws SQLException {
        if (idLiga == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureParticipant(conn, idLiga, idUsuario);

            String sql = """
                    SELECT oj.id AS id_oferta,
                           oj.id_liga,
                           oj.id_liga_jugador,
                           oj.id_usuario_comprador,
                           oj.cantidad,
                           oj.estado,
                           oj.creada_en,
                           oj.actualizada_en,
                           oj.respondida_en,
                           lj.id_jugador,
                           j.nombre,
                           j.pila,
                           j.posicion,
                           j.foto AS foto_jugador,
                           lj.id_equipo,
                           e.nombre AS nombre_equipo,
                           e.foto AS foto_equipo,
                           lj.estado AS estado_jugador,
                           lj.cansancio,
                           lj.valor AS valor_actual,
                           lj.id_usuario_dueno AS id_usuario_dueno_actual,
                           COALESCE(ud.nickname, '') AS nickname_dueno_actual,
                           COALESCE(uc.nickname, '') AS nickname_comprador,
                           COALESCE(uc.foto, '') AS foto_usuario_comprador
                    FROM ofertas_jugador oj
                    INNER JOIN liga_jugadores lj ON lj.id = oj.id_liga_jugador
                    INNER JOIN jugadores j ON j.id = lj.id_jugador
                    INNER JOIN equipos e ON e.id = lj.id_equipo
                    LEFT JOIN usuarios ud ON ud.id = lj.id_usuario_dueno
                    LEFT JOIN usuarios uc ON uc.id = oj.id_usuario_comprador
                    WHERE oj.id_liga = ?
                      AND lj.id_usuario_dueno = ?
                    ORDER BY
                        CASE oj.estado WHEN 'PENDIENTE' THEN 0 ELSE 1 END,
                        oj.actualizada_en DESC,
                        oj.id DESC
                    """;

            List<LeaguePlayerOfferResponse> rows = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                ps.setLong(2, idUsuario);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(mapOfferRow(rs));
                    }
                }
            }

            return enrichOffersWithStarterProbabilities(conn, idLiga, rows);
        }
    }

    public void acceptOffer(Long idLiga, Long idOferta, Long idUsuario) throws SQLException {
        if (idLiga == null || idOferta == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        LeagueOfferNotificationService.OfferNotificationPayload notificationPayload = null;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, idUsuario);

                LockedOffer offer = lockOfferForAction(conn, idLiga, idOferta);
                if (offer == null) {
                    throw new IllegalArgumentException("Oferta no encontrada");
                }

                if (!"PENDIENTE".equals(offer.estado())) {
                    throw new IllegalArgumentException("La oferta ya no está pendiente");
                }

                if (!Objects.equals(offer.idUsuarioDuenoActual(), idUsuario)) {
                    throw new IllegalArgumentException("Solo el dueño actual del jugador puede aceptar la oferta");
                }

                ensureParticipant(conn, idLiga, offer.idUsuarioComprador());

                int moved = transferPlayerToBuyer(
                        conn,
                        idLiga,
                        offer.idLigaJugador(),
                        idUsuario,
                        offer.idUsuarioComprador()
                );
                if (moved <= 0) {
                    throw new SQLException("No se pudo transferir el jugador al comprador");
                }

                addMoneyToParticipant(conn, idLiga, idUsuario, offer.cantidad());

                updateOfferState(conn, idOferta, "ACEPTADA", true);
                refundAndClosePendingOffersForPlayer(conn, idLiga, offer.idLigaJugador(), idOferta, "INVALIDADA");
                leagueMarketHistoryService.recordMarketHistory(
                        conn,
                        idLiga,
                        offer.idLigaJugador(),
                        null,
                        offer.idUsuarioComprador(),
                        idUsuario,
                        LeagueMarketHistoryService.TYPE_ACUERDO_USUARIOS,
                        offer.cantidad()
                );
                notificationPayload = loadOfferNotificationPayload(
                        conn,
                        idLiga,
                        offer.idLigaJugador(),
                        idOferta,
                        offer.idUsuarioComprador(),
                        idUsuario,
                        offer.cantidad()
                );

                leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, idUsuario);
                leagueLineupService.ensureDefaultLineupForNextEditableRound(conn, idLiga, offer.idUsuarioComprador());

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error aceptando oferta: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }

        if (notificationPayload != null) {
            leagueOfferNotificationService.notifyOfferAccepted(notificationPayload);
        }
    }

    public void rejectOffer(Long idLiga, Long idOferta, Long idUsuario) throws SQLException {
        if (idLiga == null || idOferta == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        LeagueOfferNotificationService.OfferNotificationPayload notificationPayload = null;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, idUsuario);

                LockedOffer offer = lockOfferForAction(conn, idLiga, idOferta);
                if (offer == null) {
                    throw new IllegalArgumentException("Oferta no encontrada");
                }

                if (!"PENDIENTE".equals(offer.estado())) {
                    throw new IllegalArgumentException("La oferta ya no está pendiente");
                }

                if (!Objects.equals(offer.idUsuarioDuenoActual(), idUsuario)) {
                    throw new IllegalArgumentException("Solo el dueño actual del jugador puede rechazar la oferta");
                }

                addMoneyToParticipant(conn, idLiga, offer.idUsuarioComprador(), offer.cantidad());
                updateOfferState(conn, idOferta, "RECHAZADA", true);
                notificationPayload = loadOfferNotificationPayload(
                        conn,
                        idLiga,
                        offer.idLigaJugador(),
                        idOferta,
                        offer.idUsuarioComprador(),
                        idUsuario,
                        offer.cantidad()
                );

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error rechazando oferta: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }

        if (notificationPayload != null) {
            leagueOfferNotificationService.notifyOfferRejected(notificationPayload);
        }
    }

    public void cancelOffer(Long idLiga, Long idOferta, Long idUsuario) throws SQLException {
        if (idLiga == null || idOferta == null || idUsuario == null) {
            throw new IllegalArgumentException("Faltan datos obligatorios");
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                ensureParticipant(conn, idLiga, idUsuario);

                LockedOffer offer = lockOfferForAction(conn, idLiga, idOferta);
                if (offer == null) {
                    throw new IllegalArgumentException("Oferta no encontrada");
                }

                if (!"PENDIENTE".equals(offer.estado())) {
                    throw new IllegalArgumentException("La oferta ya no está pendiente");
                }

                if (!Objects.equals(offer.idUsuarioComprador(), idUsuario)) {
                    throw new IllegalArgumentException("Solo quien hizo la oferta puede cancelarla");
                }

                addMoneyToParticipant(conn, idLiga, idUsuario, offer.cantidad());
                updateOfferState(conn, idOferta, "CANCELADA", true);

                conn.commit();
            } catch (Exception e) {
                conn.rollback();

                if (e instanceof IllegalArgumentException illegalArgumentException) {
                    throw illegalArgumentException;
                }
                if (e instanceof SQLException sqlException) {
                    throw sqlException;
                }

                throw new SQLException("Error cancelando oferta: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private LeaguePlayerOfferResponse mapOfferRow(ResultSet rs) throws SQLException {
        Timestamp createdTs = rs.getTimestamp("creada_en");
        Timestamp updatedTs = rs.getTimestamp("actualizada_en");
        Timestamp respondedTs = rs.getTimestamp("respondida_en");

        return new LeaguePlayerOfferResponse(
                rs.getLong("id_oferta"),
                rs.getLong("id_liga"),
                rs.getLong("id_liga_jugador"),
                rs.getLong("id_usuario_comprador"),
                rs.getLong("cantidad"),
                rs.getString("estado"),
                createdTs == null ? null : createdTs.toInstant(),
                updatedTs == null ? null : updatedTs.toInstant(),
                respondedTs == null ? null : respondedTs.toInstant(),

                rs.getLong("id_jugador"),
                rs.getString("nombre"),
                rs.getString("pila"),
                buildPlayerDisplayName(rs.getString("nombre"), rs.getString("pila")),
                rs.getString("posicion"),
                LeagueAssetUrls.player(rs.getLong("id_jugador")),

                rs.getLong("id_equipo"),
                rs.getString("nombre_equipo"),
                LeagueAssetUrls.team(rs.getLong("id_equipo")),

                rs.getString("estado_jugador"),
                rs.getInt("cansancio"),
                rs.getLong("valor_actual"),

                rs.getLong("id_usuario_dueno_actual"),
                rs.getString("nickname_dueno_actual"),
                rs.getString("nickname_comprador"),
                rs.getString("foto_usuario_comprador"),
                null,
                null,
                null,
                null
        );
    }

    private List<LeaguePlayerOfferResponse> enrichOffersWithStarterProbabilities(
            Connection conn,
            Long idLiga,
            List<LeaguePlayerOfferResponse> rows
    ) throws SQLException {
        if (rows.isEmpty()) {
            return rows;
        }
        Long idJornada = leagueStarterProbabilityService.resolveTargetJornadaForProbabilities(conn, idLiga, null);
        if (idJornada == null) {
            return rows;
        }
        List<Long> ids = rows.stream().map(LeaguePlayerOfferResponse::idLigaJugador).toList();
        Map<Long, StarterProbabilityLite> prob =
                leagueStarterProbabilityService.loadProbabilityMapForLeaguePlayers(conn, idLiga, idJornada, ids);
        List<LeaguePlayerOfferResponse> out = new ArrayList<>();
        for (LeaguePlayerOfferResponse r : rows) {
            StarterProbabilityLite l = prob.get(r.idLigaJugador());
            out.add(
                    new LeaguePlayerOfferResponse(
                            r.idOferta(),
                            r.idLiga(),
                            r.idLigaJugador(),
                            r.idUsuarioComprador(),
                            r.cantidad(),
                            r.estado(),
                            r.creadaEn(),
                            r.actualizadaEn(),
                            r.respondidaEn(),
                            r.idJugador(),
                            r.nombre(),
                            r.pila(),
                            r.nombreVisible(),
                            r.posicion(),
                            r.fotoJugador(),
                            r.idEquipo(),
                            r.nombreEquipo(),
                            r.fotoEquipo(),
                            r.estadoJugador(),
                            r.cansancio(),
                            r.valorActual(),
                            r.idUsuarioDuenoActual(),
                            r.nicknameDuenoActual(),
                            r.nicknameComprador(),
                            r.fotoUsuarioComprador(),
                            l == null ? null : l.probabilidadTitular(),
                            l == null ? null : l.motivoTitularidad(),
                            l == null ? null : l.idPartidoProbabilidad(),
                            l == null ? null : l.calculadoEnProbabilidad()
                    )
            );
        }
        return out;
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

    private long loadParticipantMoneyForUpdate(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
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

    private long readParticipantMoney(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
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

    private int countOwnedPlayers(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM liga_jugadores
                WHERE id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("total");
            }
        }
    }

    private LockedLeaguePlayer lockLeaguePlayer(Connection conn, Long idLiga, Long idLigaJugador) throws SQLException {
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

                return new LockedLeaguePlayer(
                        rs.getLong("id"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_usuario_dueno"),
                        rs.getLong("valor")
                );
            }
        }
    }

    private int sendPlayerToMarket(Connection conn, Long idLiga, Long idLigaJugador, Long idUsuarioDuenoActual) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?,
                    adquirido_en = NULL
                WHERE id = ?
                  AND id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, MARKET_USER_ID);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, idLiga);
            ps.setLong(4, idUsuarioDuenoActual);
            return ps.executeUpdate();
        }
    }

    private int transferPlayerToBuyer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioDuenoActual,
            Long idUsuarioComprador
    ) throws SQLException {
        String sql = """
                UPDATE liga_jugadores
                SET id_usuario_dueno = ?,
                    adquirido_en = NOW()
                WHERE id = ?
                  AND id_liga = ?
                  AND id_usuario_dueno = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuarioComprador);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, idLiga);
            ps.setLong(4, idUsuarioDuenoActual);
            return ps.executeUpdate();
        }
    }

    private PendingOffer lockPendingOfferByBuyer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioComprador
    ) throws SQLException {
        String sql = """
                SELECT id, cantidad
                FROM ofertas_jugador
                WHERE id_liga = ?
                  AND id_liga_jugador = ?
                  AND id_usuario_comprador = ?
                  AND estado = 'PENDIENTE'
                LIMIT 1
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, idUsuarioComprador);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new PendingOffer(
                        rs.getLong("id"),
                        rs.getLong("cantidad")
                );
            }
        }
    }

    private void insertOffer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioComprador,
            Long cantidad
    ) throws SQLException {
        String sql = """
                INSERT INTO ofertas_jugador (
                    id_liga,
                    id_liga_jugador,
                    id_usuario_comprador,
                    cantidad,
                    estado,
                    creada_en,
                    actualizada_en,
                    respondida_en
                )
                VALUES (?, ?, ?, ?, 'PENDIENTE', NOW(), NOW(), NULL)
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            ps.setLong(3, idUsuarioComprador);
            ps.setLong(4, cantidad);
            ps.executeUpdate();
        }
    }

    private void updateOfferAmount(Connection conn, Long idOferta, Long cantidad) throws SQLException {
        String sql = """
                UPDATE ofertas_jugador
                SET cantidad = ?,
                    actualizada_en = NOW()
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, cantidad);
            ps.setLong(2, idOferta);
            ps.executeUpdate();
        }
    }

    private LockedOffer lockOfferForAction(Connection conn, Long idLiga, Long idOferta) throws SQLException {
        String sql = """
                SELECT oj.id,
                       oj.id_liga,
                       oj.id_liga_jugador,
                       oj.id_usuario_comprador,
                       oj.cantidad,
                       oj.estado,
                       lj.id_usuario_dueno AS id_usuario_dueno_actual
                FROM ofertas_jugador oj
                INNER JOIN liga_jugadores lj ON lj.id = oj.id_liga_jugador
                WHERE oj.id = ?
                  AND oj.id_liga = ?
                FOR UPDATE
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idOferta);
            ps.setLong(2, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return new LockedOffer(
                        rs.getLong("id"),
                        rs.getLong("id_liga"),
                        rs.getLong("id_liga_jugador"),
                        rs.getLong("id_usuario_comprador"),
                        rs.getLong("cantidad"),
                        rs.getString("estado"),
                        rs.getLong("id_usuario_dueno_actual")
                );
            }
        }
    }

    private void updateOfferState(Connection conn, Long idOferta, String estado, boolean setRespondedAt) throws SQLException {
        String sql = """
                UPDATE ofertas_jugador
                SET estado = ?,
                    actualizada_en = NOW(),
                    respondida_en = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, estado);

            if (setRespondedAt) {
                ps.setTimestamp(2, Timestamp.from(Instant.now()));
            } else {
                ps.setNull(2, Types.TIMESTAMP);
            }

            ps.setLong(3, idOferta);
            ps.executeUpdate();
        }
    }

    private void refundAndClosePendingOffersForPlayer(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long excludedOfferId,
            String finalState
    ) throws SQLException {
        StringBuilder sql = new StringBuilder("""
                SELECT id, id_usuario_comprador, cantidad
                FROM ofertas_jugador
                WHERE id_liga = ?
                  AND id_liga_jugador = ?
                  AND estado = 'PENDIENTE'
                """);

        if (excludedOfferId != null) {
            sql.append(" AND id <> ?");
        }

        sql.append(" FOR UPDATE");

        List<PendingOfferRefund> refunds = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLigaJugador);
            if (excludedOfferId != null) {
                ps.setLong(3, excludedOfferId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    refunds.add(new PendingOfferRefund(
                            rs.getLong("id"),
                            rs.getLong("id_usuario_comprador"),
                            rs.getLong("cantidad")
                    ));
                }
            }
        }

        for (PendingOfferRefund refund : refunds) {
            addMoneyToParticipant(conn, idLiga, refund.idUsuarioComprador(), refund.cantidad());
            updateOfferState(conn, refund.idOferta(), finalState, true);
        }
    }

    private String buildPlayerDisplayName(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        if (nombre != null && !nombre.isBlank()) {
            return nombre;
        }
        return null;
    }

    private LeagueOfferNotificationService.OfferNotificationPayload loadOfferNotificationPayload(
            Connection conn,
            Long idLiga,
            Long idLigaJugador,
            Long idOferta,
            Long idUsuarioComprador,
            Long idUsuarioVendedor,
            Long precio
    ) throws SQLException {
        String sql = """
                SELECT j.nombre AS jugador_nombre,
                       j.pila AS jugador_pila,
                       uc.nickname AS comprador_nombre,
                       uv.nickname AS vendedor_nombre
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                LEFT JOIN usuarios uc ON uc.id = ?
                LEFT JOIN usuarios uv ON uv.id = ?
                WHERE lj.id = ?
                  AND lj.id_liga = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuarioComprador);
            ps.setLong(2, idUsuarioVendedor);
            ps.setLong(3, idLigaJugador);
            ps.setLong(4, idLiga);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("No se pudo cargar el contexto de notificación de oferta");
                }

                String jugadorNombre = buildOfferPlayerName(
                        rs.getString("jugador_nombre"),
                        rs.getString("jugador_pila"),
                        idLigaJugador
                );
                String compradorNombre = buildUserDisplayName(rs.getString("comprador_nombre"), idUsuarioComprador);
                String vendedorNombre = buildUserDisplayName(rs.getString("vendedor_nombre"), idUsuarioVendedor);

                return new LeagueOfferNotificationService.OfferNotificationPayload(
                        idOferta,
                        idLiga,
                        idLigaJugador,
                        idUsuarioComprador,
                        idUsuarioVendedor,
                        compradorNombre,
                        vendedorNombre,
                        jugadorNombre,
                        precio
                );
            }
        }
    }

    private String buildOfferPlayerName(String nombre, String pila, Long idLigaJugador) {
        if (nombre != null && !nombre.isBlank()) {
            return nombre;
        }
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        return "Jugador " + idLigaJugador;
    }

    private String buildUserDisplayName(String nickname, Long idUsuario) {
        if (nickname != null && !nickname.isBlank()) {
            return nickname;
        }
        return "Usuario " + idUsuario;
    }

    private record LockedLeaguePlayer(
            Long idLigaJugador,
            Long idLiga,
            Long idUsuarioDueno,
            Long valor
    ) {
    }

    private record PendingOffer(
            Long idOferta,
            Long cantidad
    ) {
    }

    private record LockedOffer(
            Long idOferta,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioComprador,
            Long cantidad,
            String estado,
            Long idUsuarioDuenoActual
    ) {
    }

    private record PendingOfferRefund(
            Long idOferta,
            Long idUsuarioComprador,
            Long cantidad
    ) {
    }

    private static String formatMoney(long amount) {
        if (amount >= 1_000_000_000L) {
            long b = amount / 1_000_000_000L;
            long rem = (amount % 1_000_000_000L) / 1_000_000L;
            return rem > 0 ? b + "." + rem + "B" : b + "B";
        }
        if (amount >= 1_000_000L) {
            long m = amount / 1_000_000L;
            long rem = (amount % 1_000_000L) / 100_000L;
            return rem > 0 ? m + "." + rem + "M" : m + "M";
        }
        if (amount >= 1_000L) {
            return (amount / 1_000L) + "K";
        }
        return String.valueOf(amount);
    }
}