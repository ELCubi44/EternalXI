package com.eternalxi.eternalxi_api.dto.league;

public record LeagueParticipantResponse(
        Long idLigaParticipante,
        Long idUsuario,
        String nickname,
        boolean admin,
        int puntosFantasy,
        int puntosBonus,
        int puntosTotales,
        long dinero,
        long valorTotalEquipo
) {}