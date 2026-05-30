package com.eternalxi.eternalxi_api.dto.user;

import com.eternalxi.eternalxi_api.progress.AchievementCode;

import java.time.Instant;

public record UserAchievementResponse(
        String codigo,
        String titulo,
        String descripcion,
        String informacion,
        String categoria,
        int xpRecompensa,
        boolean desbloqueado,
        Instant desbloqueadoEn,
        Integer progresoActual,
        Integer progresoObjetivo
) {
    public static UserAchievementResponse fromDefinition(
            AchievementCode def,
            boolean unlocked,
            Instant unlockedAt,
            Integer progresoActual,
            Integer progresoObjetivo
    ) {
        return new UserAchievementResponse(
                def.code(),
                def.title(),
                def.description(),
                def.helpDetail(),
                def.category().name(),
                def.xpReward(),
                unlocked,
                unlockedAt,
                progresoActual,
                progresoObjetivo
        );
    }
}
