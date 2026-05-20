package com.eternalxi.eternalxi_api.dto.league;

public record LeagueAssignedCoachResponse(
        Long idEntrenador,
        String entrenadorNombre,
        String entrenadorPila,
        String formacion,
        String foto,
        Integer idEquipo,
        String equipoNombre,
        Integer bonusPuntos,
        Boolean activo,
        /** Puntos fantasy aportados por el míster en una jornada concreta (historial); 0 si no aplica o jornada pendiente. */
        int puntosEntrenadorJornada
) {
}
