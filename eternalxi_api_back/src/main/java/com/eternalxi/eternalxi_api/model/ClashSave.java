package com.eternalxi.eternalxi_api.model;

import java.time.Instant;

/**
 * Partida Clash persistida online (tabla {@code clash_save}).
 */
public record ClashSave(
        long id,
        long userId,
        int contractVersion,
        int schemaVersion,
        int serverRevision,
        String saveDataJson,
        Instant createdAt,
        Instant updatedAt,
        Instant lastSyncAt
) {
}
