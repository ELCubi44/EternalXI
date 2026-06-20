package com.eternalxi.eternalxi_api.model;

import java.time.Instant;

public record ClashClaim(
        long id,
        long userId,
        String claimId,
        String claimType,
        String sourceId,
        String stageId,
        String requestJson,
        String responseJson,
        String status,
        Integer serverRevision,
        Instant createdAt,
        Instant processedAt
) {
}
