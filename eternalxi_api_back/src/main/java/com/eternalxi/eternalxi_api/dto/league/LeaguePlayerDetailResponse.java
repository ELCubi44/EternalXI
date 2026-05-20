package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.util.List;

public record LeaguePlayerDetailResponse(
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String posicion,
        Integer valoracion,
        Long idEquipo,
        String nombreEquipo,
        String estado,
        Integer cansancio,
        Long valor,
        Long valorAnterior,
        Long idUsuarioDueno,
        Boolean esMercado,
        Boolean enPoolMercado,
        Boolean enMercadoHoy,
        Boolean tieneOfertaPendiente,
        String fotoJugador,
        Integer puntosFantasyTotales,
        List<LeaguePlayerRoundStatsResponse> estadisticasJornadas,
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad,
        Long valorMercadoEfectivo,
        boolean tieneModificadorValorMercado,
        Double porcentajeModificadorValorMercado,
        Boolean jugadorProtegido,
        Boolean proteccionHastaFinTemporada,
        Long proteccionJornadaFin
) {
}