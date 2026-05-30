package com.eternalxi.eternalxi_api.dto.auth;

public record EmailChangeConfirmRequest(
        Long idUsuario,
        String nuevoCorreo,
        String codigo
) {}
