package com.eternalxi.eternalxi_api.dto.league;

import java.util.Set;

/**
 * Configuración resuelta al crear una liga (defaults legacy si el cliente no envía campos).
 */
public record LeagueCreationConfig(
        int maxParticipantes,
        boolean semanaPreviaFichajes,
        boolean permiteEntresemana,
        boolean idaYVuelta,
        int recompensaBaseJornada,
        int recompensaBonusGanador,
        long dineroPorPuntoFantasy
) {

    public static final int DEFAULT_MAX_PARTICIPANTS = 10;
    public static final int DEFAULT_RECOMPENSA_BASE_JORNADA = 150;
    public static final int DEFAULT_RECOMPENSA_BONUS_GANADOR = 250;
    public static final long DEFAULT_DINERO_POR_PUNTO_FANTASY = 100_000L;

    private static final Set<Integer> ALLOWED_MAX_PARTICIPANTS = Set.of(10, 12, 14, 16, 18, 20);
    private static final Set<Long> ALLOWED_DINERO_POR_PUNTO = Set.of(100_000L, 200_000L, 300_000L);

    public static LeagueCreationConfig resolve(CreateLeagueRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("No se ha enviado el cuerpo de la petición");
        }

        int maxParticipantes = request.maxParticipantes() != null
                ? request.maxParticipantes()
                : DEFAULT_MAX_PARTICIPANTS;
        if (!ALLOWED_MAX_PARTICIPANTS.contains(maxParticipantes)) {
            throw new IllegalArgumentException(
                    "maxParticipantes debe ser uno de: 10, 12, 14, 16, 18, 20"
            );
        }

        boolean semanaPreviaFichajes = Boolean.TRUE.equals(request.semanaPreviaFichajes());
        boolean permiteEntresemana = Boolean.TRUE.equals(request.permiteEntresemana());
        boolean idaYVuelta = request.idaYVuelta() == null || request.idaYVuelta();

        int recompensaBase = request.recompensaBaseJornada() != null
                ? request.recompensaBaseJornada()
                : DEFAULT_RECOMPENSA_BASE_JORNADA;
        if (request.recompensaBaseJornada() != null) {
            if (recompensaBase < 300 || recompensaBase > 1000) {
                throw new IllegalArgumentException(
                        "recompensaBaseJornada debe estar entre 300 y 1000"
                );
            }
        }

        long dineroPorPunto = request.dineroPorPuntoFantasy() != null
                ? request.dineroPorPuntoFantasy()
                : DEFAULT_DINERO_POR_PUNTO_FANTASY;
        if (request.dineroPorPuntoFantasy() != null && !ALLOWED_DINERO_POR_PUNTO.contains(dineroPorPunto)) {
            throw new IllegalArgumentException(
                    "dineroPorPuntoFantasy debe ser 100000, 200000 o 300000"
            );
        }

        return new LeagueCreationConfig(
                maxParticipantes,
                semanaPreviaFichajes,
                permiteEntresemana,
                idaYVuelta,
                recompensaBase,
                DEFAULT_RECOMPENSA_BONUS_GANADOR,
                dineroPorPunto
        );
    }

    public LeagueConfigResponse toConfigResponse() {
        return new LeagueConfigResponse(
                maxParticipantes,
                semanaPreviaFichajes,
                permiteEntresemana,
                idaYVuelta,
                recompensaBaseJornada,
                recompensaBonusGanador,
                dineroPorPuntoFantasy
        );
    }
}
