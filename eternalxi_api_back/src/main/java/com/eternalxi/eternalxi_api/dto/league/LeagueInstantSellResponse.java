package com.eternalxi.eternalxi_api.dto.league;

public record LeagueInstantSellResponse(
        Long idLiga,
        Long idLigaJugador,
        Long idUsuario,
        Long valorActual,
        Long cantidadVenta,
        Long nuevoSaldo
) {
}