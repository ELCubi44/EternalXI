package com.eternalxi.eternalxi_api.dto.league;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.List;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record LeagueParticipantLineupRoundDetailResponse(
        Long idLiga,
        Long idLigaParticipante,
        Long idUsuarioParticipante,
        String nickname,
        Long idJornada,
        Integer numeroJornada,
        String estadoJornada,
        Instant inicioJornada,
        /** Formación efectiva de la jornada (snapshot en {@code alineacion_jornada_participante_config} o inferida). */
        String formacionEfectiva,
        /** Entrenador congelado para esa jornada; null si no había míster en el snapshot. */
        LeagueAssignedCoachResponse entrenadorAsignado,
        Integer puntosTotales,
        /** Suma fantasy del 11 efectivo (titulares + suplencias por reglas + capitán); sin huecos ni míster. */
        Integer puntosJugadoresFormacion,
        /** Penalización por huecos vacíos en la alineación guardada. */
        Integer penalizacionHuecosFantasy,
        /** Puntos del entrenador activo en snapshot (misma cifra que {@code entrenadorAsignado.puntosEntrenadorJornada} si hay míster). */
        Integer puntosEntrenadorFantasy,
        Long idCapitan,
        List<LeagueParticipantLineupRoundPlayerResponse> titulares,
        List<LeagueParticipantLineupRoundPlayerResponse> reservas,
        List<LeagueEmptySlotResponse> emptySlots
) {
}
