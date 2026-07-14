package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueDmMessageResponse(
        Long id,
        Long idLiga,
        Long idEmisor,
        Long idDestino,
        String nicknameEmisor,
        String fotoEmisor,
        String texto,
        Instant creadoEn
) {
}
