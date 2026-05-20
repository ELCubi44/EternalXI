package com.eternalxi.eternalxi_api.dto.catalog;

import java.util.List;

public record CatalogTeamSquadResponse(
        CatalogTeamResponse equipo,
        CatalogTeamCoachResponse entrenador,
        List<CatalogTeamPlayerResponse> jugadores
) {
}
