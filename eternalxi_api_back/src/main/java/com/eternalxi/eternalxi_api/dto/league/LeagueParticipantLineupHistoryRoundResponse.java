package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueParticipantLineupHistoryRoundResponse(
        Long idJornada,
        Integer numeroJornada,
        String estadoJornada,
        Instant inicioJornada,
        boolean alineacionDisponible,
        Integer puntosTotales
) {
}
