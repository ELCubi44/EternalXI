package com.eternalxi.eternalxi_api.dto.user;

public record UserPublicFavoritePlayerResponse(
        long idJugador,
        String nombre,
        String foto,
        String equipo
) {
}
