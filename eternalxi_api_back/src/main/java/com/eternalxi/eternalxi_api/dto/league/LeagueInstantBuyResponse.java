package com.eternalxi.eternalxi_api.dto.league;

public record LeagueInstantBuyResponse(
        Long idLiga,
        Long idLigaJugador,
        Long idUsuario,
        Long valorActual,
        Long cantidadCompra,
        Long nuevoSaldo
) {
}