package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.user.EligibleFavoritePlayerResponse;
import com.eternalxi.eternalxi_api.dto.user.UserPublicFavoritePlayerResponse;
import com.eternalxi.eternalxi_api.dto.user.UserPublicLeagueSummaryResponse;
import com.eternalxi.eternalxi_api.dto.user.UserPublicProfileResponse;
import com.eternalxi.eternalxi_api.dto.user.UserPublicStatsResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import com.eternalxi.eternalxi_api.util.UserPublicTag;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
public class UserPublicProfileService {

    private final LeagueSeasonService leagueSeasonService;
    private final AccountProgressService accountProgressService;

    public UserPublicProfileService(
            LeagueSeasonService leagueSeasonService,
            AccountProgressService accountProgressService
    ) {
        this.leagueSeasonService = leagueSeasonService;
        this.accountProgressService = accountProgressService;
    }

    public UserPublicProfileResponse loadProfile(Long viewerId, Long targetId) throws SQLException {
        if (targetId == null || targetId <= 0) {
            throw new IllegalArgumentException("Usuario no valido");
        }

        try (Connection conn = DBConnection.getConnection()) {
            String userSql = """
                    SELECT u.id, u.nickname, COALESCE(u.foto, '') AS foto, u.nivel,
                           u.id_jugador_favorito
                    FROM usuarios u
                    WHERE u.id = ?
                    LIMIT 1
                    """;
            long id;
            String nickname;
            String foto;
            int nivel;
            Long favoritePlayerId;
            try (PreparedStatement ps = conn.prepareStatement(userSql)) {
                ps.setLong(1, targetId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Usuario no encontrado");
                    }
                    id = rs.getLong("id");
                    nickname = rs.getString("nickname");
                    foto = LeagueAssetUrls.userPhotoIfStored(id, rs.getString("foto"));
                    nivel = rs.getInt("nivel");
                    long favRaw = rs.getLong("id_jugador_favorito");
                    favoritePlayerId = rs.wasNull() ? null : favRaw;
                }
            }

            FriendshipRelation relation = loadFriendshipRelation(conn, viewerId, targetId);
            UserPublicStatsResponse stats = loadStats(conn, targetId);
            UserPublicFavoritePlayerResponse favorite = loadFavoritePlayer(conn, favoritePlayerId);
            List<UserPublicLeagueSummaryResponse> leagues = loadLeagues(conn, targetId);

            return new UserPublicProfileResponse(
                    id,
                    nickname,
                    foto,
                    nivel,
                    UserPublicTag.codeForUserId(id),
                    relation.estado(),
                    relation.idAmistad(),
                    relation.soySolicitante(),
                    stats,
                    favorite,
                    leagues
            );
        }
    }

    public void updateFavoritePlayer(Long userId, Long idJugador) throws SQLException {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Usuario no valido");
        }
        try (Connection conn = DBConnection.getConnection()) {
            if (idJugador != null && idJugador > 0) {
                if (!isEligibleFavoritePlayer(conn, userId, idJugador)) {
                    throw new IllegalArgumentException(
                            "Solo puedes elegir jugadores de Eterno Campeon que hayas alineado en una jornada ya iniciada"
                    );
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE usuarios SET id_jugador_favorito = ? WHERE id = ?")) {
                if (idJugador == null || idJugador <= 0) {
                    ps.setNull(1, java.sql.Types.INTEGER);
                } else {
                    ps.setLong(1, idJugador);
                }
                ps.setLong(2, userId);
                ps.executeUpdate();
            }
            accountProgressService.syncFavoriteRosterAchievements(
                    conn,
                    userId,
                    countSignedPlayersInFinishedLeagues(conn, userId),
                    countCatalogPlayers(conn)
            );
        }
    }

    public List<EligibleFavoritePlayerResponse> listEligibleFavoritePlayers(Long userId) throws SQLException {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Usuario no valido");
        }
        try (Connection conn = DBConnection.getConnection()) {
            return loadEligibleFavoritePlayers(conn, userId);
        }
    }

    public int countSignedPlayersInFinishedLeagues(Connection conn, long userId) throws SQLException {
        String sql = """
                SELECT COUNT(DISTINCT lj.id_jugador) AS total
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                INNER JOIN liga_jugadores lj
                  ON lj.id_liga = lp.id_liga
                 AND lj.id_usuario_dueno = lp.id_usuario
                WHERE lp.id_usuario = ?
                  AND l.cerrada_en IS NULL
                  AND """
                + LeagueSeasonService.sqlSeasonNaturallyCompleteOnLeagueAlias("l");
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    public int countCatalogPlayers(Connection conn) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) AS total FROM jugadores");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt("total") : 0;
        }
    }

    public Long findUserIdByTagCode(int tagCode) throws SQLException {
        String sql = """
                SELECT id
                FROM usuarios
                WHERE ((id * 7919 + 104729) % 900000 + 100000) = ?
                LIMIT 1
                """;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tagCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getLong("id");
            }
        }
    }

    public UserPublicStatsResponse loadCareerStats(Connection conn, long userId) throws SQLException {
        return loadStats(conn, userId);
    }

    public UserPublicStatsResponse loadCareerStats(long userId) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            return loadStats(conn, userId);
        }
    }

    private UserPublicStatsResponse loadStats(Connection conn, long userId) throws SQLException {
        String sql = """
                SELECT
                    COALESCE(SUM(jpj.goles), 0) AS goles,
                    COALESCE(SUM(jpj.asistencias), 0) AS asistencias,
                    COALESCE(SUM(jpj.porteria_cero), 0) AS porterias_cero,
                    COALESCE(SUM(CASE WHEN jpj.lesionado_en_partido = 1 THEN 1 ELSE 0 END), 0) AS lesiones,
                    COALESCE(SUM(jpj.tarjetas_amarillas + jpj.tarjetas_rojas), 0) AS sanciones
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                INNER JOIN liga_jugadores lj
                  ON lj.id_liga = lp.id_liga
                 AND lj.id_usuario_dueno = lp.id_usuario
                INNER JOIN jugadores_puntos_jornada jpj ON jpj.id_liga_jugador = lj.id
                WHERE lp.id_usuario = ?
                  AND"""
                + LeagueSeasonService.sqlLeagueEligibleForCareerStats("l");
        int goles = 0;
        int asistencias = 0;
        int porteriasCero = 0;
        int lesiones = 0;
        int sanciones = 0;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    goles = rs.getInt("goles");
                    asistencias = rs.getInt("asistencias");
                    porteriasCero = rs.getInt("porterias_cero");
                    lesiones = rs.getInt("lesiones");
                    sanciones = rs.getInt("sanciones");
                }
            }
        }

        int ligasGanadas = 0;
        String wonSql = """
                SELECT COUNT(*) AS total
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                WHERE lp.id_usuario = ?
                  AND """ + LeagueSeasonService.sqlLeagueEligibleForCareerStats("l") + """
                  AND """ + LeagueSeasonService.sqlSeasonNaturallyCompleteOnLeagueAlias("l") + """
                  AND lp.puntos_totales + COALESCE((
                      SELECT SUM(pb.puntos)
                      FROM liga_participante_puntos_bonus pb
                      WHERE pb.id_liga_participante = lp.id
                  ), 0) = (
                      SELECT MAX(lp2.puntos_totales + COALESCE((
                          SELECT SUM(pb2.puntos)
                          FROM liga_participante_puntos_bonus pb2
                          WHERE pb2.id_liga_participante = lp2.id
                      ), 0))
                      FROM liga_participantes lp2
                      WHERE lp2.id_liga = lp.id_liga
                  )
                """;
        try (PreparedStatement ps = conn.prepareStatement(wonSql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ligasGanadas = rs.getInt("total");
                }
            }
        }

        return new UserPublicStatsResponse(
                ligasGanadas,
                goles,
                asistencias,
                porteriasCero,
                lesiones,
                sanciones
        );
    }

    private List<UserPublicLeagueSummaryResponse> loadLeagues(Connection conn, long userId)
            throws SQLException {
        String sql = """
                SELECT lp.id AS id_lp, lp.id_liga, lp.puntos_totales,
                       COALESCE(l.nombre, CONCAT('Liga ', l.id)) AS nombre_liga,
                       'FINALIZADA' AS estado_liga
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                WHERE lp.id_usuario = ?
                  AND """ + LeagueSeasonService.sqlLeagueEligibleForCareerStats("l") + """
                  AND """ + LeagueSeasonService.sqlSeasonNaturallyCompleteOnLeagueAlias("l") + """
                ORDER BY lp.id DESC
                LIMIT 30
                """;
        List<UserPublicLeagueSummaryResponse> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long idLiga = rs.getLong("id_liga");
                    LeagueSeasonService.StandingRow standing =
                            leagueSeasonService.loadParticipantStanding(conn, idLiga, userId);
                    int posicion = standing != null ? standing.posicion() : 0;
                    int total = standing != null ? standing.totalParticipantes() : 0;
                    var goleador = leagueSeasonService.loadSquadTopStat(
                            conn, idLiga, userId, LeagueSeasonService.SquadMetric.GOLES);
                    var asistente = leagueSeasonService.loadSquadTopStat(
                            conn, idLiga, userId, LeagueSeasonService.SquadMetric.ASISTENCIAS);
                    var portero = leagueSeasonService.loadSquadTopStat(
                            conn, idLiga, userId, LeagueSeasonService.SquadMetric.PORTERIAS_CERO);
                    rows.add(new UserPublicLeagueSummaryResponse(
                            idLiga,
                            rs.getString("nombre_liga"),
                            rs.getLong("id_lp"),
                            rs.getString("estado_liga"),
                            rs.getInt("puntos_totales"),
                            posicion,
                            total,
                            goleador,
                            asistente,
                            portero
                    ));
                }
            }
        }
        return rows;
    }

    private UserPublicFavoritePlayerResponse loadFavoritePlayer(Connection conn, Long idJugador)
            throws SQLException {
        if (idJugador == null || idJugador <= 0) {
            return null;
        }
        String sql = """
                SELECT j.id, j.nombre, COALESCE(j.foto, '') AS foto,
                       COALESCE(e.nombre, '') AS equipo
                FROM jugadores j
                LEFT JOIN equipos e ON e.id = j.id_equipo
                WHERE j.id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idJugador);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                long id = rs.getLong("id");
                String nombre = rs.getString("nombre");
                String fotoRaw = rs.getString("foto");
                String foto = LeagueAssetUrls.coercePublicAsset(fotoRaw, LeagueAssetUrls.player(id));
                return new UserPublicFavoritePlayerResponse(
                        id,
                        nombre,
                        foto,
                        rs.getString("equipo")
                );
            }
        }
    }

    private FriendshipRelation loadFriendshipRelation(Connection conn, Long viewerId, long targetId)
            throws SQLException {
        if (viewerId == null || viewerId <= 0 || viewerId == targetId) {
            return new FriendshipRelation("NINGUNA", null, false);
        }
        String sql = """
                SELECT id, estado, (id_usuario_solicitante = ?) AS soy_solicitante
                FROM usuario_amistades
                WHERE (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                   OR (id_usuario_solicitante = ? AND id_usuario_destinatario = ?)
                ORDER BY id DESC
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, viewerId);
            ps.setLong(2, viewerId);
            ps.setLong(3, targetId);
            ps.setLong(4, targetId);
            ps.setLong(5, viewerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return new FriendshipRelation("NINGUNA", null, false);
                }
                return new FriendshipRelation(
                        rs.getString("estado"),
                        rs.getLong("id"),
                        rs.getBoolean("soy_solicitante")
                );
            }
        }
    }

    private record FriendshipRelation(String estado, Long idAmistad, boolean soySolicitante) {}

    /**
     * Jornada con alineación fantasy congelada (ya empezó por hora o estado de partidos).
     * Espacio inicial por stripping de text blocks Java.
     */
    static String sqlJornadaLineupFrozenOnAlias(String jornadaAlias) {
        return " (" + jornadaAlias + ".estado IN ('EN_CURSO', 'FINALIZADA') OR EXISTS ("
                + "SELECT 1 FROM partidos_jornada pj_fz WHERE pj_fz.id_jornada = " + jornadaAlias + ".id "
                + "AND (COALESCE(pj_fz.estado, '') IN ('EN_JUEGO', 'FINALIZADO') "
                + "OR pj_fz.inicio_en <= NOW()))) ";
    }

    private Long resolveEternoCampeonSeasonId(Connection conn) throws SQLException {
        String sql = """
                SELECT tt.id_temporada
                FROM temporada_traduccion tt
                WHERE tt.locale = 'es' AND tt.nombre = 'Eterno Campeon'
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }
            return rs.getLong("id_temporada");
        }
    }

    private boolean isEligibleFavoritePlayer(Connection conn, long userId, long idJugador)
            throws SQLException {
        Long seasonId = resolveEternoCampeonSeasonId(conn);
        if (seasonId == null) {
            return false;
        }
        String sql = """
                SELECT 1
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                INNER JOIN liga_jugadores lj
                  ON lj.id_liga = lp.id_liga
                 AND lj.id_usuario_dueno = lp.id_usuario
                INNER JOIN alineacion_jornada_participante ajp
                  ON ajp.id_liga_participante = lp.id
                 AND ajp.id_liga_jugador = lj.id
                INNER JOIN jornadas jrn
                  ON jrn.id = ajp.id_jornada
                 AND jrn.id_liga = lp.id_liga
                WHERE lp.id_usuario = ?
                  AND lj.id_jugador = ?
                  AND l.id_temporada = ?
                  AND """
                + sqlJornadaLineupFrozenOnAlias("jrn")
                + """
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setLong(2, idJugador);
            ps.setLong(3, seasonId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private List<EligibleFavoritePlayerResponse> loadEligibleFavoritePlayers(Connection conn, long userId)
            throws SQLException {
        Long seasonId = resolveEternoCampeonSeasonId(conn);
        if (seasonId == null) {
            return List.of();
        }
        String sql = """
                SELECT DISTINCT j.id,
                       COALESCE(NULLIF(TRIM(j.pila), ''), j.nombre) AS nombre,
                       COALESCE(j.foto, '') AS foto,
                       e.id AS id_equipo,
                       COALESCE(e.nombre, '') AS equipo,
                       COALESCE(e.foto, '') AS foto_equipo
                FROM liga_participantes lp
                INNER JOIN ligas l ON l.id = lp.id_liga
                INNER JOIN liga_jugadores lj
                  ON lj.id_liga = lp.id_liga
                 AND lj.id_usuario_dueno = lp.id_usuario
                INNER JOIN alineacion_jornada_participante ajp
                  ON ajp.id_liga_participante = lp.id
                 AND ajp.id_liga_jugador = lj.id
                INNER JOIN jornadas jrn
                  ON jrn.id = ajp.id_jornada
                 AND jrn.id_liga = lp.id_liga
                INNER JOIN jugadores j ON j.id = lj.id_jugador
                INNER JOIN equipos e ON e.id = j.id_equipo
                WHERE lp.id_usuario = ?
                  AND l.id_temporada = ?
                  AND e.id_temporada = ?
                  AND """
                + sqlJornadaLineupFrozenOnAlias("jrn")
                + """
                ORDER BY equipo ASC, nombre ASC
                """;
        List<EligibleFavoritePlayerResponse> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setLong(2, seasonId);
            ps.setLong(3, seasonId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long id = rs.getLong("id");
                    String fotoRaw = rs.getString("foto");
                    String foto = LeagueAssetUrls.coercePublicAsset(fotoRaw, LeagueAssetUrls.player(id));
                    long idEquipo = rs.getLong("id_equipo");
                    String fotoEquipoRaw = rs.getString("foto_equipo");
                    String fotoEquipo = LeagueAssetUrls.coercePublicAsset(
                            fotoEquipoRaw,
                            LeagueAssetUrls.team(idEquipo)
                    );
                    rows.add(new EligibleFavoritePlayerResponse(
                            id,
                            rs.getString("nombre"),
                            foto,
                            idEquipo,
                            rs.getString("equipo"),
                            fotoEquipo
                    ));
                }
            }
        }
        return rows;
    }
}
