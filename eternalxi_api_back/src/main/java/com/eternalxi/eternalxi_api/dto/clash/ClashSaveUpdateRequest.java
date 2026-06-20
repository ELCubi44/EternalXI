package com.eternalxi.eternalxi_api.dto.clash;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

/**
 * Body para POST/PUT {@code /api/v1/clash/save}.
 * No incluye userId: el servidor lo resuelve desde la autenticación.
 */
public record ClashSaveUpdateRequest(
        Integer expectedServerRevision,
        int contractVersion,
        int schemaVersion,
        JsonNode saveData,
        Instant clientGeneratedAt
) {
}
