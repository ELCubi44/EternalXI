package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueRoundMatchResponse(
        Long idPartido,
        Long idJornada,
        Long idLigaEquipoLocal,
        Long idEquipoLocal,
        String nombreEquipoLocal,
        Integer golesLocal,
        Long idLigaEquipoVisitante,
        Long idEquipoVisitante,
        String nombreEquipoVisitante,
        Integer golesVisitante,
        Long idLigaEquipoGanador,
        Boolean empate,
        String estado,
        Instant inicioEn
) {
}