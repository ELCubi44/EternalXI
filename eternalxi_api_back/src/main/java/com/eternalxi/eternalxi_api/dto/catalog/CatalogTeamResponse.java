package com.eternalxi.eternalxi_api.dto.catalog;

public record CatalogTeamResponse(
        Long id,
        String nombre,
        Long idTemporada,
        String foto,
        String fotoUrl
) {
}
