package com.eternalxi.eternalxi_api.dto.league;

public record LeagueMatchLineupPlayerResponse(
        Long idLigaJugador,
        Integer idJugadorCedidoTemporada,
        String tipoOrigenJugador,
        Long idJugador,
        String nombre,
        String pila,
        String nombreVisible,
        String posicion,
        Integer valoracion,
        Long idEquipo,
        String nombreEquipo,
        String foto,
        String fotoUrl,
        String estado,
        Integer cansancio,
        Long valor,
        Boolean titular
) {
}