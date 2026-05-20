package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record LeagueSimulationRunResponse(
        Integer partidosDetectados,
        Integer partidosSimulados,
        List<LeagueSimulationMatchResultResponse> resultados
) {
}