package com.eternalxi.eternalxi_api.dto.league;

public record InviteFriendToLeagueRequest(
        Long idUsuario,
        Long idAmigo
) {
}
