package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record LeagueParticipantLineupHistoryResponse(
        Long idLiga,
        Long idLigaParticipante,
        Long idUsuarioParticipante,
        String nickname,
        List<LeagueParticipantLineupHistoryRoundResponse> jornadas
) {
}
