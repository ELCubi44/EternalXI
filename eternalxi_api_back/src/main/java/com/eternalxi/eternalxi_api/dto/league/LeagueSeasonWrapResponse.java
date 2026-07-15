package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueSeasonWrapResponse(
        boolean temporadaCompleta,
        boolean archivada,
        boolean mostrarCinematica,
        int posicion,
        int totalParticipantes,
        int puntosEfectivos,
        String nombreLiga,
        Instant ultimoPartidoEn,
        LeagueSeasonWrapPlayerHighlight maxPuntos,
        LeagueSeasonWrapPlayerHighlight maxGoleador,
        LeagueSeasonWrapPlayerHighlight maxAsistente
) {
}
