package com.eternalxi.eternalxi_api.dto.rewards;

import java.util.List;

/**
 * Agrupación de objetivos de cláusula por participante rival.
 */
public record LeagueCardParticipantTargetsResponse(
        Long idLigaParticipante,
        Long idUsuario,
        String nickname,
        int jugadoresDisponibles,
        int jugadoresBloqueados,
        List<LeagueCardTargetResponse> objetivos,
        List<LeagueCardTargetResponse> objetivosBloqueados
) {}
