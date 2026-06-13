package com.eternalxi.eternalxi_api.dto.auth;

public record AgeConfirmationRequest(
        Long idUsuario,
        String fechaNacimiento
) {}
