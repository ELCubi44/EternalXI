package com.eternalxi.eternalxi_api.dto.league;

public record LeagueCoachAssignmentUpsertRequest(
        Long idUsuarioSolicitante,
        Long idEntrenador
) {
}
