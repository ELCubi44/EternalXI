package com.eternalxi.eternalxi_api.util;

/**
 * URLs públicas de imágenes para respuestas API de liga.
 * Nunca exponer rutas de filesystem ({@code /opt/eternalxi/...}).
 */
public final class LeagueAssetUrls {

    public static final String TEAMS = "/api/v1/assets/teams/";
    public static final String PLAYERS = "/api/v1/assets/players/";
    public static final String MANAGERS = "/api/v1/assets/managers/";
    public static final String LOAN_PLAYERS = "/api/v1/assets/loan-players/";
    public static final String SEASONS = "/api/v1/assets/seasons/";
    public static final String USERS = "/api/v1/users/";

    private LeagueAssetUrls() {
    }

    public static String team(Long idEquipo) {
        if (idEquipo == null || idEquipo <= 0) {
            return null;
        }
        return TEAMS + idEquipo;
    }

    public static String team(Integer idEquipo) {
        return idEquipo == null ? null : team(idEquipo.longValue());
    }

    public static String player(Long idJugador) {
        if (idJugador == null || idJugador <= 0) {
            return null;
        }
        return PLAYERS + idJugador;
    }

    public static String manager(Long idEntrenador) {
        if (idEntrenador == null || idEntrenador <= 0) {
            return null;
        }
        return MANAGERS + idEntrenador;
    }

    public static String loanPlayer(Integer idJugadorCedidoTemporada) {
        if (idJugadorCedidoTemporada == null || idJugadorCedidoTemporada <= 0) {
            return null;
        }
        return LOAN_PLAYERS + idJugadorCedidoTemporada;
    }

    public static String season(Long idTemporada) {
        if (idTemporada == null || idTemporada <= 0) {
            return null;
        }
        return SEASONS + idTemporada;
    }

    public static String userPhoto(Long idUsuario) {
        if (idUsuario == null || idUsuario <= 0) {
            return null;
        }
        return USERS + idUsuario + "/photo";
    }

    /** URL pública de perfil si el usuario tiene fichero guardado (no el nombre en disco). */
    public static String userPhotoIfStored(Long idUsuario, String storedFoto) {
        if (storedFoto == null || storedFoto.isBlank()) {
            return null;
        }
        return userPhoto(idUsuario);
    }

    public static String playerOrLoan(Long idJugador, Integer idJugadorCedidoTemporada) {
        if (idJugadorCedidoTemporada != null) {
            return loanPlayer(idJugadorCedidoTemporada);
        }
        return player(idJugador);
    }

    /**
     * Devuelve {@code apiPath} si ya es una URL de assets; si no, {@code fallback}.
     */
    public static String coercePublicAsset(String apiPath, String fallback) {
        if (isPublicAssetPath(apiPath)) {
            return apiPath;
        }
        return fallback;
    }

    public static boolean isPublicAssetPath(String value) {
        return value != null && value.startsWith("/api/v1/assets/");
    }

    public static boolean isFilesystemOrLegacyPath(String value) {
        if (value == null || value.isBlank()) {
            return false;
        }
        String t = value.trim();
        return t.startsWith("/opt/")
                || t.contains("/eternalxi/teams/")
                || t.contains("/eternalxi/jugadores/")
                || t.contains("/eternalxi/entrenadores/")
                || (t.startsWith("/") && !isPublicAssetPath(t));
    }
}
