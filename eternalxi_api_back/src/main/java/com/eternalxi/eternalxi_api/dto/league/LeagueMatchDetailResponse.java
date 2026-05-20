package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record LeagueMatchDetailResponse(
        Long idPartido,
        Long idLiga,
        Long idJornada,
        Integer numeroJornada,
        LocalDate inicioJornada,
        Instant inicioPartido,

        String estado,
        String estadoReal,
        boolean enDirecto,
        Integer minutoActual,
        Integer segundoActual,

        Long idLigaEquipoLocal,
        Long idEquipoLocal,
        String nombreEquipoLocal,
        String fotoEquipoLocal,
        Integer golesLocal,

        Long idLigaEquipoVisitante,
        Long idEquipoVisitante,
        String nombreEquipoVisitante,
        String fotoEquipoVisitante,
        Integer golesVisitante,

        String formacionLocal,
        String alineacionLocal,
        LeagueMatchRealCoachResponse entrenadorLocal,
        String formacionVisitante,
        String alineacionVisitante,
        LeagueMatchRealCoachResponse entrenadorVisitante,

        Integer golesLocalFinales,
        Integer golesVisitanteFinales,

        Long idLigaEquipoGanador,
        Boolean empate,

        List<LeagueMatchLineupPlayerResponse> titularesLocal,
        List<LeagueMatchLineupPlayerResponse> suplentesLocal,
        List<LeagueMatchLineupPlayerResponse> titularesVisitante,
        List<LeagueMatchLineupPlayerResponse> suplentesVisitante,
        List<LeagueMatchEventResponse> eventos
) {
}