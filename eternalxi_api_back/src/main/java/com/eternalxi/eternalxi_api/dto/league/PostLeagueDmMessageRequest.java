package com.eternalxi.eternalxi_api.dto.league;

public record PostLeagueDmMessageRequest(
        Long idUsuario,
        Long idDestino,
        String texto
) {
}
