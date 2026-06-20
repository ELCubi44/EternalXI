package com.eternalxi.eternalxi_api.dto.clash;

import com.fasterxml.jackson.databind.JsonNode;

public record ClashClaimResponse(
        String claimId,
        String status,
        boolean alreadyProcessed,
        Integer serverRevision,
        JsonNode rewards,
        String message
) {
}
