package com.eternalxi.eternalxi_api.dto.clash;

import com.fasterxml.jackson.databind.JsonNode;

public record ClashSaveConflictResponse(
        int serverRevision,
        JsonNode serverSaveData,
        String clientRejectedReason
) {
}
