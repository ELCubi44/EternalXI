package com.eternalxi.eternalxi_api.dto.clash;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Body para {@code POST /api/v1/clash/claims}.
 * No incluye userId: el servidor lo resuelve desde la autenticación.
 */
public record ClashClaimRequest(
        String claimId,
        String claimType,
        String sourceId,
        String stageId,
        Integer expectedServerRevision,
        JsonNode payload
) {
}
