package com.eternalxi.eternalxi_api.dto.league;

import java.time.Instant;

public record LeagueChatMessageResponse(
        long id,
        long idUsuario,
        String nickname,
        String foto,
        String texto,
        Instant creadoEn
) {}
