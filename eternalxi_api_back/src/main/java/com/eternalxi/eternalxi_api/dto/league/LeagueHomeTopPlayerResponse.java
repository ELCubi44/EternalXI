package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueHomeTopPlayerResponse(
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String nombreMostrado,
        String posicion,
        Integer valoracion,
        Long idEquipo,
        String nombreEquipo,
        String fotoJugador,
        String fotoEquipo,
        Integer total,
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad
) {
}