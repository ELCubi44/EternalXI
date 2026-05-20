package com.eternalxi.eternalxi_api.dto.league;

public record LeagueStarterProbabilityRowResponse(
        Long idPartidoJornada,
        Long idLigaEquipo,
        Long idEquipo,
        String equipoNombre,
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String posicion,
        Integer valoracion,
        String estado,
        Integer cansancio,
        Integer probabilidadTitular,
        String motivoTitularidad
) {
}
