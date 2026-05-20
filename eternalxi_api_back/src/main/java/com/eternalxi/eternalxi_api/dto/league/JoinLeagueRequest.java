package com.eternalxi.eternalxi_api.dto.league;

public record JoinLeagueRequest(
        String codigoInvitacion,
        Long idUsuario
) {
}