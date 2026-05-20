package com.eternalxi.eternalxi_api.dto.rewards;

public enum CardEffectType {
    SELL_PLAYER_BONUS,
    DIRECT_CLAUSE,
    PROTECT_PLAYER,
    ADD_LEAGUE_POINTS,
    TEMPORARY_VALUE_RECOVERY;

    public static CardEffectType fromDb(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Tipo de efecto no válido");
        }
        return CardEffectType.valueOf(raw.trim());
    }
}
