package com.eternalxi.eternalxi_api.dto.auth;

public record LoginRequest(
        String correo,
        String contrasena
) {}