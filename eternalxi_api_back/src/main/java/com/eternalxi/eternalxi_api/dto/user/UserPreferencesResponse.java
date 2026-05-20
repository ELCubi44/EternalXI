package com.eternalxi.eternalxi_api.dto.user;

public record UserPreferencesResponse(
        Long idUsuario,
        String themeMode,
        String languageCode
) {
}