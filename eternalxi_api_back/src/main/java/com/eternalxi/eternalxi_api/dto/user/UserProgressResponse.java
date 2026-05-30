package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record UserProgressResponse(
        Long idUsuario,
        int nivel,
        long experienciaTotal,
        long xpEnNivel,
        long xpParaSiguienteNivel,
        String rango,
        List<UserAchievementResponse> logros,
        List<UserProgressEventResponse> eventosPendientes
) {}
