package com.eternalxi.eternalxi_api.dto.league;

/**
 * Configuración persistida de la liga (creación / detalle).
 */
public record LeagueConfigResponse(
        int maxParticipantes,
        boolean semanaPreviaFichajes,
        boolean permiteEntresemana,
        boolean idaYVuelta,
        int recompensaBaseJornada,
        int recompensaBonusGanador,
        long dineroPorPuntoFantasy
) {
}
