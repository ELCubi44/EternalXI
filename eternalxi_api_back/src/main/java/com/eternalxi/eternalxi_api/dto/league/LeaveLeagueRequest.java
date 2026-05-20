package com.eternalxi.eternalxi_api.dto.league;

public record LeaveLeagueRequest(
        Long idUsuario,
        Long nuevoAdministradorId
) {
}