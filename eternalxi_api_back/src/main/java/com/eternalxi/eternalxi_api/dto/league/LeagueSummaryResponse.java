package com.eternalxi.eternalxi_api.dto.league;

public record LeagueSummaryResponse(
        Long id,
        String nombre,
        Long idTemporada,
        String codigoInvitacion,
        boolean soyAdmin,
        int participantes
) {
}