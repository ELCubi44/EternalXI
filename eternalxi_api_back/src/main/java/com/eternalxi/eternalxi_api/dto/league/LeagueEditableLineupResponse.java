package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.util.List;

public record LeagueEditableLineupResponse(
        Long idLiga,
        Long idLigaParticipante,
        Long idJornada,
        Integer numeroJornada,
        Instant editableHasta,
        boolean bloqueada,
        boolean desdeAlineacionGuardada,
        LeagueAssignedCoachResponse entrenadorAsignado,
        boolean entrenadorActivo,
        String formacionEfectiva,
        List<Long> titulares,
        List<Long> reservas,
        Long idCapitan,
        List<LeagueEmptySlotResponse> emptySlots
) {
}
