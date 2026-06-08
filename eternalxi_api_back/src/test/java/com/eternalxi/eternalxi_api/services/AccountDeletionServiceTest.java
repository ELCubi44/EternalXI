package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AccountDeletionServiceTest {

    @Test
    void emailSnapshotRedactedAfterSuccessfulDeletion() {
        assertEquals("", AccountDeletionService.REDACTED_EMAIL_SNAPSHOT);
    }
}
