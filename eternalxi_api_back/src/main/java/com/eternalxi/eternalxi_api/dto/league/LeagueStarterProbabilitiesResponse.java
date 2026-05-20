package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record LeagueStarterProbabilitiesResponse(
        Long idLiga,
        Long idJornada,
        Integer numeroJornada,
        List<LeagueStarterProbabilityRowResponse> probabilidades
) {
}
