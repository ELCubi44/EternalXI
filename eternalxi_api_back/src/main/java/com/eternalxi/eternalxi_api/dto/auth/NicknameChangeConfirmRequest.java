package com.eternalxi.eternalxi_api.dto.auth;

public record NicknameChangeConfirmRequest(
        Long idUsuario,
        String nuevoNickname,
        String codigo
) {}
