package com.eternalxi.eternalxi_api.dto.auth;

public record CodeVerificationRequest(
        String correo,
        String codigo
) {}