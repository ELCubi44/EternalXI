package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record MarkProgressEventsSeenRequest(
        List<Long> idsEventos
) {}
