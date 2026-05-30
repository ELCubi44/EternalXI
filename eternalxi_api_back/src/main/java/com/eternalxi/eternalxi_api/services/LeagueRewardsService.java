package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.rewards.CardEffectType;
import com.eternalxi.eternalxi_api.dto.rewards.CardRarity;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardParticipantTargetsResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardRedeemRequest;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardRedeemResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardTargetResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCardValidTargetsResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCoachRouletteItemResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueCoachRouletteSpinResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeaguePackOpenResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueRewardEventType;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueRewardEventResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueRewardsSummaryResponse;
import com.eternalxi.eternalxi_api.dto.rewards.LeagueUserCardResponse;
import com.eternalxi.eternalxi_api.dto.rewards.RewardPackType;
import com.eternalxi.eternalxi_api.dto.rewards.UserLeagueCardStatus;
import com.eternalxi.eternalxi_api.exception.LeagueRewardConflictException;
import com.eternalxi.eternalxi_api.exception.LeagueRewardForbiddenException;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import com.eternalxi.eternalxi_api.services.rewards.RewardPackCatalog;
import com.eternalxi.eternalxi_api.services.rewards.RewardPackCatalog.PackDefinition;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Recompensas de liga: puntos globales, sobres, cartas, ruleta de entrenador y auditoría.
 * <p>
 * Deuda técnica: el {@code idUsuario} llega desde el cliente; cuando exista autenticación real,
 * sustituir por el usuario autenticado y no confiar en el parámetro.
 * </p>
 * <p>
 * Transacciones: este proyecto usa {@link DBConnection} (DriverManager); las transacciones se
 * gestionan manualmente con {@code setAutoCommit(false)} (no hay {@code @Transactional} efectivo).
 * </p>
 */
@Service
public class LeagueRewardsService {

    private static final long MARKET_USER_ID = 1L;
    private static final ObjectMapper JSON = new ObjectMapper();
    private static final String ASSET_PLAYER_URL = "/api/v1/assets/players/";
    private static final String ASSET_TEAM_URL = "/api/v1/assets/teams/";

    private final LeagueTradeService leagueTradeService;
    private final LeagueLineupService leagueLineupService;
    private final LeaguePlayerMarketValueService leaguePlayerMarketValueService;
    private final LeagueActivityService leagueActivityService;
    private final AccountProgressService accountProgressService;

    public LeagueRewardsService(
            LeagueTradeService leagueTradeService,
            LeagueLineupService leagueLineupService,
            LeaguePlayerMarketValueService leaguePlayerMarketValueService,
            LeagueActivityService leagueActivityService,
            AccountProgressService accountProgressService
    ) {
        this.leagueTradeService = leagueTradeService;
        this.leagueLineupService = leagueLineupService;
        this.leaguePlayerMarketValueService = leaguePlayerMarketValueService;
        this.leagueActivityService = leagueActivityService;
        this.accountProgressService = accountProgressService;
    }

    public LeagueRewardsSummaryResponse getSummary(Long idLiga, Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureUsuario(conn, idUsuario);
            ParticipantRow p = loadParticipantOrForbidden(conn, idLiga, idUsuario);
            leagueLineupService.recalculateParticipantPoints(conn, idLiga);
            cleanupExpired(conn, idLiga);

            boolean ruletaUsada = loadRouletteUsed(conn, p.idLigaParticipante());
            LeagueCoachRouletteItemResponse coach = loadCoachSummaryForRewards(conn, p.idLigaParticipante());
            int[] counts = countCardsByState(conn, p.idLigaParticipante());

            return new LeagueRewardsSummaryResponse(
                    idLiga,
                    p.idLigaParticipante(),
                    p.puntosRecompensa(),
                    p.dinero(),
                    ruletaUsada,
                    RewardPackCatalog.COSTE_RULETA_ENTRENADOR,
                    coach,
                    counts[0],
                    counts[1],
                    RewardPackCatalog.catalogEntries()
            );
        }
    }

    public LeaguePackOpenResponse openPack(Long idLiga, RewardPackType packType, Long idUsuario) throws SQLException {
        PackDefinition def = RewardPackCatalog.get(packType);
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ensureUsuario(conn, idUsuario);
                loadParticipantOrForbidden(conn, idLiga, idUsuario);
                cleanupExpired(conn, idLiga);

                int coste = def.costePuntos();
                long[] locked = lockParticipantForRewardUpdate(conn, idLiga, idUsuario);
                long idLigaPart = locked[0];
                if (locked[1] < coste) {
                    throw new LeagueRewardConflictException("Puntos de recompensa insuficientes");
                }
                deductParticipantRewardPoints(conn, idLigaPart, coste);
                long puntosRest = locked[1] - coste;

                lockLeagueCoachRows(conn, idLiga);

                long budget = RewardPackCatalog.rollBudget(def);
                addMoneyParticipantById(conn, idLigaPart, budget);

                CardRarity rarity = RewardPackCatalog.rollRarity(def);
                Long idDef = pickRandomDefinitionId(conn, rarity);
                if (idDef == null) {
                    throw new SQLException("No hay definiciones de carta activas para la rareza " + rarity);
                }

                long idCarta = insertParticipantCard(conn, idLigaPart, idDef, null);
                long nuevoDinero = lockParticipantRow(conn, idLigaPart);

                insertEvent(conn, idLiga, idLigaPart, idUsuario,
                        LeagueRewardEventType.PACK_OPENED, idCarta, null, null,
                        packType.name(), (long) coste, "Apertura de sobre " + packType.name(), null);
                insertEvent(conn, idLiga, idLigaPart, idUsuario,
                        LeagueRewardEventType.BUDGET_GRANTED, idCarta, null, null,
                        packType.name(), budget, "Premio presupuesto sobre", null);
                insertEvent(conn, idLiga, idLigaPart, idUsuario,
                        LeagueRewardEventType.CARD_OBTAINED, idCarta, null, null,
                        packType.name(), null, "Carta obtenida por sobre", null);

                LeagueUserCardResponse cardDto = loadUserCard(conn, idCarta);

                String actNick = loadNickname(conn, idUsuario);
                String packNombre = def.nombre();
                String cartaNombre = cardDto.nombre() != null ? cardDto.nombre() : cardDto.codigo();
                leagueActivityService.recordActivity(
                        conn, idLiga, idUsuario, actNick,
                        "PACK_OPENED",
                        actNick + " abrió un " + packNombre + " y recibió " + cartaNombre + ".",
                        idLigaPart, null, null, idCarta, null, budget, null
                );

                accountProgressService.onPackOpened(conn, idUsuario, idLiga, idLigaPart);

                conn.commit();
                return new LeaguePackOpenResponse(packType.name(), coste, puntosRest, budget, nuevoDinero, cardDto);
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof LeagueRewardConflictException c) throw c;
                if (e instanceof LeagueRewardForbiddenException f) throw f;
                if (e instanceof SQLException s) throw s;
                throw new SQLException(e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public LeagueCoachRouletteSpinResponse spinCoachRoulette(Long idLiga, Long idUsuario) throws SQLException {
        final int coste = RewardPackCatalog.COSTE_RULETA_ENTRENADOR;
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ensureUsuario(conn, idUsuario);
                ParticipantRow part = loadParticipantOrForbidden(conn, idLiga, idUsuario);
                cleanupExpired(conn, idLiga);

                RouletteRow rr = lockOrInsertRoulette(conn, part.idLigaParticipante());
                LeagueCoachRouletteItemResponse actual = loadCoachSummaryForRewards(conn, part.idLigaParticipante());
                if (rr.usado()) {
                    conn.commit();
                    return new LeagueCoachRouletteSpinResponse(true, actual, List.of(), coste, null);
                }

                long[] locked = lockParticipantForRewardUpdate(conn, idLiga, idUsuario);
                long idLigaPart = locked[0];
                if (locked[1] < coste) {
                    throw new LeagueRewardConflictException("Puntos insuficientes para usar la ruleta de entrenador.");
                }
                deductParticipantRewardPoints(conn, idLigaPart, coste);
                long puntosRest = locked[1] - coste;

                lockLeagueCoachRows(conn, idLiga);

                List<CoachPickRow> libres = loadFreeCoachesForLeague(conn, idLiga);
                if (libres.isEmpty()) {
                    throw new LeagueRewardConflictException("No hay entrenadores disponibles en esta liga");
                }

                List<LeagueCoachRouletteItemResponse> items = libres.stream().map(this::mapCoachPick).toList();
                int idx = ThreadLocalRandom.current().nextInt(libres.size());
                CoachPickRow won = libres.get(idx);

                insertCoachInventory(conn, idLigaPart, won.idEntrenador());
                markRouletteUsed(conn, rr.id(), won.idEntrenador());

                insertEvent(conn, idLiga, idLigaPart, idUsuario,
                        LeagueRewardEventType.COACH_ROULETTE_SPIN, null, null, null,
                        null, (long) coste,
                        "Ruleta entrenador: " + won.nombre() + " (id=" + won.idEntrenador() + ")", null);

                String actNick = loadNickname(conn, idUsuario);
                leagueActivityService.recordActivity(
                        conn, idLiga, idUsuario, actNick,
                        "COACH_ROULETTE",
                        actNick + " usó la ruleta de entrenador y obtuvo a " + won.nombre() + ".",
                        idLigaPart, null, null, null, won.idEntrenador(), (long) coste, null
                );

                accountProgressService.onCoachRoulette(conn, idUsuario, idLiga);

                conn.commit();
                return new LeagueCoachRouletteSpinResponse(false, mapCoachPick(won), items, coste, puntosRest);
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof LeagueRewardConflictException c) throw c;
                if (e instanceof LeagueRewardForbiddenException f) throw f;
                if (e instanceof SQLException s) throw s;
                throw new SQLException(e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public List<LeagueUserCardResponse> listCards(Long idLiga, Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureUsuario(conn, idUsuario);
            ParticipantRow p = loadParticipantOrForbidden(conn, idLiga, idUsuario);
            return loadCardsForParticipant(conn, p.idLigaParticipante());
        }
    }

    public LeagueCardValidTargetsResponse validTargets(Long idLiga, Long idCarta, Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureUsuario(conn, idUsuario);
            ParticipantRow p = loadParticipantOrForbidden(conn, idLiga, idUsuario);
            cleanupExpired(conn, idLiga);

            CardRow card = loadCardOwned(conn, idCarta, p.idLigaParticipante());
            if (!UserLeagueCardStatus.AVAILABLE.name().equals(card.estado())) {
                throw new LeagueRewardConflictException("La carta no está disponible");
            }
            CardEffectType effect = CardEffectType.fromDb(card.tipoEfecto());
            JsonNode params = parseParams(card.parametrosJson());

            return switch (effect) {
                case SELL_PLAYER_BONUS -> sellTargets(conn, idLiga, idUsuario, params);
                case DIRECT_CLAUSE -> clauseTargets(conn, idLiga, idUsuario, p.idLigaParticipante(), params);
                case PROTECT_PLAYER -> protectTargets(conn, idLiga, idUsuario, p.idLigaParticipante(), params);
                case ADD_LEAGUE_POINTS -> leaguePointsTargets(effect, params);
                case TEMPORARY_VALUE_RECOVERY -> valueRecoveryTargets(conn, idLiga, idUsuario, params);
            };
        }
    }

    public LeagueCardRedeemResponse redeem(
            Long idLiga,
            Long idCarta,
            Long idUsuario,
            LeagueCardRedeemRequest body
    ) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ensureUsuario(conn, idUsuario);
                ParticipantRow part = loadParticipantOrForbidden(conn, idLiga, idUsuario);
                cleanupExpired(conn, idLiga);

                CardRow card = loadCardForUpdate(conn, idCarta, part.idLigaParticipante());
                if (!UserLeagueCardStatus.AVAILABLE.name().equals(card.estado())) {
                    throw new LeagueRewardConflictException("La carta ya fue usada o no está disponible");
                }

                CardEffectType effect = CardEffectType.fromDb(card.tipoEfecto());
                JsonNode params = parseParams(card.parametrosJson());
                Long targetLj = body == null ? null : body.idLigaJugadorObjetivo();

                LeagueCardRedeemResponse out = switch (effect) {
                    case SELL_PLAYER_BONUS -> redeemSell(conn, idLiga, idUsuario, part, card, params, targetLj);
                    case DIRECT_CLAUSE -> redeemClause(conn, idLiga, idUsuario, part, card, params, targetLj);
                    case PROTECT_PLAYER -> redeemProtect(conn, idLiga, idUsuario, part, card, params, targetLj);
                    case ADD_LEAGUE_POINTS -> redeemLeaguePoints(conn, idLiga, idUsuario, part, card, params);
                    case TEMPORARY_VALUE_RECOVERY -> redeemValueRecovery(conn, idLiga, idUsuario, part, card, params, targetLj);
                };

                markCardUsed(conn, idCarta);
                insertEvent(
                        conn,
                        idLiga,
                        part.idLigaParticipante(),
                        idUsuario,
                        LeagueRewardEventType.CARD_REDEEMED,
                        idCarta,
                        targetLj,
                        null,
                        null,
                        null,
                        "Canje carta " + card.codigo(),
                        null
                );

                String actNick = loadNickname(conn, idUsuario);
                String actMsg = buildActivityMessage(actNick, card, effect, out);
                leagueActivityService.recordActivity(
                        conn,
                        idLiga,
                        idUsuario,
                        actNick,
                        "CARD_REDEEMED",
                        actMsg,
                        part.idLigaParticipante(),
                        null,
                        targetLj,
                        idCarta,
                        null,
                        null,
                        null
                );

                conn.commit();
                return out;
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof LeagueRewardConflictException c) {
                    throw c;
                }
                if (e instanceof LeagueRewardForbiddenException f) {
                    throw f;
                }
                if (e instanceof SQLException s) {
                    throw s;
                }
                throw new SQLException(e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    public List<LeagueRewardEventResponse> listEvents(Long idLiga, Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureUsuario(conn, idUsuario);
            loadParticipantOrForbidden(conn, idLiga, idUsuario);
            String sql = """
                    SELECT id, tipo, id_carta, id_liga_jugador, id_liga_participante_objetivo, pack_type, cantidad, descripcion, creado_en
                    FROM liga_recompensa_eventos
                    WHERE id_liga = ?
                    ORDER BY creado_en DESC, id DESC
                    LIMIT 50
                    """;
            List<LeagueRewardEventResponse> list = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idLiga);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp ts = rs.getTimestamp("creado_en");
                        list.add(new LeagueRewardEventResponse(
                                rs.getLong("id"),
                                rs.getString("tipo"),
                                rs.getObject("id_carta", Long.class),
                                rs.getObject("id_liga_jugador", Long.class),
                                rs.getObject("id_liga_participante_objetivo", Long.class),
                                rs.getString("pack_type"),
                                rs.getObject("cantidad", Long.class),
                                rs.getString("descripcion"),
                                ts == null ? null : ts.toInstant()
                        ));
                    }
                }
            }
            return list;
        }
    }

    // --- redeem per effect ---

    private LeagueCardRedeemResponse redeemSell(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            ParticipantRow part,
            CardRow card,
            JsonNode params,
            Long idLj
    ) throws SQLException {
        if (idLj == null) {
            throw new IllegalArgumentException("Esta carta requiere idLigaJugadorObjetivo");
        }
        double mult = params.path("sellMultiplier").asDouble(1.0d);
        if (mult <= 0) {
            throw new IllegalArgumentException("Parámetros de carta inválidos");
        }
        LockedLj lj = lockLeaguePlayerRow(conn, idLiga, idLj);
        if (!Objects.equals(lj.idUsuarioDueno(), idUsuario)) {
            throw new LeagueRewardForbiddenException("El jugador no te pertenece");
        }
        if (lj.idUsuarioDueno() == MARKET_USER_ID) {
            throw new IllegalArgumentException("Jugador del mercado no válido para esta operación");
        }
        String nombre = lj.nombreJugador();
        double pctMod = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLj);
        long valorEfectivo = leaguePlayerMarketValueService.effectiveValueFromBase(lj.valor(), pctMod);
        long nuevo = leagueTradeService.sellLeaguePlayerToMarketWithinTransaction(conn, idLiga, idLj, idUsuario, mult);
        long recibido = (long) Math.floor(valorEfectivo * mult);
        insertEvent(
                conn,
                idLiga,
                part.idLigaParticipante(),
                idUsuario,
                LeagueRewardEventType.PLAYER_SOLD_WITH_CARD,
                card.idCarta(),
                idLj,
                null,
                null,
                recibido,
                "Venta con carta " + card.codigo(),
                null
        );
        accountProgressService.onPlayerSold(conn, idUsuario, idLiga, recibido);
        return LeagueCardRedeemResponse.sell(
                idLj,
                nombre,
                lj.valor(),
                valorEfectivo,
                pctMod > 0d ? pctMod : null,
                mult,
                recibido,
                nuevo
        );
    }

    private LeagueCardRedeemResponse redeemClause(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            ParticipantRow part,
            CardRow card,
            JsonNode params,
            Long idLj
    ) throws SQLException {
        if (idLj == null) {
            throw new IllegalArgumentException("Esta carta requiere idLigaJugadorObjetivo");
        }
        double buyerM = params.path("buyerMultiplier").asDouble();
        double ownerM = params.path("ownerCompensationMultiplier").asDouble(1.0d);
        JsonNode mv = params.get("maxPlayerValue");
        Long maxV = mv == null || mv.isNull() ? null : mv.asLong();

        LockedLj lj = lockLeaguePlayerRow(conn, idLiga, idLj);
        if (isPlayerProtected(conn, idLj)) {
            throw new LeagueRewardConflictException("El jugador está protegido frente a cláusulas");
        }
        if (lj.idUsuarioDueno() == MARKET_USER_ID) {
            throw new IllegalArgumentException("No se puede usar cláusula sobre el mercado");
        }
        if (Objects.equals(lj.idUsuarioDueno(), idUsuario)) {
            throw new IllegalArgumentException("No puedes usar cláusula sobre tu propio jugador");
        }
        long valorBase = lj.valor();
        long valorEfectivo = leaguePlayerMarketValueService.effectiveValue(conn, idLiga, idLj, valorBase);
        if (maxV != null && valorEfectivo > maxV) {
            throw new LeagueRewardConflictException("El valor del jugador supera el máximo de la carta");
        }

        String nickPrev = loadNickname(conn, lj.idUsuarioDueno());
        String nickNew = loadNickname(conn, idUsuario);
        double pctAct = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLj);

        LeagueTradeService.DirectClauseResult r = leagueTradeService.executeDirectClauseWithinTransaction(
                conn,
                idLiga,
                idLj,
                idUsuario,
                buyerM,
                ownerM,
                maxV
        );

        insertEvent(
                conn,
                idLiga,
                part.idLigaParticipante(),
                idUsuario,
                LeagueRewardEventType.DIRECT_CLAUSE_EXECUTED,
                card.idCarta(),
                idLj,
                null,
                null,
                r.buyerPaid(),
                "Cláusula directa",
                null
        );

        accountProgressService.onClauseExecuted(conn, idUsuario, idLiga, valorEfectivo);

        return LeagueCardRedeemResponse.clause(
                idLj,
                lj.nombreJugador(),
                lj.idUsuarioDueno(),
                nickPrev,
                idUsuario,
                nickNew,
                r.valorBaseMercado(),
                r.valorMercadoEfectivo(),
                pctAct > 0d ? pctAct : null,
                r.buyerPaid(),
                r.ownerReceived(),
                r.buyerNewMoney(),
                r.ownerNewMoney()
        );
    }

    private LeagueCardRedeemResponse redeemProtect(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            ParticipantRow part,
            CardRow card,
            JsonNode params,
            Long idLj
    ) throws SQLException {
        if (idLj == null) {
            throw new IllegalArgumentException("Esta carta requiere idLigaJugadorObjetivo");
        }
        boolean season = params.path("seasonLong").asBoolean(false);
        Integer rounds = params.get("rounds").isNull() ? null : params.get("rounds").asInt();

        String nombre = requireOwnedLeaguePlayerName(conn, idLiga, idLj, idUsuario);
        List<JornadaLite> jr = loadJornadas(conn, idLiga);
        ProtectionEval existing = loadActiveProtection(conn, idLj);
        int newTier = newProtectionTier(season, rounds);
        if (existing != null && protectionTierValue(existing, jr) >= newTier) {
            throw new LeagueRewardConflictException("El jugador ya tiene una protección igual o superior");
        }

        Long jIni = firstPendingJornadaId(jr);
        if (jIni == null) {
            jIni = lastJornadaId(jr);
        }
        Long jFin;
        if (season) {
            jFin = null;
        } else {
            int r = rounds == null ? 1 : Math.max(1, rounds);
            jFin = jornadaFinDesde(jr, jIni, r);
        }

        if (existing != null) {
            deactivateProtection(conn, existing.id());
        }

        long idProt = insertProtection(conn, idLiga, idLj, part.idLigaParticipante(), card.idCarta(), jIni, jFin, season);
        insertEvent(
                conn,
                idLiga,
                part.idLigaParticipante(),
                idUsuario,
                LeagueRewardEventType.PLAYER_PROTECTION_APPLIED,
                card.idCarta(),
                idLj,
                null,
                null,
                idProt,
                "Protección aplicada",
                null
        );

        accountProgressService.onProtectionApplied(conn, idUsuario, idLiga, part.idLigaParticipante());

        return LeagueCardRedeemResponse.protect(idLj, nombre, jIni, jFin, season);
    }

    private LeagueCardRedeemResponse redeemLeaguePoints(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            ParticipantRow part,
            CardRow card,
            JsonNode params
    ) throws SQLException {
        int pts = params.path("points").asInt(0);
        if (pts <= 0) {
            throw new IllegalArgumentException("Parámetros de carta inválidos");
        }
        insertBonusPoints(conn, part.idLigaParticipante(), card.idCarta(), pts, "Carta " + card.codigo());
        leagueLineupService.recalculateParticipantPoints(conn, idLiga);
        int fantasy = loadFantasyPoints(conn, part.idLigaParticipante());
        int bonus = sumBonusPoints(conn, part.idLigaParticipante());
        insertEvent(
                conn,
                idLiga,
                part.idLigaParticipante(),
                idUsuario,
                LeagueRewardEventType.LEAGUE_POINTS_BONUS_APPLIED,
                card.idCarta(),
                null,
                null,
                null,
                (long) pts,
                "Bonus puntos liga",
                null
        );
        return LeagueCardRedeemResponse.leaguePoints(pts, bonus, fantasy, fantasy + bonus);
    }

    private LeagueCardRedeemResponse redeemValueRecovery(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            ParticipantRow part,
            CardRow card,
            JsonNode params,
            Long idLj
    ) throws SQLException {
        if (idLj == null) {
            throw new IllegalArgumentException("Esta carta requiere idLigaJugadorObjetivo");
        }
        double pct = params.path("percentage").asDouble(0d);
        if (pct <= 0) {
            throw new IllegalArgumentException("Parámetros de carta inválidos");
        }

        LockedLj lj = lockLeaguePlayerRow(conn, idLiga, idLj);
        if (!Objects.equals(lj.idUsuarioDueno(), idUsuario)) {
            throw new LeagueRewardForbiddenException("El jugador no te pertenece");
        }
        if (lj.valor() >= lj.valorAnterior()) {
            throw new LeagueRewardConflictException("El jugador no está bajando de valor");
        }
        ModifierActive mod = loadActiveValueModifier(conn, idLj);
        if (mod != null && mod.porcentaje() >= pct) {
            throw new LeagueRewardConflictException("Ya existe un modificador de valor activo igual o superior");
        }
        if (mod != null) {
            deactivateValueModifier(conn, mod.id());
        }

        List<JornadaLite> jr = loadJornadas(conn, idLiga);
        Long jExp = firstPendingJornadaId(jr);
        if (jExp == null) {
            jExp = lastJornadaId(jr);
        }

        long valorTemp = (long) Math.floor(lj.valor() * (1.0d + pct));
        long idMod = insertValueModifier(conn, idLiga, idLj, part.idLigaParticipante(), card.idCarta(), pct, jExp);

        insertEvent(
                conn,
                idLiga,
                part.idLigaParticipante(),
                idUsuario,
                LeagueRewardEventType.VALUE_RECOVERY_APPLIED,
                card.idCarta(),
                idLj,
                null,
                null,
                idMod,
                "Recuperación valor mercado",
                null
        );

        return LeagueCardRedeemResponse.valueRecovery(
                idLj,
                lj.nombreJugador(),
                lj.valor(),
                lj.valorAnterior(),
                pct,
                valorTemp,
                jExp,
                valorTemp,
                pct
        );
    }

    private String buildActivityMessage(String nick, CardRow card, CardEffectType effect, LeagueCardRedeemResponse out) {
        String cartaNombre = card.nombre() != null ? card.nombre() : card.codigo();
        return switch (effect) {
            case SELL_PLAYER_BONUS -> nick + " usó " + cartaNombre + " y vendió a " +
                    out.nombreJugador() + " por " + formatMoney(out.cantidadRecibida()) + ".";
            case DIRECT_CLAUSE -> nick + " usó " + cartaNombre + " y fichó a " +
                    out.nombreJugador() + " de " + out.nicknamePropietarioAnterior() + " pagando " + formatMoney(out.pagadoPorAtacante()) + ".";
            case PROTECT_PLAYER -> nick + " protegió a " + out.nombreJugador() +
                    (out.idJornadaFinProteccion() != null ? " hasta la jornada " + out.idJornadaFinProteccion() : " toda la temporada") + ".";
            case ADD_LEAGUE_POINTS -> nick + " usó " + cartaNombre + " y sumó +" +
                    out.puntosAnadidos() + " puntos.";
            case TEMPORARY_VALUE_RECOVERY -> nick + " aplicó recuperación de valor a " +
                    out.nombreJugador() + ".";
        };
    }

    private static String formatMoney(Long amount) {
        if (amount == null) return "0";
        return String.format("%,d", amount).replace(',', '.');
    }

    // --- helpers ---

    private record ParticipantRow(long idLigaParticipante, long idUsuario, long dinero, long puntosRecompensa) {}

    private record CardRow(
            long idCarta,
            long idDefinicion,
            String codigo,
            String nombre,
            String rareza,
            String tipoEfecto,
            String descripcion,
            String parametrosJson,
            String estado
    ) {}

    private record LockedLj(long id, long idUsuarioDueno, long valor, long valorAnterior, String nombreJugador) {}

    private record JornadaLite(long id, int numero, String estado) {}

    private static Map<Long, Long> jornadaNumeroPorId(List<JornadaLite> jr) {
        Map<Long, Long> m = new HashMap<>();
        for (JornadaLite j : jr) {
            m.put(j.id(), (long) j.numero());
        }
        return m;
    }

    private record ProtectionEval(long id, boolean season, Long jIni, Long jFin) {}

    private record ModifierActive(long id, double porcentaje) {}

    private record RouletteRow(long id, boolean usado) {}

    private record CoachPickRow(long idEntrenador, String nombre, String pila, String foto, int idEquipo, String nombreEquipo, String fotoEquipo, int bonusPuntos) {}

    private void ensureUsuario(Connection conn, Long idUsuario) throws SQLException {
        String sql = "SELECT 1 FROM usuarios WHERE id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Usuario no encontrado");
                }
            }
        }
    }

    private ParticipantRow loadParticipantOrForbidden(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT id, dinero, puntos_recompensa
                FROM liga_participantes
                WHERE id_liga = ? AND id_usuario = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new LeagueRewardForbiddenException("No perteneces a esta liga");
                }
                return new ParticipantRow(rs.getLong("id"), idUsuario, rs.getLong("dinero"), rs.getLong("puntos_recompensa"));
            }
        }
    }

    private void cleanupExpired(Connection conn, Long idLiga) throws SQLException {
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        String sqlProt = """
                UPDATE liga_jugador_protecciones p
                INNER JOIN jornadas j ON j.id = p.id_jornada_fin
                SET p.activo = FALSE
                WHERE p.id_liga = ? AND p.activo = TRUE AND p.hasta_fin_temporada = FALSE
                  AND p.id_jornada_fin IS NOT NULL AND j.estado = 'FINALIZADA'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sqlProt)) {
            ps.setLong(1, idLiga);
            ps.executeUpdate();
        }
        String sqlSeason = """
                UPDATE liga_jugador_protecciones p
                INNER JOIN ligas l ON l.id = p.id_liga
                SET p.activo = FALSE
                WHERE p.activo = TRUE AND p.hasta_fin_temporada = TRUE AND l.cerrada_en IS NOT NULL
                """;
        try (PreparedStatement ps = conn.prepareStatement(sqlSeason)) {
            ps.executeUpdate();
        }
    }

    private void addMoneyParticipantById(Connection conn, long idLigaParticipante, long delta) throws SQLException {
        String sql = "UPDATE liga_participantes SET dinero = dinero + ? WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, delta);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private long lockParticipantRow(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = "SELECT dinero FROM liga_participantes WHERE id = ? FOR UPDATE";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong("dinero");
            }
        }
    }

    /**
     * Bloquea la fila de participante y devuelve [idLigaParticipante, puntosRecompensa].
     */
    private long[] lockParticipantForRewardUpdate(Connection conn, Long idLiga, Long idUsuario) throws SQLException {
        String sql = """
                SELECT id, puntos_recompensa
                FROM liga_participantes
                WHERE id_liga = ? AND id_usuario = ?
                FOR UPDATE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new LeagueRewardForbiddenException("No perteneces a esta liga");
                }
                return new long[]{rs.getLong("id"), rs.getLong("puntos_recompensa")};
            }
        }
    }

    private void deductParticipantRewardPoints(Connection conn, long idLigaParticipante, int cantidad) throws SQLException {
        String sql = "UPDATE liga_participantes SET puntos_recompensa = puntos_recompensa - ? WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, cantidad);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private void addParticipantRewardPoints(Connection conn, long idLigaParticipante, int cantidad) throws SQLException {
        String sql = "UPDATE liga_participantes SET puntos_recompensa = puntos_recompensa + ? WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, cantidad);
            ps.setLong(2, idLigaParticipante);
            ps.executeUpdate();
        }
    }

    private void lockAllLeagueParticipantsForUpdate(Connection conn, Long idLiga) throws SQLException {
        String sql = "SELECT id FROM liga_participantes WHERE id_liga = ? ORDER BY id FOR UPDATE";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    // consumir filas para materializar bloqueos
                }
            }
        }
    }

    private Long pickRandomDefinitionId(Connection conn, CardRarity rarity) throws SQLException {
        String sql = """
                SELECT id FROM definiciones_carta
                WHERE rareza = ? AND activo = TRUE
                ORDER BY RAND() LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, rarity.name());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    private long insertParticipantCard(Connection conn, long idLigaParticipante, long idDef, String metadata) throws SQLException {
        String sql = """
                INSERT INTO liga_participante_cartas (id_liga_participante, id_definicion_carta, estado, metadata_json)
                VALUES (?, ?, 'AVAILABLE', ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idDef);
            if (metadata == null) {
                ps.setNull(3, Types.LONGVARCHAR);
            } else {
                ps.setString(3, metadata);
            }
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getLong(1);
            }
        }
    }

    private void insertEvent(
            Connection conn,
            Long idLiga,
            Long idLigaParticipante,
            Long idUsuario,
            LeagueRewardEventType tipo,
            Long idCarta,
            Long idLigaJugador,
            Long idLigaParticipanteObjetivo,
            String packType,
            Long cantidad,
            String descripcion,
            String metadataJson
    ) throws SQLException {
        String sql = """
                INSERT INTO liga_recompensa_eventos (
                    id_liga, id_liga_participante, id_usuario, tipo, id_carta, id_liga_jugador,
                    id_liga_participante_objetivo, pack_type, cantidad, descripcion, metadata_json
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            setLongOrNull(ps, 2, idLigaParticipante);
            setLongOrNull(ps, 3, idUsuario);
            ps.setString(4, tipo.name());
            setLongOrNull(ps, 5, idCarta);
            setLongOrNull(ps, 6, idLigaJugador);
            setLongOrNull(ps, 7, idLigaParticipanteObjetivo);
            if (packType == null) {
                ps.setNull(8, Types.VARCHAR);
            } else {
                ps.setString(8, packType);
            }
            setLongOrNull(ps, 9, cantidad);
            ps.setString(10, descripcion);
            if (metadataJson == null) {
                ps.setNull(11, Types.LONGVARCHAR);
            } else {
                ps.setString(11, metadataJson);
            }
            ps.executeUpdate();
        }
    }

    private void setLongOrNull(PreparedStatement ps, int i, Long v) throws SQLException {
        if (v == null) {
            ps.setNull(i, Types.BIGINT);
        } else {
            ps.setLong(i, v);
        }
    }

    private void markCardUsed(Connection conn, long idCarta) throws SQLException {
        String sql = """
                UPDATE liga_participante_cartas
                SET estado = 'USED', usado_en = CURRENT_TIMESTAMP(3)
                WHERE id = ? AND estado = 'AVAILABLE'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idCarta);
            int u = ps.executeUpdate();
            if (u != 1) {
                throw new LeagueRewardConflictException("La carta no pudo marcarse como usada");
            }
        }
    }

    private CardRow loadCardOwned(Connection conn, long idCarta, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lpc.id, lpc.id_definicion_carta, dc.codigo, dc.nombre, dc.rareza, dc.tipo_efecto, dc.descripcion,
                       dc.parametros_json, lpc.estado
                FROM liga_participante_cartas lpc
                INNER JOIN definiciones_carta dc ON dc.id = lpc.id_definicion_carta
                WHERE lpc.id = ? AND lpc.id_liga_participante = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idCarta);
            ps.setLong(2, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Carta no encontrada");
                }
                return mapCard(rs);
            }
        }
    }

    private CardRow loadCardForUpdate(Connection conn, long idCarta, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lpc.id, lpc.id_definicion_carta, dc.codigo, dc.nombre, dc.rareza, dc.tipo_efecto, dc.descripcion,
                       dc.parametros_json, lpc.estado
                FROM liga_participante_cartas lpc
                INNER JOIN definiciones_carta dc ON dc.id = lpc.id_definicion_carta
                WHERE lpc.id = ? AND lpc.id_liga_participante = ?
                FOR UPDATE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idCarta);
            ps.setLong(2, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Carta no encontrada");
                }
                return mapCard(rs);
            }
        }
    }

    private CardRow mapCard(ResultSet rs) throws SQLException {
        return new CardRow(
                rs.getLong("id"),
                rs.getLong("id_definicion_carta"),
                rs.getString("codigo"),
                rs.getString("nombre"),
                rs.getString("rareza"),
                rs.getString("tipo_efecto"),
                rs.getString("descripcion"),
                rs.getString("parametros_json"),
                rs.getString("estado")
        );
    }

    private LeagueUserCardResponse loadUserCard(Connection conn, long idCarta) throws SQLException {
        String sql = """
                SELECT lpc.id, dc.id, dc.codigo, dc.nombre, dc.rareza, dc.tipo_efecto, dc.descripcion, dc.parametros_json,
                       lpc.estado, lpc.obtenido_en, lpc.usado_en
                FROM liga_participante_cartas lpc
                INNER JOIN definiciones_carta dc ON dc.id = lpc.id_definicion_carta
                WHERE lpc.id = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idCarta);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                Timestamp o = rs.getTimestamp("obtenido_en");
                Timestamp u = rs.getTimestamp("usado_en");
                return new LeagueUserCardResponse(
                        rs.getLong(1),
                        rs.getLong(2),
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        rs.getString("rareza"),
                        rs.getString("tipo_efecto"),
                        rs.getString("descripcion"),
                        rs.getString("parametros_json"),
                        rs.getString("estado"),
                        o == null ? null : o.toInstant(),
                        u == null ? null : u.toInstant()
                );
            }
        }
    }

    private List<LeagueUserCardResponse> loadCardsForParticipant(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT lpc.id, dc.id, dc.codigo, dc.nombre, dc.rareza, dc.tipo_efecto, dc.descripcion, dc.parametros_json,
                       lpc.estado, lpc.obtenido_en, lpc.usado_en
                FROM liga_participante_cartas lpc
                INNER JOIN definiciones_carta dc ON dc.id = lpc.id_definicion_carta
                WHERE lpc.id_liga_participante = ?
                ORDER BY lpc.obtenido_en DESC, lpc.id DESC
                """;
        List<LeagueUserCardResponse> out = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp o = rs.getTimestamp("obtenido_en");
                    Timestamp u = rs.getTimestamp("usado_en");
                    out.add(new LeagueUserCardResponse(
                            rs.getLong(1),
                            rs.getLong(2),
                            rs.getString("codigo"),
                            rs.getString("nombre"),
                            rs.getString("rareza"),
                            rs.getString("tipo_efecto"),
                            rs.getString("descripcion"),
                            rs.getString("parametros_json"),
                            rs.getString("estado"),
                            o == null ? null : o.toInstant(),
                            u == null ? null : u.toInstant()
                    ));
                }
            }
        }
        return out;
    }

    private int[] countCardsByState(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT estado, COUNT(*) c
                FROM liga_participante_cartas
                WHERE id_liga_participante = ?
                GROUP BY estado
                """;
        int avail = 0;
        int used = 0;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String e = rs.getString("estado");
                    int c = rs.getInt("c");
                    if ("AVAILABLE".equals(e)) {
                        avail = c;
                    } else if ("USED".equals(e)) {
                        used = c;
                    }
                }
            }
        }
        return new int[]{avail, used};
    }

    private boolean loadRouletteUsed(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = "SELECT usado FROM liga_participante_ruleta_entrenador WHERE id_liga_participante = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                return rs.getBoolean("usado");
            }
        }
    }

    private RouletteRow lockOrInsertRoulette(Connection conn, long idLigaParticipante) throws SQLException {
        String ins = """
                INSERT INTO liga_participante_ruleta_entrenador (id_liga_participante, usado)
                VALUES (?, FALSE)
                ON DUPLICATE KEY UPDATE id_liga_participante = id_liga_participante
                """;
        try (PreparedStatement ps = conn.prepareStatement(ins)) {
            ps.setLong(1, idLigaParticipante);
            ps.executeUpdate();
        }
        String sel = """
                SELECT id, usado FROM liga_participante_ruleta_entrenador
                WHERE id_liga_participante = ? FOR UPDATE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sel)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return new RouletteRow(rs.getLong("id"), rs.getBoolean("usado"));
            }
        }
    }

    private void markRouletteUsed(Connection conn, long idRouletteRow, long idEntrenador) throws SQLException {
        String sql = """
                UPDATE liga_participante_ruleta_entrenador
                SET usado = TRUE, usado_en = CURRENT_TIMESTAMP(3), id_entrenador_asignado = ?
                WHERE id = ? AND usado = FALSE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEntrenador);
            ps.setLong(2, idRouletteRow);
            int u = ps.executeUpdate();
            if (u != 1) {
                throw new LeagueRewardConflictException("La ruleta ya fue usada");
            }
        }
    }

    private void lockLeagueCoachRows(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT lpe.id
                FROM liga_participante_entrenador lpe
                INNER JOIN liga_participantes lp ON lp.id = lpe.id_liga_participante
                WHERE lp.id_liga = ?
                FOR UPDATE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.executeQuery().close();
        }
    }

    private List<CoachPickRow> loadFreeCoachesForLeague(Connection conn, Long idLiga) throws SQLException {
        String sql = """
                SELECT e.id, e.nombre, e.pila, e.foto, e.id_equipo, eq.nombre AS nombre_equipo, eq.foto AS foto_equipo,
                       e.bonus_puntos
                FROM entrenadores e
                INNER JOIN ligas l ON l.id = ? AND l.id_temporada = e.id_temporada
                LEFT JOIN equipos eq ON eq.id = e.id_equipo
                WHERE e.activo = TRUE
                  AND NOT EXISTS (
                      SELECT 1 FROM liga_participante_entrenador lpe
                      INNER JOIN liga_participantes lp ON lp.id = lpe.id_liga_participante
                      WHERE lp.id_liga = l.id AND lpe.id_entrenador = e.id
                  )
                ORDER BY e.id ASC
                """;
        List<CoachPickRow> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new CoachPickRow(
                            rs.getLong("id"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            rs.getString("foto"),
                            rs.getInt("id_equipo"),
                            rs.getString("nombre_equipo"),
                            rs.getString("foto_equipo"),
                            rs.getInt("bonus_puntos")
                    ));
                }
            }
        }
        return list;
    }

    private void insertCoachInventory(Connection conn, long idLigaParticipante, long idEntrenador) throws SQLException {
        String sql = """
                INSERT INTO liga_participante_entrenador (id_liga_participante, id_entrenador, activo)
                VALUES (?, ?, FALSE)
                ON DUPLICATE KEY UPDATE actualizado_en = CURRENT_TIMESTAMP(3)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idEntrenador);
            ps.executeUpdate();
        }
    }

    private LeagueCoachRouletteItemResponse mapCoachPick(CoachPickRow r) {
        return new LeagueCoachRouletteItemResponse(
                r.idEntrenador(),
                r.nombre(),
                r.pila(),
                LeagueAssetUrls.manager(r.idEntrenador()),
                r.idEquipo(),
                r.nombreEquipo(),
                LeagueAssetUrls.team(r.idEquipo()),
                r.bonusPuntos()
        );
    }

    private LeagueCoachRouletteItemResponse loadCoachSummaryForRewards(Connection conn, long idLigaParticipante) throws SQLException {
        LeagueCoachRouletteItemResponse active = loadEquippedCoachSummary(conn, idLigaParticipante);
        if (active != null) {
            return active;
        }
        return loadRouletteAssignedCoachSummary(conn, idLigaParticipante);
    }

    private LeagueCoachRouletteItemResponse loadRouletteAssignedCoachSummary(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT e.id, e.nombre, e.pila, e.foto, e.id_equipo, eq.nombre AS nombre_equipo, eq.foto AS foto_equipo,
                       e.bonus_puntos
                FROM liga_participante_ruleta_entrenador lpr
                INNER JOIN entrenadores e ON e.id = lpr.id_entrenador_asignado
                LEFT JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpr.id_liga_participante = ?
                  AND lpr.usado = TRUE
                  AND lpr.id_entrenador_asignado IS NOT NULL
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new LeagueCoachRouletteItemResponse(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getString("pila"),
                        LeagueAssetUrls.manager(rs.getLong("id")),
                        rs.getInt("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.team(rs.getInt("id_equipo")),
                        rs.getInt("bonus_puntos")
                );
            }
        }
    }

    private LeagueCoachRouletteItemResponse loadEquippedCoachSummary(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = """
                SELECT e.id, e.nombre, e.pila, e.foto, e.id_equipo, eq.nombre AS nombre_equipo, eq.foto AS foto_equipo,
                       e.bonus_puntos
                FROM liga_participante_entrenador lpe
                INNER JOIN entrenadores e ON e.id = lpe.id_entrenador
                LEFT JOIN equipos eq ON eq.id = e.id_equipo
                WHERE lpe.id_liga_participante = ? AND lpe.activo = TRUE
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new LeagueCoachRouletteItemResponse(
                        rs.getLong("id"),
                        rs.getString("nombre"),
                        rs.getString("pila"),
                        LeagueAssetUrls.manager(rs.getLong("id")),
                        rs.getInt("id_equipo"),
                        rs.getString("nombre_equipo"),
                        LeagueAssetUrls.team(rs.getInt("id_equipo")),
                        rs.getInt("bonus_puntos")
                );
            }
        }
    }

    private JsonNode parseParams(String json) throws SQLException {
        if (json == null || json.isBlank()) {
            return JSON.missingNode();
        }
        try {
            return JSON.readTree(json);
        } catch (Exception e) {
            throw new SQLException("parametros_json inválidos en definición de carta", e);
        }
    }

    private LeagueCardValidTargetsResponse sellTargets(Connection conn, Long idLiga, Long idUsuario, JsonNode params) throws SQLException {
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        double mult = params.path("sellMultiplier").asDouble(1.0d);
        String sql = """
                SELECT lj.id, lj.id_jugador, j.nombre, j.pila, j.posicion, lj.valor,
                       e.id AS id_equipo, e.nombre AS nombre_equipo,
                       lj.valoracion_actual
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = j.id_equipo
                WHERE lj.id_liga = ? AND lj.id_usuario_dueno = ? AND lj.id_usuario_dueno <> ?
                ORDER BY j.nombre ASC
                """;
        record Row(long id, long idJugador, String nombre, Long idEquipo, String nombreEquipo,
                   String posicion, Double valoracion, long valor) {}
        List<Row> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setLong(3, MARKET_USER_ID);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new Row(
                            rs.getLong("id"),
                            rs.getLong("id_jugador"),
                            buildName(rs.getString("nombre"), rs.getString("pila")),
                            rs.getLong("id_equipo"),
                            rs.getString("nombre_equipo"),
                            rs.getString("posicion"),
                            rs.getObject("valoracion_actual") != null ? rs.getDouble("valoracion_actual") : null,
                            rs.getLong("valor")
                    ));
                }
            }
        }
        List<Long> ids = rows.stream().map(Row::id).toList();
        Map<Long, Double> pctBy = leaguePlayerMarketValueService.batchMaxActiveModifierPercents(conn, idLiga, ids);
        List<LeagueCardTargetResponse> list = new ArrayList<>();
        for (Row r : rows) {
            double p = pctBy.getOrDefault(r.id(), 0d);
            long eff = leaguePlayerMarketValueService.effectiveValueFromBase(r.valor(), p);
            long preview = (long) Math.floor(eff * mult);
            list.add(LeagueCardTargetResponse.sellTarget(
                    r.id(), r.nombre(),
                    r.idEquipo(), r.nombreEquipo(), ASSET_TEAM_URL + r.idEquipo(),
                    ASSET_PLAYER_URL + r.idJugador(), r.posicion(), r.valoracion(),
                    eff, preview
            ));
        }
        return new LeagueCardValidTargetsResponse(CardEffectType.SELL_PLAYER_BONUS.name(), list);
    }

    private LeagueCardValidTargetsResponse clauseTargets(
            Connection conn,
            Long idLiga,
            Long idUsuario,
            long idLigaParticipanteAtacante,
            JsonNode params
    ) throws SQLException {
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        double buyerM = params.path("buyerMultiplier").asDouble();
        double ownerM = params.path("ownerCompensationMultiplier").asDouble(1.0d);
        JsonNode mv = params.get("maxPlayerValue");
        Long maxV = mv == null || mv.isNull() ? null : mv.asLong();

        String sql = """
                SELECT lj.id, lj.id_jugador, lj.valor, lj.id_usuario_dueno, j.nombre, j.pila, j.posicion,
                       e.id AS id_equipo, e.nombre AS nombre_equipo,
                       lj.valoracion_actual,
                       u.nickname, lp.id AS id_liga_participante
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = j.id_equipo
                LEFT JOIN usuarios u ON u.id = lj.id_usuario_dueno
                LEFT JOIN liga_participantes lp ON lp.id_liga = lj.id_liga AND lp.id_usuario = lj.id_usuario_dueno
                WHERE lj.id_liga = ? AND lj.id_usuario_dueno NOT IN (?, ?)
                ORDER BY u.nickname ASC, j.nombre ASC
                """;

        record PartKey(long idLigaParticipante, long idUsuario, String nickname) {}
        Map<Long, PartKey> partMap = new java.util.LinkedHashMap<>();
        Map<Long, List<LeagueCardTargetResponse>> validByPart = new java.util.LinkedHashMap<>();
        Map<Long, List<LeagueCardTargetResponse>> blockedByPart = new java.util.LinkedHashMap<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            ps.setLong(3, MARKET_USER_ID);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id");
                    long idJugador = rs.getLong("id_jugador");
                    long base = rs.getLong("valor");
                    long idDueno = rs.getLong("id_usuario_dueno");
                    long idLigaPart = rs.getLong("id_liga_participante");
                    String nick = rs.getString("nickname");
                    String nm = buildName(rs.getString("nombre"), rs.getString("pila"));
                    String posicion = rs.getString("posicion");
                    Long idEquipo = rs.getLong("id_equipo");
                    String nombreEquipo = rs.getString("nombre_equipo");
                    String fotoJugador = ASSET_PLAYER_URL + idJugador;
                    String fotoEquipo = ASSET_TEAM_URL + idEquipo;
                    Double valoracion = rs.getObject("valoracion_actual") != null ? rs.getDouble("valoracion_actual") : null;

                    double pct = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLj);
                    long eff = leaguePlayerMarketValueService.effectiveValueFromBase(base, pct);
                    boolean prot = isPlayerProtected(conn, idLj);

                    partMap.putIfAbsent(idLigaPart, new PartKey(idLigaPart, idDueno, nick));
                    validByPart.computeIfAbsent(idLigaPart, k -> new ArrayList<>());
                    blockedByPart.computeIfAbsent(idLigaPart, k -> new ArrayList<>());

                    if (prot) {
                        blockedByPart.get(idLigaPart).add(LeagueCardTargetResponse.clauseTarget(
                                idLj, nm, idEquipo, nombreEquipo, fotoEquipo, fotoJugador, posicion, valoracion,
                                idDueno, nick, eff, null, null, true, "JUGADOR_PROTEGIDO"));
                        continue;
                    }
                    if (maxV != null && eff > maxV) {
                        blockedByPart.get(idLigaPart).add(LeagueCardTargetResponse.clauseTarget(
                                idLj, nm, idEquipo, nombreEquipo, fotoEquipo, fotoJugador, posicion, valoracion,
                                idDueno, nick, eff, null, null, true, "SUPERA_VALOR_MAXIMO_CARTA"));
                        continue;
                    }
                    long coste = (long) Math.ceil(eff * buyerM);
                    long comp = (long) Math.floor(eff * ownerM);
                    validByPart.get(idLigaPart).add(LeagueCardTargetResponse.clauseTarget(
                            idLj, nm, idEquipo, nombreEquipo, fotoEquipo, fotoJugador, posicion, valoracion,
                            idDueno, nick, eff, coste, comp, false, null));
                }
            }
        }

        List<LeagueCardParticipantTargetsResponse> participantes = new ArrayList<>();
        for (Map.Entry<Long, PartKey> e : partMap.entrySet()) {
            long key = e.getKey();
            PartKey pk = e.getValue();
            List<LeagueCardTargetResponse> v = validByPart.getOrDefault(key, List.of());
            List<LeagueCardTargetResponse> b = blockedByPart.getOrDefault(key, List.of());
            participantes.add(new LeagueCardParticipantTargetsResponse(
                    pk.idLigaParticipante(), pk.idUsuario(), pk.nickname(),
                    v.size(), b.size(), v, b));
        }

        List<LeagueCardTargetResponse> allValid = new ArrayList<>();
        List<LeagueCardTargetResponse> allBlocked = new ArrayList<>();
        participantes.forEach(p -> { allValid.addAll(p.objetivos()); allBlocked.addAll(p.objetivosBloqueados()); });

        return new LeagueCardValidTargetsResponse(CardEffectType.DIRECT_CLAUSE.name(), allValid, allBlocked, participantes, null);
    }

    private LeagueCardValidTargetsResponse protectTargets(Connection conn, Long idLiga, Long idUsuario, long idLigaParticipante, JsonNode params) throws SQLException {
        boolean seasonCard = params.path("seasonLong").asBoolean(false);
        JsonNode roundsNode = params.get("rounds");
        Integer roundsCard = (roundsNode == null || roundsNode.isNull()) ? null : roundsNode.asInt();

        String sql = """
                SELECT lj.id, lj.id_jugador, j.nombre, j.pila, j.posicion, lj.valor,
                       e.id AS id_equipo, e.nombre AS nombre_equipo,
                       lj.valoracion_actual
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = j.id_equipo
                WHERE lj.id_liga = ? AND lj.id_usuario_dueno = ?
                ORDER BY j.nombre ASC
                """;
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        List<JornadaLite> jr = loadJornadas(conn, idLiga);
        Map<Long, Long> numeroPorJornadaId = jornadaNumeroPorId(jr);
        int newTier = newProtectionTier(seasonCard, roundsCard);
        List<LeagueCardTargetResponse> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id");
                    long idJugador = rs.getLong("id_jugador");
                    long idEquipo = rs.getLong("id_equipo");
                    ProtectionEval pe = loadActiveProtection(conn, idLj);
                    boolean protegido = pe != null;
                    String nm = buildName(rs.getString("nombre"), rs.getString("pila"));
                    long valor = rs.getLong("valor");
                    double pctMod = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLj);
                    long eff = leaguePlayerMarketValueService.effectiveValueFromBase(valor, pctMod);

                    String motivo = null;
                    if (pe != null && protectionTierValue(pe, jr) >= newTier) {
                        motivo = "PROTECCION_IGUAL_O_SUPERIOR";
                    }

                    Long numFin = pe == null || pe.jFin() == null ? null : numeroPorJornadaId.get(pe.jFin());

                    list.add(LeagueCardTargetResponse.protectTarget(
                            idLj, nm,
                            idEquipo, rs.getString("nombre_equipo"), ASSET_TEAM_URL + idEquipo,
                            ASSET_PLAYER_URL + idJugador, rs.getString("posicion"),
                            rs.getObject("valoracion_actual") != null ? rs.getDouble("valoracion_actual") : null,
                            eff,
                            protegido, motivo != null ? motivo : (protegido ? "PROTECCION_ACTIVA" : null),
                            pe == null ? null : pe.jIni(),
                            pe == null ? null : pe.jFin(),
                            numFin,
                            pe != null && pe.season(),
                            seasonCard ? null : (roundsCard != null ? roundsCard : 1),
                            seasonCard
                    ));
                }
            }
        }
        return new LeagueCardValidTargetsResponse(CardEffectType.PROTECT_PLAYER.name(), list);
    }

    private LeagueCardValidTargetsResponse leaguePointsTargets(CardEffectType effect, JsonNode params) {
        int pts = params.path("points").asInt(0);
        return new LeagueCardValidTargetsResponse(effect.name(), List.of(), List.of(), null, pts > 0 ? pts : null);
    }

    private LeagueCardValidTargetsResponse valueRecoveryTargets(Connection conn, Long idLiga, Long idUsuario, JsonNode params) throws SQLException {
        leaguePlayerMarketValueService.refreshExpiredValueModifiers(conn, idLiga);
        double pct = params.path("percentage").asDouble(0d);
        String sql = """
                SELECT lj.id, lj.id_jugador, j.nombre, j.pila, j.posicion, lj.valor, lj.valor_anterior,
                       e.id AS id_equipo, e.nombre AS nombre_equipo,
                       lj.valoracion_actual
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = j.id_equipo
                WHERE lj.id_liga = ? AND lj.id_usuario_dueno = ? AND lj.valor < lj.valor_anterior
                ORDER BY j.nombre ASC
                """;
        List<JornadaLite> jr = loadJornadas(conn, idLiga);
        Map<Long, Long> numeroPorJornadaId = jornadaNumeroPorId(jr);
        Long jExp = firstPendingJornadaId(jr);
        if (jExp == null) { jExp = lastJornadaId(jr); }

        List<LeagueCardTargetResponse> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLj = rs.getLong("id");
                    long v = rs.getLong("valor");
                    long va = rs.getLong("valor_anterior");
                    ModifierActive mod = loadActiveValueModifier(conn, idLj);
                    if (mod != null && mod.porcentaje() >= pct) {
                        continue;
                    }
                    double pctAct = leaguePlayerMarketValueService.maxActiveModifierPercent(conn, idLiga, idLj);
                    long effCur = leaguePlayerMarketValueService.effectiveValueFromBase(v, pctAct);
                    long temp = (long) Math.floor(v * (1.0d + pct));
                    long idJugador = rs.getLong("id_jugador");
                    long idEquipo = rs.getLong("id_equipo");
                    String nm = buildName(rs.getString("nombre"), rs.getString("pila"));
                    long diferencia = Math.max(0L, va - v);
                    long incDiario = (long) Math.floor(effCur * pct);
                    Long numExp = jExp == null ? null : numeroPorJornadaId.get(jExp);
                    list.add(LeagueCardTargetResponse.valueRecovery(
                            idLj, nm,
                            idEquipo, rs.getString("nombre_equipo"), ASSET_TEAM_URL + idEquipo,
                            ASSET_PLAYER_URL + idJugador, rs.getString("posicion"),
                            rs.getObject("valoracion_actual") != null ? rs.getDouble("valoracion_actual") : null,
                            v, va,
                            temp, pct, jExp, numExp, incDiario, diferencia
                    ));
                }
            }
        }
        return new LeagueCardValidTargetsResponse(CardEffectType.TEMPORARY_VALUE_RECOVERY.name(), list);
    }

    private boolean isPlayerProtected(Connection conn, long idLigaJugador) throws SQLException {
        return loadActiveProtection(conn, idLigaJugador) != null;
    }

    private ProtectionEval loadActiveProtection(Connection conn, long idLigaJugador) throws SQLException {
        String sql = """
                SELECT p.id, p.hasta_fin_temporada, p.id_jornada_fin, p.id_jornada_inicio,
                       (SELECT estado FROM jornadas j WHERE j.id = p.id_jornada_fin) AS est_fin
                FROM liga_jugador_protecciones p
                WHERE p.id_liga_jugador = ? AND p.activo = TRUE
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                boolean season = rs.getBoolean("hasta_fin_temporada");
                Long jFin = rs.getObject("id_jornada_fin", Long.class);
                Long jIni = rs.getObject("id_jornada_inicio", Long.class);
                String estFin = rs.getString("est_fin");
                boolean active = season || jFin == null || !"FINALIZADA".equals(estFin);
                if (!active) {
                    return null;
                }
                return new ProtectionEval(rs.getLong("id"), season, jIni, jFin);
            }
        }
    }

    private int newProtectionTier(boolean season, Integer rounds) {
        if (season) {
            return 1_000_000;
        }
        int r = rounds == null ? 1 : Math.max(1, rounds);
        return r * 10_000;
    }

    private int protectionTierValue(ProtectionEval e, List<JornadaLite> jr) {
        if (e.season()) {
            return 1_000_000;
        }
        if (e.jIni() != null && e.jFin() != null) {
            return countJornadasBetween(jr, e.jIni(), e.jFin()) * 10_000;
        }
        return 1;
    }

    private int countJornadasBetween(List<JornadaLite> jr, long idIni, long idFin) {
        int c = 0;
        boolean on = false;
        for (JornadaLite j : jr) {
            if (j.id() == idIni) {
                on = true;
            }
            if (on) {
                c++;
            }
            if (j.id() == idFin) {
                break;
            }
        }
        return Math.max(c, 1);
    }

    private void deactivateProtection(Connection conn, long idProt) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("UPDATE liga_jugador_protecciones SET activo = FALSE WHERE id = ?")) {
            ps.setLong(1, idProt);
            ps.executeUpdate();
        }
    }

    private long insertProtection(
            Connection conn,
            Long idLiga,
            long idLj,
            long idLigaParticipante,
            long idCarta,
            Long jIni,
            Long jFin,
            boolean season
    ) throws SQLException {
        String sql = """
                INSERT INTO liga_jugador_protecciones (
                    id_liga, id_liga_jugador, id_liga_participante, id_carta_origen,
                    id_jornada_inicio, id_jornada_fin, hasta_fin_temporada, activo
                ) VALUES (?,?,?,?,?,?,?,TRUE)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLj);
            ps.setLong(3, idLigaParticipante);
            ps.setLong(4, idCarta);
            setLongOrNull(ps, 5, jIni);
            setLongOrNull(ps, 6, jFin);
            ps.setBoolean(7, season);
            ps.executeUpdate();
            try (ResultSet k = ps.getGeneratedKeys()) {
                k.next();
                return k.getLong(1);
            }
        }
    }

    private List<JornadaLite> loadJornadas(Connection conn, Long idLiga) throws SQLException {
        String sql = "SELECT id, numero, estado FROM jornadas WHERE id_liga = ? ORDER BY numero ASC";
        List<JornadaLite> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new JornadaLite(rs.getLong("id"), rs.getInt("numero"), rs.getString("estado")));
                }
            }
        }
        return list;
    }

    private Long firstPendingJornadaId(List<JornadaLite> jr) {
        return jr.stream().filter(j -> "PENDIENTE".equals(j.estado())).map(JornadaLite::id).findFirst().orElse(null);
    }

    private Long lastJornadaId(List<JornadaLite> jr) {
        return jr.isEmpty() ? null : jr.get(jr.size() - 1).id();
    }

    private Long jornadaFinDesde(List<JornadaLite> jr, Long jIniId, int rounds) {
        int idx = -1;
        for (int i = 0; i < jr.size(); i++) {
            if (jr.get(i).id() == jIniId) {
                idx = i;
                break;
            }
        }
        if (idx < 0) {
            return jIniId;
        }
        int finIdx = Math.min(idx + rounds - 1, jr.size() - 1);
        return jr.get(finIdx).id();
    }

    private LockedLj lockLeaguePlayerRow(Connection conn, Long idLiga, long idLj) throws SQLException {
        String sql = """
                SELECT lj.id, lj.id_usuario_dueno, lj.valor, lj.valor_anterior,
                       COALESCE(j.pila, j.nombre) AS nm
                FROM liga_jugadores lj
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                WHERE lj.id = ? AND lj.id_liga = ?
                FOR UPDATE
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLj);
            ps.setLong(2, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Jugador no encontrado en la liga");
                }
                return new LockedLj(
                        rs.getLong("id"),
                        rs.getLong("id_usuario_dueno"),
                        rs.getLong("valor"),
                        rs.getLong("valor_anterior"),
                        rs.getString("nm")
                );
            }
        }
    }

    private String requireOwnedLeaguePlayerName(Connection conn, Long idLiga, long idLj, Long idUsuario) throws SQLException {
        LockedLj lj = lockLeaguePlayerRow(conn, idLiga, idLj);
        if (!Objects.equals(lj.idUsuarioDueno(), idUsuario)) {
            throw new LeagueRewardForbiddenException("El jugador no te pertenece");
        }
        if (lj.idUsuarioDueno() == MARKET_USER_ID) {
            throw new IllegalArgumentException("Jugador del mercado no válido para esta operación");
        }
        return lj.nombreJugador();
    }

    private ModifierActive loadActiveValueModifier(Connection conn, long idLj) throws SQLException {
        String sql = """
                SELECT id, porcentaje FROM liga_jugador_modificadores_valor
                WHERE id_liga_jugador = ? AND activo = TRUE
                ORDER BY porcentaje DESC LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLj);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new ModifierActive(rs.getLong("id"), rs.getBigDecimal("porcentaje").doubleValue());
            }
        }
    }

    private void deactivateValueModifier(Connection conn, long id) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("UPDATE liga_jugador_modificadores_valor SET activo = FALSE WHERE id = ?")) {
            ps.setLong(1, id);
            ps.executeUpdate();
        }
    }

    private long insertValueModifier(
            Connection conn,
            Long idLiga,
            long idLj,
            long idLigaParticipante,
            long idCarta,
            double pct,
            Long jExp
    ) throws SQLException {
        String sql = """
                INSERT INTO liga_jugador_modificadores_valor (
                    id_liga, id_liga_jugador, id_liga_participante, id_carta_origen, tipo, porcentaje, activo, id_jornada_expiracion
                ) VALUES (?,?,?,?,?,?,TRUE,?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idLj);
            ps.setLong(3, idLigaParticipante);
            ps.setLong(4, idCarta);
            ps.setString(5, "TEMPORARY_VALUE_RECOVERY");
            ps.setBigDecimal(6, BigDecimal.valueOf(pct));
            setLongOrNull(ps, 7, jExp);
            ps.executeUpdate();
            try (ResultSet k = ps.getGeneratedKeys()) {
                k.next();
                return k.getLong(1);
            }
        }
    }

    private void insertBonusPoints(Connection conn, long idLigaParticipante, long idCarta, int pts, String motivo) throws SQLException {
        String sql = """
                INSERT INTO liga_participante_puntos_bonus (id_liga_participante, id_carta_origen, puntos, motivo)
                VALUES (?,?,?,?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idCarta);
            ps.setInt(3, pts);
            ps.setString(4, motivo);
            ps.executeUpdate();
        }
    }

    private int sumBonusPoints(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = "SELECT COALESCE(SUM(puntos),0) s FROM liga_participante_puntos_bonus WHERE id_liga_participante = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("s");
            }
        }
    }

    private int loadFantasyPoints(Connection conn, long idLigaParticipante) throws SQLException {
        String sql = "SELECT puntos_totales FROM liga_participantes WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("puntos_totales");
            }
        }
    }

    private String loadNickname(Connection conn, long idUsuario) throws SQLException {
        String sql = "SELECT nickname FROM usuarios WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getString("nickname");
            }
        }
    }

    private String buildName(String nombre, String pila) {
        if (pila != null && !pila.isBlank()) {
            return pila;
        }
        return nombre == null ? "" : nombre;
    }
}
