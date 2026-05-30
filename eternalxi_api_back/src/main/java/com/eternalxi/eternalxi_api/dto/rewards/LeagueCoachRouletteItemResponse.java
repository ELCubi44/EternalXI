package com.eternalxi.eternalxi_api.dto.rewards;

public record LeagueCoachRouletteItemResponse(
        Long idEntrenador,
        String nombre,
        String pila,
        String foto,
        Integer idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        Integer bonusPuntos
) {}
