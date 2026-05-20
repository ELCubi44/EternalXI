package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeaguePlayerOfferResponse(
        Long idOferta,
        Long idLiga,
        Long idLigaJugador,
        Long idUsuarioComprador,
        Long cantidad,
        String estado,
        Instant creadaEn,
        Instant actualizadaEn,
        Instant respondidaEn,

        Long idJugador,
        String nombre,
        String pila,
        String nombreVisible,
        String posicion,
        String fotoJugador,

        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,

        String estadoJugador,
        Integer cansancio,
        Long valorActual,

        Long idUsuarioDuenoActual,
        String nicknameDuenoActual,
        String nicknameComprador,
        String fotoUsuarioComprador,
        Integer probabilidadTitular,
        String motivoTitularidad,
        Long idPartidoProbabilidad,
        Instant calculadoEnProbabilidad
) {
}