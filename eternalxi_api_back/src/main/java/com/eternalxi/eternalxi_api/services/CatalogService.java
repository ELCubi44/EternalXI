package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamCoachResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamPlayerResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamSquadResponse;
import com.eternalxi.eternalxi_api.dto.catalog.CatalogTeamResponse;
import com.eternalxi.eternalxi_api.dto.catalog.SeasonResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.springframework.stereotype.Service;


import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
public class CatalogService {
    public List<SeasonResponse> listSeasons() throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT id, nombre, foto
                    FROM temporadas
                    ORDER BY id ASC
                    """;

            List<SeasonResponse> seasons = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    seasons.add(new SeasonResponse(
                            rs.getLong("id"),
                            rs.getString("nombre"),
                            rs.getString("foto")
                    ));
                }
            }

            return seasons;
        }
    }

    public List<CatalogTeamResponse> listTeamsBySeason(Long seasonId) throws SQLException {
        if (seasonId == null) {
            throw new IllegalArgumentException("Falta seasonId");
        }

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                    SELECT id, nombre, id_temporada, foto
                    FROM equipos
                    WHERE id_temporada = ?
                    ORDER BY id ASC
                    """;

            List<CatalogTeamResponse> teams = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, seasonId);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long teamId = rs.getLong("id");
                        String teamPhoto = LeagueAssetUrls.team(teamId);
                        teams.add(new CatalogTeamResponse(
                                teamId,
                                rs.getString("nombre"),
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

    public List<CatalogTeamPlayerResponse> listPlayersByTeam(Long idEquipo, Long seasonId) throws SQLException {
        if (idEquipo == null) {
            throw new IllegalArgumentException("Falta idEquipo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            ensureTeamExists(conn, idEquipo);

            if (seasonId != null) {
                ensureTeamBelongsToSeason(conn, idEquipo, seasonId);
            }

            String sql = """
                    SELECT id,
                           id_equipo,
                           nombre,
                           pila,
                           dorsal,
                           descripcion,
                           valoracion,
                           genero,
                           posicion,
                           foto
                    FROM jugadores
                    WHERE id_equipo = ?
                    ORDER BY dorsal ASC, id ASC
                    """;

            List<CatalogTeamPlayerResponse> players = new ArrayList<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, idEquipo);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Integer dorsal = rs.getObject("dorsal", Integer.class);
                        Integer valoracion = rs.getObject("valoracion", Integer.class);

                        long playerId = rs.getLong("id");
                        String playerPhoto = LeagueAssetUrls.player(playerId);
                        players.add(new CatalogTeamPlayerResponse(
                                playerId,
                                null,
                                rs.getLong("id_equipo"),
                                rs.getString("nombre"),
                                rs.getString("pila"),
                                dorsal,
                                rs.getString("descripcion"),
                                valoracion,
                                rs.getString("genero"),
                                rs.getString("posicion"),
                                playerPhoto,
                                playerPhoto,
                                null,
                                null,
                                null
                        ));
                    }
                }
            }

            return players;
        }
    }

    public CatalogTeamSquadResponse getTeamSquad(Long idEquipo, Long seasonId, Long idLiga) throws SQLException {
        if (idEquipo == null) {
            throw new IllegalArgumentException("Falta idEquipo");
        }

        try (Connection conn = DBConnection.getConnection()) {
            CatalogTeamResponse team = loadTeam(conn, idEquipo, seasonId);
            if (idLiga != null) {
                ensureTeamBelongsToLeague(conn, idEquipo, idLiga);
            }
            CatalogTeamCoachResponse coach = loadActiveCoachByTeam(conn, idEquipo);
            List<CatalogTeamPlayerResponse> players = loadPlayersByTeam(conn, idEquipo, idLiga);
            return new CatalogTeamSquadResponse(team, coach, players);
        }
    }

    private CatalogTeamResponse loadTeam(Connection conn, Long idEquipo, Long seasonId) throws SQLException {
        String sql = seasonId == null
                ? """
                SELECT id, nombre, id_temporada, foto
                FROM equipos
                WHERE id = ?
                LIMIT 1
                """
                : """
                SELECT id, nombre, id_temporada, foto
                FROM equipos
                WHERE id = ?
                  AND id_temporada = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idEquipo);
            if (seasonId != null) {
                ps.setLong(2, seasonId);
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

    private List<CatalogTeamPlayerResponse> loadPlayersByTeam(Connection conn, Long idEquipo, Long idLiga) throws SQLException {
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
                       j.descripcion,
                       j.valoracion,
                       j.genero,
                       j.posicion,
                       j.foto
                FROM jugadores j
                LEFT JOIN liga_jugadores lj
                  ON lj.id_jugador = j.id
                 AND lj.id_liga = ?
                WHERE j.id_equipo = ?
                ORDER BY j.dorsal ASC, j.id ASC
                """;

        List<CatalogTeamPlayerResponse> players = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (idLiga == null) {
                ps.setNull(1, java.sql.Types.BIGINT);
            } else {
                ps.setLong(1, idLiga);
            }
            ps.setLong(2, idEquipo);

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
