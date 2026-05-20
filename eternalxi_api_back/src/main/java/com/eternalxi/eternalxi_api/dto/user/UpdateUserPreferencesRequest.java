package com.eternalxi.eternalxi_api.dto.user;

public record UpdateUserPreferencesRequest(
        String themeMode,
        String languageCode
) {
}