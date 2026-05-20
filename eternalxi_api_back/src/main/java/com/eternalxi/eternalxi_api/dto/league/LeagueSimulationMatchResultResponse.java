package com.eternalxi.eternalxi_api.dto.league;

public record LeagueSimulationMatchResultResponse(
        Long idLiga,
        Long idJornada,
        Long idPartido,
        String nombreEquipoLocal,
        Integer golesLocal,
        String nombreEquipoVisitante,
        Integer golesVisitante,
        String estadoFinal
) {
}