package com.eternalxi.eternalxi_api.dto.league;

public record LeagueMatchRealCoachResponse(
        Long idEntrenador,
        String entrenadorNombre,
        String entrenadorPila,
        String formacion,
        String foto,
        String fotoUrl,
        Long idEquipo,
        String equipoNombre,
        Integer bonusPuntos,
        Boolean activo
) {
}
