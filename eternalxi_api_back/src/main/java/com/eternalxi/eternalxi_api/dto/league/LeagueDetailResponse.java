package com.eternalxi.eternalxi_api.dto.league;

public record LeagueDetailResponse(
        Long id,
        String nombre,
        Long idTemporada,
        String codigoInvitacion,
        Long idAdministrador,
        boolean soyAdmin,
        int participantes,
        long miDinero,
        int misPuntosFantasy,
        int misPuntosBonus,
        /** Total efectivo fantasy + bonus (misma semántica que clasificación). */
        int misPuntos,
        long miValorEquipo,
        int maxParticipantes,
        boolean semanaPreviaFichajes,
        boolean permiteEntresemana,
        boolean idaYVuelta,
        int recompensaBaseJornada,
        int recompensaBonusGanador,
        long dineroPorPuntoFantasy
) {}
