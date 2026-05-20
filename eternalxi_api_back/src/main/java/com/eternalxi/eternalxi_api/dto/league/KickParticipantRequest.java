package com.eternalxi.eternalxi_api.dto.league;

public record KickParticipantRequest(
        Long idAdminUsuario,
        Long idUsuarioExpulsado
) {}