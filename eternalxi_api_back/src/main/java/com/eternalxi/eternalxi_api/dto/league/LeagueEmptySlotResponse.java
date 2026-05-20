package com.eternalxi.eternalxi_api.dto.league;

public record LeagueEmptySlotResponse(
        String posicion,
        Integer orden,
        Integer penalizacion,
        Boolean emptySlot
) {
}
