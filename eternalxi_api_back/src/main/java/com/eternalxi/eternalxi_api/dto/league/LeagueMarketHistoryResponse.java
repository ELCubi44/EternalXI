package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueMarketHistoryResponse(
        Long id,
        Long idLiga,
        Long idLigaJugador,
        Long idJugador,
        Long idUsuarioComprador,
        String compradorNombre,
        Long idUsuarioVendedor,
        String vendedorNombre,
        String tipo,
        Long precio,
        String jugadorNombre,
        String descripcion,
        Instant creadoEn
) {}
