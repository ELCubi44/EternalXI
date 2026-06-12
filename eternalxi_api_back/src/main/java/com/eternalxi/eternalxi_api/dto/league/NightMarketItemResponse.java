package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;
import java.time.LocalDate;

public record NightMarketItemResponse(
        Long idMercadoDiario,
        Long idLiga,
        LocalDate fecha,
        boolean resuelto,
        Instant resueltoEn,
        Long idUsuarioGanador,
        Long pujaGanadora,

        Long idLigaJugador,
        Long idJugador,
        String nombre,
        String pila,
        String nombreVisible,
        String posicion,
        String fotoJugador,

        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,

        String estado,
        Integer cansancio,
        Long valorActual,
        Integer valoracion,
        Long precioSalida,

        Long miPuja,
        Long pujaMasAlta,
        Integer totalPujas,
        Integer probabilidadTitular
) {
}