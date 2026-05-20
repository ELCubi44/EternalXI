package com.eternalxi.eternalxi_api.dto.rewards;

public enum RewardPackType {
    BASIC_PACK,
    COMMON_PACK,
    PREMIUM_PACK;

    public static RewardPackType fromPath(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Tipo de sobre no válido");
        }
        try {
            return RewardPackType.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Tipo de sobre no válido");
        }
    }
}
