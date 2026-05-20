package com.eternalxi.eternalxi_api.dto.rewards;

import java.util.List;

public record LeagueCardValidTargetsResponse(
        String tipoEfecto,
        List<LeagueCardTargetResponse> objetivos,
        List<LeagueCardTargetResponse> objetivosBloqueados,
        List<LeagueCardParticipantTargetsResponse> participantesObjetivo,
        Integer puntosAnadidosPreview
) {
    public LeagueCardValidTargetsResponse(String tipoEfecto, List<LeagueCardTargetResponse> objetivos) {
        this(tipoEfecto, objetivos, List.of(), null, null);
    }

    public LeagueCardValidTargetsResponse(String tipoEfecto, List<LeagueCardTargetResponse> objetivos, List<LeagueCardTargetResponse> objetivosBloqueados) {
        this(tipoEfecto, objetivos, objetivosBloqueados, null, null);
    }
}
