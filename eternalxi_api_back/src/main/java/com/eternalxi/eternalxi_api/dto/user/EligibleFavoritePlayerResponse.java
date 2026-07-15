package com.eternalxi.eternalxi_api.dto.user;

public record EligibleFavoritePlayerResponse(
        long idJugador,
        String nombre,
        String foto,
        String equipo
) {
}
