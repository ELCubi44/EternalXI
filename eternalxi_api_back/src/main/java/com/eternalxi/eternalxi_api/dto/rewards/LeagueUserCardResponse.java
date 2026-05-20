package com.eternalxi.eternalxi_api.dto.rewards;

public record LeagueUserCardResponse(
        Long idCarta,
        Long idDefinicion,
        String codigo,
        String nombre,
        String rareza,
        String tipoEfecto,
        String descripcion,
        String parametrosJson,
        String estado,
        java.time.Instant obtenidoEn,
        java.time.Instant usadoEn
) {}
