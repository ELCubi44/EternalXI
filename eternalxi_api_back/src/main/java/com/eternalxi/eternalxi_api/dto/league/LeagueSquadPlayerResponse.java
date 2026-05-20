package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueSquadPlayerResponse(
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String posicion,
        int valoracion,
        Long idEquipo,
        String nombreEquipo,
        String estado,
        int cansancio,
        /** Valor de mercado en BD (sin modificador temporal). */
        long valor,
        String fotoJugador,
        int puntosTotales,
        boolean tieneOfertaPendiente,
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad,
        long valorMercadoEfectivo,
        boolean tieneModificadorValorMercado,
        Double porcentajeModificadorValorMercado,
        boolean jugadorProtegido,
        boolean proteccionHastaFinTemporada,
        Long proteccionJornadaFin
) {
}