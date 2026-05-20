package com.eternalxi.eternalxi_api.dto.league;

public record LeagueCoachAssignmentResponse(
        Long idLiga,
        Long idLigaParticipante,
        Long idUsuario,
        Long idEntrenador,
        String entrenadorNombre,
        String entrenadorPila,
        String formacion,
        String foto,
        Integer idEquipo,
        String equipoNombre,
        Integer bonusPuntos,
        Boolean activo
) {
}
