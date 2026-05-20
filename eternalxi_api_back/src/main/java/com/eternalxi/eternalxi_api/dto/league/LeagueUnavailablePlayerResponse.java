package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueUnavailablePlayerResponse(
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String fotoJugador,
        String posicion,
        Long idEquipo,
        String nombreEquipo,
        String estado,
        Instant lesionadoHasta,
        Instant sancionadoHasta,
        Instant disponibleDesde,
        Long idJornadaDisponible,
        Integer numeroJornadaDisponible,
        String textoDisponibilidad
) {}
