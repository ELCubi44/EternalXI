package com.eternalxi.eternalxi_api.dto.clash;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

public record ClashSaveResponse(
        int serverRevision,
        int contractVersion,
        int schemaVersion,
        JsonNode saveData,
        Instant updatedAt
) {
}
