package com.eternalxi.eternalxi_api.dto.league;

public record LeagueSeasonWrapPlayerHighlight(
        Long idJugador,
        String nombre,
        String pila,
        String nombreMostrado,
        String fotoJugador,
        int valor
) {
}
