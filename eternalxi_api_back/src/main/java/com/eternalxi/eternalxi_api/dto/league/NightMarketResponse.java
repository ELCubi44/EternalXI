package com.eternalxi.eternalxi_api.dto.league;

import java.time.LocalDate;
import java.util.List;

public record NightMarketResponse(
        Long idLiga,
        Long idUsuario,
        LocalDate fechaMercado,
        Long saldoDisponible,
        Long saldoRetenido,
        Integer totalItems,
        List<NightMarketItemResponse> items
) {
}