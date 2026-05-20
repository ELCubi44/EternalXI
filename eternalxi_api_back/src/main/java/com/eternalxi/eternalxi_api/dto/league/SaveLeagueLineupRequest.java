package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record SaveLeagueLineupRequest(
        Long idUsuario,
        Long idJornada,
        List<Long> titulares,
        List<Long> reservas,
        Long idCapitan
) {
}
