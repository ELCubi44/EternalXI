package com.eternalxi.eternalxi_api.dto.rewards;

public enum CardEffectType {
    SELL_PLAYER_BONUS,
    DIRECT_CLAUSE,
    PROTECT_PLAYER,
    ADD_LEAGUE_POINTS,
    /** Subida permanente del valor de mercado de un jugador propio. */
    PLAYER_VALUE_BOOST;

    public static CardEffectType fromDb(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Tipo de efecto no válido");
        }
        String normalized = raw.trim();
        if ("TEMPORARY_VALUE_RECOVERY".equals(normalized)) {
            return PLAYER_VALUE_BOOST;
        }
        return CardEffectType.valueOf(normalized);
    }
}
