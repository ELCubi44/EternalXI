package com.eternalxi.eternalxi_api.dto.user;

public record UserPublicStatsResponse(
        int ligasGanadas,
        int goles,
        int asistencias,
        int porteriasCero,
        int lesiones,
        int sanciones
) {
}
