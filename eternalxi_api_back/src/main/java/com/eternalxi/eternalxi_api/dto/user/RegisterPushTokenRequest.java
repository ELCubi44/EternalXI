package com.eternalxi.eternalxi_api.dto.user;

public record RegisterPushTokenRequest(
        Long idUsuario,
        String token,
        String plataforma,
        String deviceId
) {}