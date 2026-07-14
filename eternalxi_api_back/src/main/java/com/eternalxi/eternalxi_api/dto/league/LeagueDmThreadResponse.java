package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueDmThreadResponse(
        Long idPeer,
        String nicknamePeer,
        String fotoPeer,
        String ultimoTexto,
        Instant ultimoEn,
        Long ultimoId,
        boolean esAmigo
) {
}
