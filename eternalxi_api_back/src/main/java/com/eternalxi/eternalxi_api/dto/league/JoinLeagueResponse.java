package com.eternalxi.eternalxi_api.dto.league;

public record JoinLeagueResponse(
        boolean joined,
        Long idLiga,
        Long idLigaParticipante,
        int jugadoresAsignados,
        boolean plantillaIncompleta,
        long valorPlantillaInicial,
        long objetivoValorMin,
        long objetivoValorMax,
        String mensaje
) {
}
