package com.eternalxi.eternalxi_api.dto.user;

public record UserPublicLeagueSummaryResponse(
        long idLiga,
        String nombreLiga,
        long idLigaParticipante,
        String estadoLiga,
        int puntosFantasy,
        int posicionFinal,
        int totalParticipantes,
        UserPublicLeaguePlayerStat maxGoleador,
        UserPublicLeaguePlayerStat maxAsistente,
        UserPublicLeaguePlayerStat maxPorteriasCero
) {
}
