package com.eternalxi.eternalxi_api.dto.league;

public record LeagueStandingsRowResponse(
        int posicion,
        Long idLigaParticipante,
        Long idUsuario,
        String nickname,
        /** Puntos fantasy recalculados (sin bonus de cartas). */
        int puntosFantasy,
        /** Suma de {@code liga_participante_puntos_bonus}. */
        int puntosBonus,
        /** Total efectivo fantasy + bonus (ordenación de clasificación). */
        int puntosTotales,
        long dinero,
        long valorTotalEquipo,
        boolean admin
) {}