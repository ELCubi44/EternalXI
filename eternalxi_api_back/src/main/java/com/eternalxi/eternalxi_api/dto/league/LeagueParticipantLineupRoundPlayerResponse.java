package com.eternalxi.eternalxi_api.dto.league;

public record LeagueParticipantLineupRoundPlayerResponse(
        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String nombreMostrado,
        String posicion,
        Integer valoracion,
        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        String fotoJugador,
        String estado,
        Integer cansancio,
        Long valor,
        boolean titular,
        boolean capitan,
        Integer orden,
        Integer puntosJornada,
        FantasyPointsBreakdownResponse puntosDesglose,
        Integer minutosJugados,
        Integer golesEncajados,
        /** Paradas registradas en la jornada (típ. portero). */
        Integer paradas,
        /** Titular con 0 min cuyo hueco fantasy lo cubrió el banquillo (partido del club finalizado). */
        boolean fantasyTitularSinConteoPorBanquillo,
        /** Suplente cuyos puntos fantasy cuentan por sustituir a un titular sin minutos. */
        boolean fantasyBanquilloContandoPorSuplencia
) {
}
