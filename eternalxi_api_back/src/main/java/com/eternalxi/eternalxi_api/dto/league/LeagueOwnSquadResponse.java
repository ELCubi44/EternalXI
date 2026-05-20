package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record LeagueOwnSquadResponse(
        Long idLiga,
        Long idLigaParticipante,
        Long idUsuario,
        LeagueAssignedCoachResponse entrenadorAsignado,
        boolean entrenadorActivo,
        String formacionEfectiva,
        List<LeagueSquadPlayerResponse> plantilla
) {
}
