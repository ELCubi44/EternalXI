package com.eternalxi.eternalxi_api.dto.league;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record CreateLeagueResponse(
        Long idLiga,
        int maxParticipantes,
        boolean semanaPreviaFichajes,
        boolean permiteEntresemana,
        boolean idaYVuelta,
        int recompensaBaseJornada,
        int recompensaBonusGanador,
        long dineroPorPuntoFantasy,
        int numeroJornadas,
        LocalDateTime primerPartidoEn,
        LocalDate finLigaEn
) {
}
