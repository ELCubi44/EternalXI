package com.eternalxi.eternalxi_api.dto.auth;

public record NicknameChangeRequest(
        Long idUsuario,
        String contrasenaActual,
        String nuevoNickname
) {}
