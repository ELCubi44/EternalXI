package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.time.LocalDate;

public record LeagueRoundSummaryResponse(
        Long idJornada,
        Long idLiga,
        Integer numero,
        LocalDate inicio,
        Instant inicioEn,
        LocalDate fin,
        String estado,
        Integer totalPartidos,
        Integer partidosFinalizados,
        Boolean actual,
        Boolean proxima,
        Boolean finalizada
) {
}