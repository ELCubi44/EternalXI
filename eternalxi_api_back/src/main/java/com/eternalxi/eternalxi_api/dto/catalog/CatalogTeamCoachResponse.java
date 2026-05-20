package com.eternalxi.eternalxi_api.dto.catalog;

public record CatalogTeamCoachResponse(
        Long id,
        String nombre,
        String pila,
        String formacion,
        String foto,
        String fotoUrl,
        Integer idEquipo,
        Integer idTemporada,
        Integer bonusPuntos,
        Boolean activo
) {
}
