package com.eternalxi.eternalxi_api.dto.rewards;

import java.time.Instant;

public record LeagueRewardEventResponse(
        Long id,
        String tipo,
        Long idCarta,
        Long idLigaJugador,
        Long idLigaParticipanteObjetivo,
        String packType,
        Long cantidad,
        String descripcion,
        Instant creadoEn
) {}
