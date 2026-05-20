package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueMarketPlayerResponse(
        Long idLigaJugador,
        Long idLiga,
        Long idJugador,
        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        String nombre,
        String pila,
        Integer dorsal,
        String descripcion,
        int valoracion,
        String genero,
        String posicion,
        String fotoJugador,
        String estado,
        int cansancio,
        long valor,
        long valorAnterior,
        Instant adquiridoEn,
        Long idUsuarioDueno,
        String nombreDuenoVisible,
        boolean esMercado,
        boolean tieneOfertaPendiente,
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad
) {
}
