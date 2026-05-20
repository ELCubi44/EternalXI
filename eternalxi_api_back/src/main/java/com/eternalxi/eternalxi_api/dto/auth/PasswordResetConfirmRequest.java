package com.eternalxi.eternalxi_api.dto.auth;

public record PasswordResetConfirmRequest(
        String correo,
        String codigo,
        String nuevaContrasena
) {}