package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

/**
 * Probabilidad de titularidad persistida para un jugador de liga en una jornada concreta.
 */
public record StarterProbabilityLite(
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad
) {
}
