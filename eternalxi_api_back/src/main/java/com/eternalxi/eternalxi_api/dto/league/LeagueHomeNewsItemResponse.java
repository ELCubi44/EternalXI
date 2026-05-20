package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueHomeNewsItemResponse(
        Long idEvento,
        Long idPartido,
        Long idJornada,
        Integer numeroJornada,
        Instant inicioPartido,
        Integer minuto,
        Integer segundo,
        String tipo,
        String texto,
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String nombreMostrado,
        String fotoJugador,
        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        Instant lesionadoHasta,
        boolean lesionActiva
) {}