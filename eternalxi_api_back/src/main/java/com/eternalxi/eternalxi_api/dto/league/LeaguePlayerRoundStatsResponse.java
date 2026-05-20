package com.eternalxi.eternalxi_api.dto.league;

public record LeaguePlayerRoundStatsResponse(
        Long idJornada,
        Integer numeroJornada,
        String estadoJornada,
        Integer minutosJugados,
        Integer goles,
        Integer asistencias,
        Integer regates,
        Integer balonesRecuperados,
        Integer tarjetasAmarillas,
        Integer tarjetasRojas,
        Boolean lesionadoEnPartido,
        Integer puntos,
        FantasyPointsBreakdownResponse puntosDesglose,
        Integer notaPeriodico,
        Integer golesEncajados,
        /** Paradas (portero); 0 si stats no visibles (anti-spoiler). */
        Integer paradas
) {}