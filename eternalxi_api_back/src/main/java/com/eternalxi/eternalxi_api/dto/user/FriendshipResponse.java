package com.eternalxi.eternalxi_api.dto.user;

import java.time.Instant;

public record FriendshipResponse(
        Long id,
        Long idUsuario,
        String nickname,
        String foto,
        String estado,
        boolean soySolicitante,
        Instant creadoEn
) {
}
