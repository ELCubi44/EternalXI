package com.eternalxi.eternalxi_api.dto.rewards;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Objetivo genérico para canje de carta; solo aplican campos según {@code tipoEfecto}.
 * Todos los campos de preview vienen calculados por backend para que Flutter no haga cálculos.
 * Los campos nulos se omiten en JSON para no exponer datos internos innecesarios.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeagueCardTargetResponse(
        Long idLigaJugador,
        String nombreJugador,
        Long idEquipo,
        String nombreEquipo,
        String fotoEquipo,
        String fotoJugador,
        String posicion,
        Double valoracionActual,
        Long idUsuarioDueno,
        String nicknameDueno,
        Long valorActual,
        Long valorAnterior,
        Long valorMercadoEfectivo,
        Double porcentajeModificadorValorActivo,
        // SELL (Flutter puede ocultar multiplicador / valorMercado; aquí se envían nulos en SELL)
        Double multiplicadorVenta,
        Long cantidadRecibidaPreview,
        // CLAUSE
        Long costeClausulaAtacante,
        Long compensacionPropietario,
        // PROTECT
        Boolean protegido,
        String motivoBloqueo,
        Long idJornadaInicioProteccion,
        Long idJornadaFinProteccion,
        /** Número de jornada de liga (columna {@code jornadas.numero}), no el id interno. */
        Long numeroJornadaFinProteccion,
        Boolean proteccionHastaFinTemporada,
        Integer jornadasProteccion,
        Boolean proteccionTemporada,
        // VALUE RECOVERY
        Long valorTemporalEstimado,
        Double porcentajeRecuperacion,
        Long idJornadaExpiracionPreview,
        /** Número de jornada de liga para expiración prevista. */
        Long numeroJornadaExpiracionPreview,
        /** Importe diario previsto que aporta la carta (valor efectivo × porcentaje carta), en € enteros. */
        Long incrementoValorDiarioPreview,
        /** Bajada acumulada respecto al valor anterior (valor anterior − valor actual), en € enteros. */
        Long diferenciaValorPreview
) {
    public static LeagueCardTargetResponse sellTarget(
            long idLj,
            String nombre,
            Long idEquipo,
            String nombreEquipo,
            String fotoEquipo,
            String fotoJugador,
            String posicion,
            Double valoracion,
            long valorMercadoEfectivoParaVenta,
            long cantidadRecibidaPreview
    ) {
        return new LeagueCardTargetResponse(
                idLj,
                nombre,
                idEquipo,
                nombreEquipo,
                fotoEquipo,
                fotoJugador,
                posicion,
                valoracion,
                null,
                null,
                valorMercadoEfectivoParaVenta,
                null,
                null,
                null,
                null,
                cantidadRecibidaPreview,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null
        );
    }

    public static LeagueCardTargetResponse clauseTarget(
            long idLj,
            String nombre,
            Long idEquipo,
            String nombreEquipo,
            String fotoEquipo,
            String fotoJugador,
            String posicion,
            Double valoracion,
            long idDueno,
            String nick,
            long valorMercadoEfectivo,
            Long costeClausulaAtacante,
            Long compensacionPropietario,
            boolean protegido,
            String motivoBloqueo
    ) {
        return new LeagueCardTargetResponse(
                idLj,
                nombre,
                idEquipo,
                nombreEquipo,
                fotoEquipo,
                fotoJugador,
                posicion,
                valoracion,
                idDueno,
                nick,
                valorMercadoEfectivo,
                null,
                null,
                null,
                null,
                null,
                costeClausulaAtacante,
                compensacionPropietario,
                protegido,
                motivoBloqueo,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null
        );
    }

    public static LeagueCardTargetResponse protectTarget(
            long idLj,
            String nombre,
            Long idEquipo,
            String nombreEquipo,
            String fotoEquipo,
            String fotoJugador,
            String posicion,
            Double valoracion,
            long valorActual,
            boolean jugadorProtegido,
            String motivoProteccion,
            Long idJornadaInicioProteccion,
            Long idJornadaFinProteccion,
            Long numeroJornadaFinProteccion,
            Boolean proteccionHastaFinTemporada,
            Integer jornadasProteccionCarta,
            Boolean proteccionTemporadaCarta
    ) {
        return new LeagueCardTargetResponse(
                idLj,
                nombre,
                idEquipo,
                nombreEquipo,
                fotoEquipo,
                fotoJugador,
                posicion,
                valoracion,
                null,
                null,
                valorActual,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                jugadorProtegido,
                motivoProteccion,
                idJornadaInicioProteccion,
                idJornadaFinProteccion,
                numeroJornadaFinProteccion,
                proteccionHastaFinTemporada,
                jornadasProteccionCarta,
                proteccionTemporadaCarta,
                null,
                null,
                null,
                null,
                null,
                null
        );
    }

    public static LeagueCardTargetResponse valueRecovery(
            long idLj,
            String nombre,
            Long idEquipo,
            String nombreEquipo,
            String fotoEquipo,
            String fotoJugador,
            String posicion,
            Double valoracion,
            long valorActual,
            long valorAnterior,
            long valorTemporalEstimado,
            double porcentajeRecuperacion,
            Long idJornadaExpiracionPreview,
            Long numeroJornadaExpiracionPreview,
            long incrementoValorDiarioPreview,
            long diferenciaValorPreview
    ) {
        return new LeagueCardTargetResponse(
                idLj,
                nombre,
                idEquipo,
                nombreEquipo,
                fotoEquipo,
                fotoJugador,
                posicion,
                valoracion,
                null,
                null,
                valorActual,
                valorAnterior,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                valorTemporalEstimado,
                porcentajeRecuperacion,
                idJornadaExpiracionPreview,
                numeroJornadaExpiracionPreview,
                incrementoValorDiarioPreview,
                diferenciaValorPreview
        );
    }
}
