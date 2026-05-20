package com.eternalxi.eternalxi_api.dto.league;

public record CreateLeagueRequest(
        String nombre,
        Long idTemporada,
        Long idUsuario,
        Integer maxParticipantes,
        Boolean semanaPreviaFichajes,
        /** Añade jornadas martes/miércoles entre fines de semana; la J1 siempre es fin de semana. */
        Boolean permiteEntresemana,
        Boolean idaYVuelta,
        Integer recompensaBaseJornada,
        Long dineroPorPuntoFantasy
) {
}
