package com.eternalxi.eternalxi_api.dto.auth;

public record RegisterRequest(
        String correo,
        String contrasena,
        String nickname,
        String fechaNacimiento,
        Boolean aceptaTerminos
) {}