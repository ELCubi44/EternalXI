package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record LeagueRoundDetailResponse(
        Long idJornada,
        Long idLiga,
        Integer numero,
        LocalDate inicio,
        Instant inicioEn,
        LocalDate fin,
        String estado,
        Integer totalPartidos,
        Integer partidosFinalizados,
        List<LeagueRoundMatchResponse> partidos
) {
}