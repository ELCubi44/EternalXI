package com.eternalxi.eternalxi_api.dto.league;

/**
 * Desglose oficial de puntos fantasy por concepto (misma regla que {@code puntos}).
 */
public record FantasyPointsBreakdownResponse(
        Integer minutos,
        Integer goles,
        Integer asistencias,
        Integer regates,
        Integer recuperaciones,
        Integer paradas,
        Integer porteriaCero,
        /** Penalización por goles encajados (≤ 0). */
        Integer golesEncajados,
        Integer notaPeriodico,
        /** Penalización por amarillas (≤ 0). */
        Integer amarillas,
        /** Penalización por rojas (≤ 0). */
        Integer rojas,
        /** Penalización por lesión en partido (≤ 0). */
        Integer lesion,
        Integer total
) {
}
