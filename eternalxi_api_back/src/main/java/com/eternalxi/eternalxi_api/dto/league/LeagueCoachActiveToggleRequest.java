package com.eternalxi.eternalxi_api.dto.league;

public record LeagueCoachActiveToggleRequest(
        Long idUsuarioSolicitante,
        Boolean activo,
        /** Obligatorio cuando activo=true y no hay ya un único entrenador equipado; indica cuál equipar. */
        Long idEntrenador
) {
}
