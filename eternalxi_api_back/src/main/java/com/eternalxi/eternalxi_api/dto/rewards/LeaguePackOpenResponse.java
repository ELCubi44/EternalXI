package com.eternalxi.eternalxi_api.dto.rewards;

public record LeaguePackOpenResponse(
        String packType,
        int puntosGastados,
        long puntosRestantes,
        long dineroGanado,
        long nuevoDineroLiga,
        LeagueUserCardResponse cartaObtenida
) {}
