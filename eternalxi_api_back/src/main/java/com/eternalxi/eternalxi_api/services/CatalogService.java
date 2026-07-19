package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamCoachResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamPlayerResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamSquadResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamResponse;
import com.eternalxi.eternalxi_api.dto.catalog.SeasonResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import com.eternalxi.eternalxi_api.util.LocaleSupport;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
public class CatalogService {

    public List<SeasonResponse> listSeasons(String locale) throws SQLException {
        String resolvedLocale = resolveLocale(locale);
        try (Connection conn = DBConnection.getConnection()) {
            ensureTranslationSchema(conn);
            String sql = """
                    SELECT t.id,
                           COALESCE(tt.nombre, t.nombre) AS nombre,
                           t.foto
                    FROM temporadas t
                    LEFT JOIN temporada_traduccion tt
                      ON tt.id_temporada = t.id
                     AND tt.locale = ?
                    ORDER BY t.id ASC
                    """;

            List<SeasonResponse> seasons = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, resolvedLocale);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long seasonId = rs.getLong("id");
                        seasons.add(new SeasonResponse(
                                seasonId,
                                rs.getString("nombre"),
                                LeagueAssetUrls.season(seasonId)
                        ));
                    }
                }
            }

            return seasons;
        }
    }

    public List<CatalogTeamResponse> listTeamsBySeason(Long seasonId, String locale) throws SQLException {
        if (seasonId == null) {
            throw new IllegalArgumentException("Falta seasonId");
        }

        String resolvedLocale = resolveLocale(locale);
        try (Connection conn = DBConnection.getConnection()) {
            ensureTranslationSchema(conn);
            String sql = """
                    SELECT e.id,
                           COALESCE(et.nombre, e.nombre) AS nombre,
                           e.pais,
                           e.id_temporada,
                           e.foto
                    FROM equipos e
                    LEFT JOIN equipo_traduccion et
                      ON et.id_equipo = e.id
                     AND et.locale = ?
                    WHERE e.id_temporada = ?
                    ORDER BY e.id ASC
                    """;

            List<CatalogTeamResponse> teams = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, resolvedLocale);
                ps.setLong(2, seasonId);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long teamId = rs.getLong("id");
                        String teamPhoto = LeagueAssetUrls.team(teamId);
                        teams.add(new CatalogTeamResponse(
                                teamId,
                                rs.getString("nombre"),
                                rs.getString("pais"),
                                rs.getLong("id_temporada"),
                                teamPhoto,
                                teamPhoto
                        ));
                    }
                }
            }

            return teams;
        }
    }

    public List<CatalogTeamPlayerResponse> listPlayersByTeam(
            Long idEquipo,
            Long seasonId,
            String locale
    ) throws SQLException {
        if (idEquipo == null) {
            throw new IllegalArgumentException("Falta idEquipo");
        }

        String resolvedLocale = resolveLocale(locale);
        try (Connection conn = DBConnection.getConnection()) {
            ensureTranslationSchema(conn);
            ensureTeamExists(conn, idEquipo);

            if (seasonId != null) {
                ensureTeamBelongsToSeason(conn, idEquipo, seasonId);
            }

            return queryPlayersByTeam(conn, idEquipo, null, resolvedLocale);
        }
    }

    public CatalogTeamSquadResponse getTeamSquad(
            Long idEquipo,
            Long seasonId,
            Long idLiga,
            String locale
    ) throws SQLException {
        if (idEquipo == null) {
            throw new IllegalArgumentException("Falta idEquipo");
        }

        String resolvedLocale = resolveLocale(locale);
        try (Connection conn = DBConnection.getConnection()) {
            ensureTranslationSchema(conn);
            CatalogTeamResponse team = loadTeam(conn, idEquipo, seasonId, resolvedLocale);
            if (idLiga != null) {
                ensureTeamBelongsToLeague(conn, idEquipo, idLiga);
            }
            CatalogTeamCoachResponse coach = loadActiveCoachByTeam(conn, idEquipo);
            List<CatalogTeamPlayerResponse> players = queryPlayersByTeam(conn, idEquipo, idLiga, resolvedLocale);
            return new CatalogTeamSquadResponse(team, coach, players);
        }
    }

    private CatalogTeamResponse loadTeam(
            Connection conn,
            Long idEquipo,
            Long seasonId,
            String locale
    ) throws SQLException {
        String sql = seasonId == null
                ? """
                SELECT e.id,
                       COALESCE(et.nombre, e.nombre) AS nombre,
                       e.pais,
                       e.id_temporada,
                       e.foto
                FROM equipos e
                LEFT JOIN equipo_traduccion et
                  ON et.id_equipo = e.id
                 AND et.locale = ?
                WHERE e.id = ?
                LIMIT 1
                """
                : """
                SELECT e.id,
                       COALESCE(et.nombre, e.nombre) AS nombre,
                       e.pais,
                       e.id_temporada,
                       e.foto
                FROM equipos e
                LEFT JOIN equipo_traduccion et
                  ON et.id_equipo = e.id
                 AND et.locale = ?
                WHERE e.id = ?
                  AND e.id_temporada = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, locale);
            ps.setLong(2, idEquipo);
            if (seasonId != null) {
                ps.setLong(3, seasonId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            seasonId == null
                                    ? "Equipo no encontrado"
                                    : "El equipo no pertenece a la temporada indicada"
                    );
                }

                long teamId = rs.getLong("id");
                String teamPhoto = LeagueAssetUrls.team(teamId);
                return new CatalogTeamResponse(
                        teamId,
                        rs.getString("nombre"),
                        rs.getString("pais"),
                        rs.getLong("id_temporada"),
                        teamPhoto,
                        teamPhoto
                );
            }
        }
    }

    private CatalogTeamCoachResponse loadActiveCoachByTeam(Connection conn, Long idEquipo) throws SQLException {
        String sql = """
                SELECT id,
                       nombre,
                       pila,
                       formacion,
                       foto,
                       id_equipo,
                       id_temporada,
                       bonus_puntos,
                       activo
                FROM entrenadores
                WHERE id_equipo = ?
                  AND activo = TRUE
                ORDER BY id ASC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEquipo);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                long coachId = rs.getLong("id");
                String coachPhoto = LeagueAssetUrls.manager(coachId);
                return new CatalogTeamCoachResponse(
                        coachId,
                        rs.getString("nombre"),
                        rs.getString("pila"),
                        rs.getString("formacion"),
                        coachPhoto,
                        coachPhoto,
                        rs.getInt("id_equipo"),
                        rs.getInt("id_temporada"),
                        rs.getInt("bonus_puntos"),
                        rs.getBoolean("activo")
                );
            }
        }
    }

    private List<CatalogTeamPlayerResponse> queryPlayersByTeam(
            Connection conn,
            Long idEquipo,
            Long idLiga,
            String locale
    ) throws SQLException {
        final String valoracionExpr = idLiga != null
                ? "CAST(ROUND(COALESCE(lj.valoracion_actual, j.valoracion), 0) AS SIGNED)"
                : "j.valoracion";
        String sql = """
                SELECT j.id,
                       lj.id AS id_liga_jugador,
                       lj.valor,
                       lj.estado,
                       lj.id_usuario_dueno,
                       j.id_equipo,
                       j.nombre,
                       j.pila,
                       j.dorsal,
                       COALESCE(jt.descripcion, j.descripcion) AS descripcion,
                       %s AS valoracion,
                       j.genero,
                       j.posicion,
                       j.pais,
                       j.foto
                FROM jugadores j
                LEFT JOIN jugador_traduccion jt
                  ON jt.id_jugador = j.id
                 AND jt.locale = ?
                LEFT JOIN liga_jugadores lj
                  ON lj.id_jugador = j.id
                 AND lj.id_liga = ?
                WHERE j.id_equipo = ?
                ORDER BY j.dorsal ASC, j.id ASC
                """.formatted(valoracionExpr);

        List<CatalogTeamPlayerResponse> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, locale);
            if (idLiga == null) {
                ps.setNull(2, java.sql.Types.BIGINT);
            } else {
                ps.setLong(2, idLiga);
            }
            ps.setLong(3, idEquipo);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long playerId = rs.getLong("id");
                    String playerPhoto = LeagueAssetUrls.player(playerId);
                    players.add(new CatalogTeamPlayerResponse(
                            playerId,
                            rs.getObject("id_liga_jugador", Long.class),
                            rs.getLong("id_equipo"),
                            rs.getString("nombre"),
                            rs.getString("pila"),
                            rs.getObject("dorsal", Integer.class),
                            rs.getString("descripcion"),
                            rs.getObject("valoracion", Integer.class),
                            rs.getString("genero"),
                            rs.getString("posicion"),
                            rs.getString("pais"),
                            playerPhoto,
                            playerPhoto,
                            rs.getObject("valor", Long.class),
                            rs.getString("estado"),
                            rs.getObject("id_usuario_dueno", Long.class)
                    ));
                }
            }
        }

        return players;
    }

    private void ensureTranslationSchema(Connection conn) throws SQLException {
        conn.createStatement().execute("""
                CREATE TABLE IF NOT EXISTS temporada_traduccion (
                    id_temporada INT NOT NULL,
                    locale VARCHAR(5) NOT NULL,
                    nombre VARCHAR(100) NOT NULL,
                    PRIMARY KEY (id_temporada, locale)
                )
                """);
        conn.createStatement().execute("""
                CREATE TABLE IF NOT EXISTS equipo_traduccion (
                    id_equipo INT NOT NULL,
                    locale VARCHAR(5) NOT NULL,
                    nombre VARCHAR(120) NOT NULL,
                    PRIMARY KEY (id_equipo, locale)
                )
                """);
        conn.createStatement().execute("""
                CREATE TABLE IF NOT EXISTS jugador_traduccion (
                    id_jugador INT NOT NULL,
                    locale VARCHAR(5) NOT NULL,
                    descripcion TEXT NULL,
                    PRIMARY KEY (id_jugador, locale)
                )
                """);
    }

    private static String resolveLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return LocaleSupport.DEFAULT;
        }
        return LocaleSupport.fromAcceptLanguage(locale);
    }

    private void ensureTeamBelongsToLeague(Connection conn, Long idEquipo, Long idLiga) throws SQLException {
        String sql = """
                SELECT 1
                FROM liga_equipos le
                WHERE le.id_liga = ?
                  AND le.id_equipo = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idLiga);
            ps.setLong(2, idEquipo);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("El equipo no pertenece a la liga indicada");
                }
            }
        }
    }

    private void ensureTeamExists(Connection conn, Long idEquipo) throws SQLException {
        String sql = """
                SELECT 1
                FROM equipos
                WHERE id = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEquipo);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Equipo no encontrado");
                }
            }
        }
    }

    private void ensureTeamBelongsToSeason(Connection conn, Long idEquipo, Long seasonId) throws SQLException {
        String sql = """
                SELECT 1
                FROM equipos
                WHERE id = ?
                  AND id_temporada = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEquipo);
            ps.setLong(2, seasonId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("El equipo no pertenece a la temporada indicada");
                }
            }
        }
    }
}
