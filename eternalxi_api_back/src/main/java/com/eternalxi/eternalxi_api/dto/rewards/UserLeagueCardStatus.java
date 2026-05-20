package com.eternalxi.eternalxi_api.dto.rewards;

public enum UserLeagueCardStatus {
    AVAILABLE,
    USED,
    EXPIRED;

    public static UserLeagueCardStatus fromDb(String raw) {
        if (raw == null || raw.isBlank()) {
            return AVAILABLE;
        }
        return UserLeagueCardStatus.valueOf(raw.trim());
    }
}
