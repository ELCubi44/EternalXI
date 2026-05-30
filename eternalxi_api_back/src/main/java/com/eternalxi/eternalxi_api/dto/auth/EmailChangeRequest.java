package com.eternalxi.eternalxi_api.dto.auth;

public record EmailChangeRequest(
        Long idUsuario,
        String contrasenaActual,
        String nuevoCorreo
) {}
