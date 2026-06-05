package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record MarkUserNotificationsReadRequest(
        Long idUsuario,
        List<Long> ids,
        Long idLiga,
        boolean marcarTodas
) {
}
