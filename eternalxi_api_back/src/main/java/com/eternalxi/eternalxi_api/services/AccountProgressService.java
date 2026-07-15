package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.user.UserAchievementResponse;
import com.eternalxi.eternalxi_api.dto.user.UserProgressEventResponse;
import com.eternalxi.eternalxi_api.dto.user.UserProgressResponse;
import com.eternalxi.eternalxi_api.progress.AccountLevelMath;
import com.eternalxi.eternalxi_api.progress.AchievementCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.Map;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class AccountProgressService {

    private static final Logger log = LoggerFactory.getLogger(AccountProgressService.class);

    private static final int DAILY_LOGIN_XP = 12;
    private static final int ROUND_PARTICIPATION_XP = 6;
    private static final int MIN_LEAGUE_PARTICIPANTS = 3;

    private final PushNotificationService pushNotificationService;
    private final UserPublicProfileService userPublicProfileService;

    public AccountProgressService(
            PushNotificationService pushNotificationService,
            @Lazy UserPublicProfileService userPublicProfileService
    ) {
        this.pushNotificationService = pushNotificationService;
        this.userPublicProfileService = userPublicProfileService;
    }

    public void ensureSchema() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureSchema(conn);
        }
    }

    private boolean columnExists(Connection conn, String table, String column) throws SQLException {
        String sql = """
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name = ?
                  AND column_name = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, table);
            ps.setString(2, column);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void ensureColumn(Connection conn, String table, String column, String ddl) throws SQLException {
        if (columnExists(conn, table, column)) {
            return;
        }
        try (PreparedStatement ps = conn.prepareStatement(ddl)) {
            ps.executeUpdate();
            log.info("Columna creada: {}.{}", table, column);
        }
    }

    public void ensureSchema(Connection conn) throws SQLException {
        ensureColumn(conn, "usuarios", "experiencia",
                "ALTER TABLE usuarios ADD COLUMN experiencia BIGINT NOT NULL DEFAULT 0");
        ensureColumn(conn, "usuarios", "ultimo_login_xp",
                "ALTER TABLE usuarios ADD COLUMN ultimo_login_xp DATE NULL");
        try (PreparedStatement ps = conn.prepareStatement("""
                CREATE TABLE IF NOT EXISTS usuario_logros (
                    id BIGINT NOT NULL AUTO_INCREMENT,
                    id_usuario BIGINT NOT NULL,
                    codigo_logro VARCHAR(64) NOT NULL,
                    desbloqueado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                    id_liga BIGINT NULL,
                    PRIMARY KEY (id),
                    UNIQUE KEY uk_usuario_logro (id_usuario, codigo_logro)
                )
                """)) {
            ps.executeUpdate();
        }
        try (PreparedStatement ps = conn.prepareStatement("""
                CREATE TABLE IF NOT EXISTS usuario_progreso_eventos (
                    id BIGINT NOT NULL AUTO_INCREMENT,
                    id_usuario BIGINT NOT NULL,
                    tipo VARCHAR(24) NOT NULL,
                    cantidad_xp INT NULL,
                    nivel_anterior INT NULL,
                    nivel_nuevo INT NULL,
                    codigo_logro VARCHAR(64) NULL,
                    titulo_logro VARCHAR(128) NULL,
                    descripcion_logro VARCHAR(255) NULL,
                    xp_logro INT NULL,
                    xp_total_despues BIGINT NULL,
                    xp_en_nivel_despues BIGINT NULL,
                    xp_para_siguiente_despues BIGINT NULL,
                    visto BOOLEAN NOT NULL DEFAULT FALSE,
                    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                    PRIMARY KEY (id),
                    KEY idx_upe_usuario_visto (id_usuario, visto, creado_en)
                )
                """)) {
            ps.executeUpdate();
        }
    }

    public UserProgressResponse loadProgress(Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureSchema(conn);
            processDailyLogin(conn, idUsuario);
            repairDayPointAchievementTiers(conn, idUsuario);
            return buildProgressResponse(conn, idUsuario);
        }
    }

    /** Logros y nivel visibles en el perfil de otro usuario (sin eventos pendientes privados). */
    public UserProgressResponse loadPublicProgress(Long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureSchema(conn);
            UserProgressResponse full = buildProgressResponse(conn, idUsuario);
            return new UserProgressResponse(
                    full.idUsuario(),
                    full.nivel(),
                    full.experienciaTotal(),
                    full.xpEnNivel(),
                    full.xpParaSiguienteNivel(),
                    full.rango(),
                    full.logros(),
                    List.of()
            );
        }
    }

    public UserProgressResponse markEventsSeen(Long idUsuario, List<Long> eventIds) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            ensureSchema(conn);
            if (eventIds != null && !eventIds.isEmpty()) {
                String placeholders = String.join(",", eventIds.stream().map(x -> "?").toList());
                String sql = "UPDATE usuario_progreso_eventos SET visto = TRUE "
                        + "WHERE id_usuario = ? AND visto = FALSE AND id IN (" + placeholders + ")";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, idUsuario);
                    int i = 2;
                    for (Long id : eventIds) {
                        ps.setLong(i++, id);
                    }
                    ps.executeUpdate();
                }
            }
            return buildProgressResponse(conn, idUsuario);
        }
    }

    public void processDailyLogin(Connection conn, Long idUsuario) throws SQLException {
        if (idUsuario == null || idUsuario <= 0) {
            return;
        }
        LocalDate today = LocalDate.now();
        Date last = null;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT ultimo_login_xp FROM usuarios WHERE id = ? FOR UPDATE")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return;
                }
                Date d = rs.getDate("ultimo_login_xp");
                if (d != null) {
                    last = d;
                }
            }
        }
        if (last != null && last.toLocalDate().equals(today)) {
            return;
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE usuarios SET ultimo_login_xp = ? WHERE id = ?")) {
            ps.setDate(1, Date.valueOf(today));
            ps.setLong(2, idUsuario);
            ps.executeUpdate();
        }
        grantXp(conn, idUsuario, DAILY_LOGIN_XP, "DAILY_LOGIN", "DAILY_LOGIN",
                "Inicio de sesión", "Bonificación diaria");
    }

    public void onLeagueClosed(Connection conn, Long idLiga) throws SQLException {
        if (idLiga == null) {
            return;
        }
        LeagueMeta meta = loadLeagueMeta(conn, idLiga);
        if (meta == null) {
            return;
        }
        if (!isLeagueEligibleForProgress(conn, idLiga, meta)) {
            log.info("Liga {} no elegible para XP de cierre", idLiga);
            return;
        }
        List<StandingRow> standings = loadFinalStandings(conn, idLiga);
        int n = standings.size();
        String leagueName = loadLeagueName(conn, idLiga);
        String leagueTitle = leagueName != null && !leagueName.isBlank() ? leagueName : "Liga";
        for (StandingRow row : standings) {
            if (row.idUsuario() == null) {
                continue;
            }
            int position = row.posicion();
            long leagueXp = 25L + (long) (n - position + 1) * 15L;
            if (position == 1) {
                leagueXp += 120;
            }
            String leagueDesc = position == 1
                    ? "Campeón · Liga finalizada"
                    : "Puesto " + position + " · Liga finalizada";
            grantXp(conn, row.idUsuario(), (int) leagueXp, "LEAGUE_FINISH",
                    "LEAGUE_" + idLiga, leagueTitle, leagueDesc);

            if (position == 1) {
                incrementWinLeagueAchievements(conn, row.idUsuario(), idLiga);
            }

            if (!meta.idaYVuelta()) {
                if (row.puntosTotales() >= 1000) {
                    tryUnlock(conn, row.idUsuario(), AchievementCode.FINISH_LEAGUE_1000, idLiga);
                } else if (row.puntosTotales() >= 750) {
                    tryUnlock(conn, row.idUsuario(), AchievementCode.FINISH_LEAGUE_750, idLiga);
                } else if (row.puntosTotales() >= 500) {
                    tryUnlock(conn, row.idUsuario(), AchievementCode.FINISH_LEAGUE_500, idLiga);
                }
            }

            tryUnlock(conn, row.idUsuario(), AchievementCode.FIRST_LEAGUE, idLiga);
            syncFavoriteRosterAchievements(
                    conn,
                    row.idUsuario(),
                    userPublicProfileService.countSignedPlayersInFinishedLeagues(conn, row.idUsuario()),
                    userPublicProfileService.countCatalogPlayers(conn)
            );
        }
    }

    public void syncFavoriteRosterAchievements(
            Connection conn,
            Long idUsuario,
            int signedPlayers,
            int catalogPlayers
    ) throws SQLException {
        if (idUsuario == null || catalogPlayers <= 0) {
            return;
        }
        int percent = Math.min(100, (signedPlayers * 100) / catalogPlayers);
        if (percent >= 50) {
            tryUnlock(conn, idUsuario, AchievementCode.FAVORITE_ROSTER_HALF, null);
        }
        if (signedPlayers >= catalogPlayers) {
            tryUnlock(conn, idUsuario, AchievementCode.FAVORITE_ROSTER_COMPLETE, null);
        }
    }

    public void syncFavoriteRosterAchievements(Long idUsuario) throws SQLException {
        if (idUsuario == null || idUsuario <= 0) {
            return;
        }
        try (Connection conn = DBConnection.getConnection()) {
            syncFavoriteRosterAchievements(
                    conn,
                    idUsuario,
                    userPublicProfileService.countSignedPlayersInFinishedLeagues(conn, idUsuario),
                    userPublicProfileService.countCatalogPlayers(conn)
            );
        }
    }

    /**
     * XP de cuenta al cerrarse una jornada: participación + logros de puntos diarios.
     */
    public int onRoundFinished(
            Connection conn,
            Long idLiga,
            Long idJornada,
            Long idUsuario,
            int fantasyPoints
    ) throws SQLException {
        int xp = grantRoundParticipationXpIfAbsent(conn, idUsuario, idLiga, idJornada);
        xp += onRoundFantasyPoints(conn, idLiga, idUsuario, fantasyPoints);
        return xp;
    }

    private int grantRoundParticipationXpIfAbsent(
            Connection conn,
            Long idUsuario,
            Long idLiga,
            Long idJornada
    ) throws SQLException {
        if (idUsuario == null || idLiga == null || idJornada == null) {
            return 0;
        }
        String marker = "ROUND_" + idLiga + "_" + idJornada;
        if (hasXpEventWithCode(conn, idUsuario, marker)) {
            return 0;
        }
        String leagueName = loadLeagueName(conn, idLiga);
        String leagueTitle = leagueName != null && !leagueName.isBlank() ? leagueName : "Liga";
        grantXp(conn, idUsuario, ROUND_PARTICIPATION_XP, "ROUND_FINISH",
                marker, leagueTitle, "Jornada completada");
        return ROUND_PARTICIPATION_XP;
    }

    private boolean hasXpEventWithCode(Connection conn, Long idUsuario, String code) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM usuario_progreso_eventos WHERE id_usuario = ? AND codigo_logro = ? LIMIT 1")) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public int onRoundFantasyPoints(Connection conn, Long idLiga, Long idUsuario, int fantasyPoints)
            throws SQLException {
        int xp = 0;
        if (fantasyPoints >= 50) {
            xp += tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_50, idLiga);
        }
        if (fantasyPoints >= 75) {
            xp += tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_75, idLiga);
        }
        if (fantasyPoints >= 100) {
            xp += tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_100, idLiga);
        }
        if (fantasyPoints >= 150) {
            xp += tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_150, idLiga);
        }
        return xp;
    }

    /**
     * Si el usuario desbloqueó un umbral alto de puntos en jornada antes del fix en cascada,
     * concede los logros de umbrales inferiores que falten.
     */
    void repairDayPointAchievementTiers(Connection conn, Long idUsuario) throws SQLException {
        if (idUsuario == null) {
            return;
        }
        if (hasAchievement(conn, idUsuario, AchievementCode.DAY_POINTS_150)) {
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_100, null);
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_75, null);
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_50, null);
            return;
        }
        if (hasAchievement(conn, idUsuario, AchievementCode.DAY_POINTS_100)) {
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_75, null);
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_50, null);
            return;
        }
        if (hasAchievement(conn, idUsuario, AchievementCode.DAY_POINTS_75)) {
            tryUnlock(conn, idUsuario, AchievementCode.DAY_POINTS_50, null);
        }
    }

    public void onPackOpened(Connection conn, Long idUsuario, Long idLiga, Long idLigaParticipante) throws SQLException {
        int count = countPackOpens(conn, idLigaParticipante);
        if (count >= 20) {
            tryUnlock(conn, idUsuario, AchievementCode.PACKS_20, idLiga);
        } else if (count >= 15) {
            tryUnlock(conn, idUsuario, AchievementCode.PACKS_15, idLiga);
        } else if (count >= 10) {
            tryUnlock(conn, idUsuario, AchievementCode.PACKS_10, idLiga);
        } else if (count >= 5) {
            tryUnlock(conn, idUsuario, AchievementCode.PACKS_5, idLiga);
        }
    }

    public void onClauseExecuted(Connection conn, Long idUsuario, Long idLiga, long valorEfectivo) throws SQLException {
        if (valorEfectivo >= 100_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.CLAUSE_100M, idLiga);
        } else if (valorEfectivo >= 50_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.CLAUSE_50M, idLiga);
        } else if (valorEfectivo >= 30_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.CLAUSE_30M, idLiga);
        } else if (valorEfectivo >= 20_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.CLAUSE_20M, idLiga);
        }
    }

    public void onProtectionApplied(Connection conn, Long idUsuario, Long idLiga, Long idLigaParticipante)
            throws SQLException {
        tryUnlock(conn, idUsuario, AchievementCode.SHIELD_PLAYER, idLiga);
        int active = countActiveProtections(conn, idLigaParticipante);
        if (active >= 5) {
            tryUnlock(conn, idUsuario, AchievementCode.SHIELD_5_ACTIVE, idLiga);
        } else if (active >= 3) {
            tryUnlock(conn, idUsuario, AchievementCode.SHIELD_3_ACTIVE, idLiga);
        }
    }

    public void onPlayerSold(Connection conn, Long idUsuario, Long idLiga, long amount) throws SQLException {
        if (amount >= 200_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.SELL_200M, idLiga);
        } else if (amount >= 150_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.SELL_150M, idLiga);
        } else if (amount >= 100_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.SELL_100M, idLiga);
        } else if (amount >= 50_000_000L) {
            tryUnlock(conn, idUsuario, AchievementCode.SELL_50M, idLiga);
        }
    }

    private static final AchievementCode[] PUSH_TIERS = {
            AchievementCode.PUSH_WIN_5000,
            AchievementCode.PUSH_WIN_1000,
            AchievementCode.PUSH_WIN_500,
            AchievementCode.PUSH_WIN_100
    };

    public void onMarketAdjudication(Connection conn, Long idUsuario, Long idLiga, Long idMercadoDiario, long winnerBid)
            throws SQLException {
        long second = loadSecondHighestBid(conn, idMercadoDiario);
        if (second <= 0) {
            return;
        }
        long margin = winnerBid - second;
        if (margin <= 100) {
            unlockPushCascade(conn, idUsuario, idLiga, 3);
        } else if (margin <= 500) {
            unlockPushCascade(conn, idUsuario, idLiga, 2);
        } else if (margin <= 1000) {
            unlockPushCascade(conn, idUsuario, idLiga, 1);
        } else if (margin <= 5000) {
            unlockPushCascade(conn, idUsuario, idLiga, 0);
        }
    }

    private void unlockPushCascade(Connection conn, Long idUsuario, Long idLiga, int fromIndex) throws SQLException {
        for (int i = fromIndex; i < PUSH_TIERS.length; i++) {
            tryUnlock(conn, idUsuario, PUSH_TIERS[i], idLiga);
        }
    }

    public void onCoachRoulette(Connection conn, Long idUsuario, Long idLiga) throws SQLException {
        tryUnlock(conn, idUsuario, AchievementCode.COACH_ROULETTE, idLiga);
    }

    private void incrementWinLeagueAchievements(Connection conn, Long idUsuario, Long idLiga) throws SQLException {
        recordLeagueWin(conn, idUsuario, idLiga);
        int wins = countLeagueWins(conn, idUsuario);
        if (wins >= 30) {
            tryUnlock(conn, idUsuario, AchievementCode.WIN_LEAGUE_30, idLiga);
        }
        if (wins >= 10) {
            tryUnlock(conn, idUsuario, AchievementCode.WIN_LEAGUE_10, idLiga);
        }
        if (wins >= 5) {
            tryUnlock(conn, idUsuario, AchievementCode.WIN_LEAGUE_5, idLiga);
        }
        if (wins >= 3) {
            tryUnlock(conn, idUsuario, AchievementCode.WIN_LEAGUE_3, idLiga);
        }
        if (wins >= 1) {
            tryUnlock(conn, idUsuario, AchievementCode.WIN_LEAGUE_1, idLiga);
        }
    }

    private void recordLeagueWin(Connection conn, Long idUsuario, Long idLiga) throws SQLException {
        String code = "LEAGUE_WON_" + idLiga;
        if (hasAchievementCode(conn, idUsuario, code)) {
            return;
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO usuario_logros (id_usuario, codigo_logro, id_liga) VALUES (?, ?, ?)")) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code);
            ps.setLong(3, idLiga);
            ps.executeUpdate();
        }
    }

    private int countLeagueWins(Connection conn, Long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM usuario_logros WHERE id_usuario = ? AND codigo_logro LIKE 'LEAGUE_WON_%'")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private boolean hasAchievementCode(Connection conn, Long idUsuario, String code) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM usuario_logros WHERE id_usuario = ? AND codigo_logro = ? LIMIT 1")) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private int tryUnlock(Connection conn, Long idUsuario, AchievementCode code, Long idLiga) throws SQLException {
        if (hasAchievement(conn, idUsuario, code)) {
            return 0;
        }
        insertAchievement(conn, idUsuario, code, idLiga);
        grantXp(conn, idUsuario, code.xpReward(), "ACHIEVEMENT", code.code(), code.title(), code.description());
        insertAchievementEvent(conn, idUsuario, code);
        notifyAchievementUnlocked(idUsuario, code);
        return code.xpReward();
    }

    private void notifyAchievementUnlocked(Long idUsuario, AchievementCode code) {
        try {
            pushNotificationService.sendToUser(
                    idUsuario,
                    "¡Logro conseguido!",
                    code.title(),
                    Map.of(
                            "type", "ACHIEVEMENT",
                            "achievementCode", code.code()
                    )
            );
        } catch (Exception e) {
            log.warn("No se pudo enviar push de logro {} a usuario {}: {}", code.code(), idUsuario, e.getMessage());
        }
    }

    private void grantXp(
            Connection conn,
            Long idUsuario,
            int xp,
            String source,
            String achievementCode,
            String achievementTitle,
            String achievementDesc
    ) throws SQLException {
        if (xp <= 0) {
            return;
        }
        long totalBefore;
        int levelBefore;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT experiencia, nivel FROM usuarios WHERE id = ? FOR UPDATE")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return;
                }
                totalBefore = rs.getLong("experiencia");
                levelBefore = rs.getInt("nivel");
            }
        }
        long totalAfter = totalBefore + xp;
        int levelAfter = AccountLevelMath.levelFromTotalXp(totalAfter);
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE usuarios SET experiencia = ?, nivel = ? WHERE id = ?")) {
            ps.setLong(1, totalAfter);
            ps.setInt(2, levelAfter);
            ps.setLong(3, idUsuario);
            ps.executeUpdate();
        }
        long xpInLevel = AccountLevelMath.xpIntoCurrentLevel(totalAfter);
        long xpNext = AccountLevelMath.xpForNextLevelFromTotal(totalAfter);

        if ("ACHIEVEMENT".equals(source)) {
            // evento de logro se inserta aparte
        } else {
            String codigo = achievementCode;
            String titulo = achievementTitle;
            String descripcion = achievementDesc;
            if (titulo == null || titulo.isBlank()) {
                titulo = switch (source) {
                    case "DAILY_LOGIN" -> "Inicio de sesión";
                    case "LEAGUE_FINISH" -> "Liga";
                    case "ROUND_FINISH" -> "Liga";
                    default -> "Experiencia";
                };
            }
            if (descripcion == null || descripcion.isBlank()) {
                descripcion = switch (source) {
                    case "DAILY_LOGIN" -> "Bonificación diaria";
                    case "LEAGUE_FINISH" -> "Liga finalizada";
                    case "ROUND_FINISH" -> "Jornada completada";
                    default -> null;
                };
            }
            insertXpEvent(conn, idUsuario, xp, null, null, codigo, titulo, descripcion,
                    totalAfter, xpInLevel, xpNext);
        }

        if (levelAfter > levelBefore) {
            insertLevelUpEvent(conn, idUsuario, levelBefore, levelAfter, totalAfter, xpInLevel, xpNext);
        }
    }

    private void insertAchievementEvent(Connection conn, Long idUsuario, AchievementCode code) throws SQLException {
        long total = loadTotalXp(conn, idUsuario);
        long xpInLevel = AccountLevelMath.xpIntoCurrentLevel(total);
        long xpNext = AccountLevelMath.xpForNextLevelFromTotal(total);
        String sql = """
                INSERT INTO usuario_progreso_eventos (
                    id_usuario, tipo, codigo_logro, titulo_logro, descripcion_logro, xp_logro,
                    xp_total_despues, xp_en_nivel_despues, xp_para_siguiente_despues
                ) VALUES (?, 'ACHIEVEMENT', ?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code.code());
            ps.setString(3, code.title());
            ps.setString(4, code.description());
            ps.setInt(5, code.xpReward());
            ps.setLong(6, total);
            ps.setLong(7, xpInLevel);
            ps.setLong(8, xpNext);
            ps.executeUpdate();
        }
    }

    private void insertXpEvent(
            Connection conn,
            Long idUsuario,
            int xp,
            Integer nivelAnterior,
            Integer nivelNuevo,
            String codigoLogro,
            String tituloLogro,
            String descLogro,
            long totalAfter,
            long xpInLevel,
            long xpNext
    ) throws SQLException {
        String sql = """
                INSERT INTO usuario_progreso_eventos (
                    id_usuario, tipo, cantidad_xp, nivel_anterior, nivel_nuevo,
                    codigo_logro, titulo_logro, descripcion_logro,
                    xp_total_despues, xp_en_nivel_despues, xp_para_siguiente_despues
                ) VALUES (?, 'XP', ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setInt(2, xp);
            if (nivelAnterior != null) {
                ps.setInt(3, nivelAnterior);
            } else {
                ps.setNull(3, java.sql.Types.INTEGER);
            }
            if (nivelNuevo != null) {
                ps.setInt(4, nivelNuevo);
            } else {
                ps.setNull(4, java.sql.Types.INTEGER);
            }
            ps.setString(5, codigoLogro);
            ps.setString(6, tituloLogro);
            ps.setString(7, descLogro);
            ps.setLong(8, totalAfter);
            ps.setLong(9, xpInLevel);
            ps.setLong(10, xpNext);
            ps.executeUpdate();
        }
    }

    private void insertLevelUpEvent(
            Connection conn,
            Long idUsuario,
            int levelBefore,
            int levelAfter,
            long totalAfter,
            long xpInLevel,
            long xpNext
    ) throws SQLException {
        String sql = """
                INSERT INTO usuario_progreso_eventos (
                    id_usuario, tipo, nivel_anterior, nivel_nuevo,
                    xp_total_despues, xp_en_nivel_despues, xp_para_siguiente_despues
                ) VALUES (?, 'LEVEL_UP', ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setInt(2, levelBefore);
            ps.setInt(3, levelAfter);
            ps.setLong(4, totalAfter);
            ps.setLong(5, xpInLevel);
            ps.setLong(6, xpNext);
            ps.executeUpdate();
        }
    }

    private UserProgressResponse buildProgressResponse(Connection conn, Long idUsuario) throws SQLException {
        long totalXp;
        int level;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(experiencia, 0) AS experiencia, nivel FROM usuarios WHERE id = ?")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Usuario no encontrado");
                }
                totalXp = rs.getLong("experiencia");
                level = rs.getInt("nivel");
            }
        }
        long xpInLevel = AccountLevelMath.xpIntoCurrentLevel(totalXp);
        long xpNext = AccountLevelMath.xpForNextLevelFromTotal(totalXp);
        Map<String, Instant> unlocked = loadUnlockedAchievements(conn, idUsuario);
        int leagueWins = countLeagueWins(conn, idUsuario);
        int maxPacksInLeague = countMaxPackOpensInAnyLeague(conn, idUsuario);
        int friendCount = countAcceptedFriends(conn, idUsuario);
        int signedPlayers = userPublicProfileService.countSignedPlayersInFinishedLeagues(conn, idUsuario);
        int catalogPlayers = userPublicProfileService.countCatalogPlayers(conn);
        int rosterPercent = catalogPlayers > 0
                ? Math.min(100, (signedPlayers * 100) / catalogPlayers)
                : 0;
        List<UserAchievementResponse> achievements = new ArrayList<>();
        for (AchievementCode def : AchievementCode.values()) {
            Instant at = unlocked.get(def.code());
            Integer target = def.progressTarget();
            Integer actual = resolveProgressActual(
                    def, target, leagueWins, maxPacksInLeague, friendCount, rosterPercent
            );
            achievements.add(UserAchievementResponse.fromDefinition(def, at != null, at, actual, target));
        }
        List<UserProgressEventResponse> pending = loadPendingEvents(conn, idUsuario);
        return new UserProgressResponse(
                idUsuario,
                level,
                totalXp,
                xpInLevel,
                xpNext,
                AccountLevelMath.rankTitle(level),
                achievements,
                pending
        );
    }

    private List<UserProgressEventResponse> loadPendingEvents(Connection conn, Long idUsuario) throws SQLException {
        List<UserProgressEventResponse> out = new ArrayList<>();
        String sql = """
                SELECT id, tipo, cantidad_xp, nivel_anterior, nivel_nuevo,
                       codigo_logro, titulo_logro, descripcion_logro, xp_logro,
                       xp_total_despues, xp_en_nivel_despues, xp_para_siguiente_despues
                FROM usuario_progreso_eventos
                WHERE id_usuario = ? AND visto = FALSE
                ORDER BY id ASC
                LIMIT 20
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(new UserProgressEventResponse(
                            rs.getLong("id"),
                            rs.getString("tipo"),
                            (Integer) rs.getObject("cantidad_xp"),
                            (Integer) rs.getObject("nivel_anterior"),
                            (Integer) rs.getObject("nivel_nuevo"),
                            rs.getString("codigo_logro"),
                            rs.getString("titulo_logro"),
                            rs.getString("descripcion_logro"),
                            (Integer) rs.getObject("xp_logro"),
                            rs.getLong("xp_total_despues"),
                            rs.getLong("xp_en_nivel_despues"),
                            rs.getLong("xp_para_siguiente_despues")
                    ));
                }
            }
        }
        return out;
    }

    private Map<String, Instant> loadUnlockedAchievements(Connection conn, Long idUsuario) throws SQLException {
        Map<String, Instant> map = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT codigo_logro, desbloqueado_en FROM usuario_logros WHERE id_usuario = ?")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Timestamp ts = rs.getTimestamp("desbloqueado_en");
                    map.put(rs.getString("codigo_logro"), ts != null ? ts.toInstant() : null);
                }
            }
        }
        return map;
    }

    private boolean hasAchievement(Connection conn, Long idUsuario, AchievementCode code) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM usuario_logros WHERE id_usuario = ? AND codigo_logro = ? LIMIT 1")) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code.code());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void insertAchievement(Connection conn, Long idUsuario, AchievementCode code, Long idLiga)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO usuario_logros (id_usuario, codigo_logro, id_liga) VALUES (?, ?, ?)")) {
            ps.setLong(1, idUsuario);
            ps.setString(2, code.code());
            if (idLiga != null) {
                ps.setLong(3, idLiga);
            } else {
                ps.setNull(3, java.sql.Types.BIGINT);
            }
            ps.executeUpdate();
        }
    }

    private long loadTotalXp(Connection conn, Long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT experiencia FROM usuarios WHERE id = ?")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    public void onFriendshipAccepted(Long idUsuario) throws SQLException {
        if (idUsuario == null) {
            return;
        }
        try (Connection conn = DBConnection.getConnection()) {
            int friends = countAcceptedFriends(conn, idUsuario);
            if (friends >= 1) {
                tryUnlock(conn, idUsuario, AchievementCode.FRIEND_1, null);
            }
            if (friends >= 5) {
                tryUnlock(conn, idUsuario, AchievementCode.FRIEND_5, null);
            }
            if (friends >= 15) {
                tryUnlock(conn, idUsuario, AchievementCode.FRIEND_15, null);
            }
        }
    }

    private int countAcceptedFriends(Connection conn, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COUNT(*) FROM usuario_amistades
                WHERE estado = 'ACEPTADA'
                  AND (id_usuario_solicitante = ? OR id_usuario_destinatario = ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            ps.setLong(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private Integer resolveProgressActual(
            AchievementCode def,
            Integer target,
            int leagueWins,
            int maxPacksInLeague,
            int friendCount,
            int rosterPercent
    ) {
        if (target == null) {
            return null;
        }
        return switch (def) {
            case WIN_LEAGUE_1, WIN_LEAGUE_3, WIN_LEAGUE_5, WIN_LEAGUE_10, WIN_LEAGUE_30 ->
                    Math.min(leagueWins, target);
            case PACKS_5, PACKS_10, PACKS_15, PACKS_20 ->
                    Math.min(maxPacksInLeague, target);
            case FRIEND_1, FRIEND_5, FRIEND_15 ->
                    Math.min(friendCount, target);
            case FAVORITE_ROSTER_HALF, FAVORITE_ROSTER_COMPLETE ->
                    Math.min(rosterPercent, target);
            default -> null;
        };
    }

    private int countMaxPackOpensInAnyLeague(Connection conn, Long idUsuario) throws SQLException {
        String sql = """
                SELECT COALESCE(MAX(cnt), 0) AS max_cnt
                FROM (
                    SELECT COUNT(*) AS cnt
                    FROM liga_recompensa_eventos e
                    INNER JOIN liga_participantes lp ON lp.id = e.id_liga_participante
                    WHERE lp.id_usuario = ? AND e.tipo = 'PACK_OPENED'
                    GROUP BY lp.id
                ) t
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("max_cnt") : 0;
            }
        }
    }

    private int countPackOpens(Connection conn, Long idLigaParticipante) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                """
                SELECT COUNT(*) FROM liga_recompensa_eventos
                WHERE id_liga_participante = ? AND tipo = 'PACK_OPENED'
                """)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private int countActiveProtections(Connection conn, Long idLigaParticipante) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                """
                SELECT COUNT(*) FROM liga_jugador_protecciones p
                INNER JOIN liga_jugadores lj ON lj.id = p.id_liga_jugador
                WHERE p.id_liga_participante = ? AND p.activo = TRUE
                """)) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private long loadSecondHighestBid(Connection conn, Long idMercadoDiario) throws SQLException {
        String sql = """
                SELECT cantidad FROM pujas
                WHERE id_mercado_diario = ?
                ORDER BY cantidad DESC, fecha ASC, id ASC
                LIMIT 1 OFFSET 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idMercadoDiario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("cantidad") : 0L;
            }
        }
    }

    private boolean isLeagueEligibleForProgress(Connection conn, Long idLiga, LeagueMeta meta) throws SQLException {
        if (meta.finalizedRounds() < 1) {
            return false;
        }
        List<Long> participantIds = loadParticipantIds(conn, idLiga);
        if (participantIds.size() < MIN_LEAGUE_PARTICIPANTS) {
            return false;
        }
        Set<Long> kicked = loadKickedUserIds(conn, idLiga);
        int eligible = 0;
        for (Long lpId : participantIds) {
            ParticipantInfo p = loadParticipantInfo(conn, lpId);
            if (p == null || p.idUsuario() == null) {
                continue;
            }
            if (kicked.contains(p.idUsuario())) {
                continue;
            }
            if (!playedAllFinalizedRounds(conn, lpId, idLiga, meta.finalizedRoundIds())) {
                continue;
            }
            eligible++;
        }
        return eligible >= MIN_LEAGUE_PARTICIPANTS;
    }

    private boolean playedAllFinalizedRounds(
            Connection conn,
            Long idLigaParticipante,
            Long idLiga,
            List<Long> roundIds
    ) throws SQLException {
        if (roundIds.isEmpty()) {
            return false;
        }
        for (Long idJornada : roundIds) {
            if (!hasSavedLineup(conn, idLigaParticipante, idJornada)) {
                return false;
            }
        }
        return true;
    }

    private boolean hasSavedLineup(Connection conn, Long idLigaParticipante, Long idJornada) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                """
                SELECT 1 FROM alineacion_jornada_participante_config
                WHERE id_liga_participante = ? AND id_jornada = ?
                LIMIT 1
                """)) {
            ps.setLong(1, idLigaParticipante);
            ps.setLong(2, idJornada);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Set<Long> loadKickedUserIds(Connection conn, Long idLiga) throws SQLException {
        Set<Long> out = new HashSet<>();
        try (PreparedStatement ps = conn.prepareStatement(
                """
                SELECT DISTINCT id_actor_usuario FROM liga_actividad
                WHERE id_liga = ? AND tipo = 'ADMIN_KICK' AND id_liga_participante_objetivo IS NOT NULL
                """)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    // objetivo es participante, no usuario — consultar participante
                }
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(
                """
                SELECT DISTINCT lp.id_usuario
                FROM liga_actividad a
                INNER JOIN liga_participantes lp ON lp.id = a.id_liga_participante_objetivo
                WHERE a.id_liga = ? AND a.tipo = 'ADMIN_KICK'
                """)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(rs.getLong("id_usuario"));
                }
            }
        }
        return out;
    }

    private List<Long> loadParticipantIds(Connection conn, Long idLiga) throws SQLException {
        List<Long> ids = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM liga_participantes WHERE id_liga = ?")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("id"));
                }
            }
        }
        return ids;
    }

    private ParticipantInfo loadParticipantInfo(Connection conn, Long idLigaParticipante) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id_usuario FROM liga_participantes WHERE id = ?")) {
            ps.setLong(1, idLigaParticipante);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new ParticipantInfo(idLigaParticipante, rs.getLong("id_usuario"));
            }
        }
    }

    private String loadLeagueName(Connection conn, Long idLiga) throws SQLException {
        if (idLiga == null) {
            return null;
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT nombre FROM ligas WHERE id = ?")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("nombre") : null;
            }
        }
    }

    private LeagueMeta loadLeagueMeta(Connection conn, Long idLiga) throws SQLException {
        boolean idaYVuelta = true;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT ida_y_vuelta FROM ligas WHERE id = ?")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                idaYVuelta = rs.getBoolean("ida_y_vuelta");
            }
        }
        List<Long> finalized = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM jornadas WHERE id_liga = ? AND estado = 'FINALIZADA' ORDER BY numero ASC")) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    finalized.add(rs.getLong("id"));
                }
            }
        }
        return new LeagueMeta(idaYVuelta, finalized.size(), finalized);
    }

    private List<StandingRow> loadFinalStandings(Connection conn, Long idLiga) throws SQLException {
        List<StandingRow> rows = new ArrayList<>();
        String sql = """
                SELECT lp.id AS id_lp, lp.id_usuario, lp.puntos_totales,
                       ROW_NUMBER() OVER (ORDER BY lp.puntos_totales DESC, lp.id ASC) AS pos
                FROM liga_participantes lp
                WHERE lp.id_liga = ?
                ORDER BY pos ASC
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            try (ResultSet rs = ps.executeQuery()) {
                int pos = 0;
                while (rs.next()) {
                    pos++;
                    rows.add(new StandingRow(
                            pos,
                            rs.getLong("id_lp"),
                            rs.getLong("id_usuario"),
                            rs.getInt("puntos_totales")
                    ));
                }
            }
        }
        return rows;
    }

    private record LeagueMeta(boolean idaYVuelta, int finalizedRounds, List<Long> finalizedRoundIds) {}

    private record ParticipantInfo(Long idLigaParticipante, Long idUsuario) {}

    private record StandingRow(int posicion, Long idLigaParticipante, Long idUsuario, int puntosTotales) {}
}
