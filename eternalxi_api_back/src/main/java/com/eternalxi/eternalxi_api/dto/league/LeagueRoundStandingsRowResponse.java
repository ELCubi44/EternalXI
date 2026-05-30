package com.eternalxi.eternalxi_api.dto.league;

public record LeagueRoundStandingsRowResponse(
        int posicion,
        Long idLigaParticipante,
        Long idUsuario,
        String nickname,
        int puntosFantasyJornada,
        int puntosRecompensaJornada,
        long valorTotalEquipo,
        boolean admin
) {}
