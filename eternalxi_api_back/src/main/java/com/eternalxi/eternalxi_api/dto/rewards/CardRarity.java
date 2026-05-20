package com.eternalxi.eternalxi_api.dto.rewards;

public enum CardRarity {
    BASIC,
    NORMAL,
    SPECIAL,
    SUPER_RARE,
    LEGENDARY;

    public static CardRarity fromDb(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Rareza no válida");
        }
        return CardRarity.valueOf(raw.trim());
    }
}
