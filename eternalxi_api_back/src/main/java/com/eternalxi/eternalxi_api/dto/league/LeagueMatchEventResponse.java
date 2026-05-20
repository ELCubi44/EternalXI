package com.eternalxi.eternalxi_api.dto.league;

public record LeagueMatchEventResponse(
        Long id,
        Integer minuto,
        Integer segundo,
        String tipo,
        Integer replayOffsetSec,
        Long idLigaJugadorPrincipal,
        Integer idJugadorCedidoTemporadaPrincipal,
        String nombreJugadorPrincipal,
        String fotoUrlJugadorPrincipal,
        Long idLigaJugadorSecundario,
        Integer idJugadorCedidoTemporadaSecundario,
        String nombreJugadorSecundario,
        String fotoUrlJugadorSecundario,
        String texto
) {}