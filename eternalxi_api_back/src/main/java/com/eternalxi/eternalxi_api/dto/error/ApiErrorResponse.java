package com.eternalxi.eternalxi_api.dto.error;

import java.time.Instant;

public record ApiErrorResponse(
        String error,
        String message,
        int status,
        Instant timestamp,
        String path
) {
    public ApiErrorResponse(String error, String message, int status, String path) {
        this(error, message, status, Instant.now(), path);
    }
}
