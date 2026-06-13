package com.eternalxi.eternalxi_api.dto.user;

public record UserResponse(
        Long id,
        String correo,
        String nickname,
        int nivel,
        String foto,
        boolean requiereConfirmacionEdad
) {
}