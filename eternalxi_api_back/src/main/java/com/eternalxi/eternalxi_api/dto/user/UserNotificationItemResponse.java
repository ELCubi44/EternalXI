package com.eternalxi.eternalxi_api.dto.user;

import java.time.Instant;
import java.util.Map;

public record UserNotificationItemResponse(
        Long id,
        Long idLiga,
        String tipo,
        String titulo,
        String mensaje,
        boolean leida,
        Map<String, Object> datos,
        Instant creadaEn
) {
}
