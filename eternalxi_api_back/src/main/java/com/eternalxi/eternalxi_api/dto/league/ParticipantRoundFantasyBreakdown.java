package com.eternalxi.eternalxi_api.dto.league;

import java.util.Set;

/**
 * Desglose de puntos fantasy de una jornada para un participante (útil en historial / depuración).
 * Los conjuntos marcan titulares que no sumaron porque entró el banquillo y el suplente que sí sumó por esa vía.
 */
public record ParticipantRoundFantasyBreakdown(
        int puntosTotales,
        int puntosJugadoresFormacion,
        int penalizacionHuecos,
        int puntosEntrenador,
        Set<Long> fantasyTitularesDescartados,
        Set<Long> fantasyBanquilloPorSuplencia
) {
}
