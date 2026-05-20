package com.eternalxi.eternalxi_api.dto.catalog;

public record CatalogTeamPlayerResponse(
        Long id,
        Long idLigaJugador,
        Long idEquipo,
        String nombre,
        String pila,
        Integer dorsal,
        String descripcion,
        Integer valoracion,
        String genero,
        String posicion,
        String foto,
        String fotoUrl,
        Long valor,
        String estado,
        Long idUsuarioDueno
) {
}
