package com.eternalxi.eternalxi_api.exception;

import com.eternalxi.eternalxi_api.dto.clash.ClashSaveConflictResponse;

/**
 * Conflicto de revisión en PUT /api/v1/clash/save (HTTP 409 con payload específico).
 */
public class ClashSaveRevisionConflictException extends RuntimeException {

    private final ClashSaveConflictResponse conflictResponse;

    public ClashSaveRevisionConflictException(ClashSaveConflictResponse conflictResponse) {
        super(conflictResponse.clientRejectedReason());
        this.conflictResponse = conflictResponse;
    }

    public ClashSaveConflictResponse getConflictResponse() {
        return conflictResponse;
    }
}
