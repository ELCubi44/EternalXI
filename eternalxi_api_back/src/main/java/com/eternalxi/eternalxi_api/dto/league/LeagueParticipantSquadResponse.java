package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

/**
 * GET /leagues/{idLiga}/participants/{idLigaParticipante}/squad
 */
public record LeagueParticipantSquadResponse(
        long idLiga,
        long idLigaParticipante,
        long idUsuarioParticipante,
        String nickname,
        LeagueAssignedCoachResponse entrenadorAsignado,
        boolean entrenadorActivo,
        String formacionEfectiva,
        ParticipantSavedLineupPayload alineacion,
        List<LeagueSquadPlayerResponse> plantilla
) {
    public record ParticipantSavedLineupPayload(
            boolean disponible,
            long idJornadaOrigen,
            long numeroJornadaOrigen,
            String formacion,
            long idCapitan,
            List<LeagueSquadPlayerResponse> titulares,
            List<LeagueSquadPlayerResponse> reservas,
            List<LeagueEmptySlotResponse> emptySlots
    ) {}
}
