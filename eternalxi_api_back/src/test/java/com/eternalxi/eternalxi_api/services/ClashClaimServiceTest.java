package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.clash.ClashClaimRequest;
import com.eternalxi.eternalxi_api.dto.clash.ClashClaimResponse;
import com.eternalxi.eternalxi_api.model.ClashClaim;
import com.eternalxi.eternalxi_api.model.ClashClaimStatus;
import com.eternalxi.eternalxi_api.repository.ClashClaimRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.sql.SQLException;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ClashClaimServiceTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final long USER_ID = 42L;
    private static final long OTHER_USER_ID = 99L;
    private static final Instant NOW = Instant.parse("2026-06-20T12:00:00Z");
    private static final String CLAIM_ID = "gift:gift-welcome";

    @Mock
    private ClashClaimRepository repository;

    private ClashClaimService service;

    @BeforeEach
    void setUp() {
        service = new ClashClaimService(repository);
    }

    @Test
    void newClaimReturnsAcceptedAndNotAlreadyProcessed() throws SQLException {
        when(repository.findByUserIdAndClaimId(USER_ID, CLAIM_ID)).thenReturn(Optional.empty());
        when(repository.insert(
                eq(USER_ID),
                eq(CLAIM_ID),
                eq("gift"),
                eq("gift-welcome"),
                isNull(),
                anyString(),
                anyString(),
                eq(ClashClaimStatus.ACCEPTED),
                isNull()
        )).thenReturn(sampleClaim(false));

        ClashClaimResponse response = service.processClaimForUser(USER_ID, validRequest(null));

        assertEquals(CLAIM_ID, response.claimId());
        assertEquals(ClashClaimStatus.ACCEPTED, response.status());
        assertFalse(response.alreadyProcessed());
        verify(repository, times(1)).insert(
                eq(USER_ID),
                eq(CLAIM_ID),
                eq("gift"),
                eq("gift-welcome"),
                isNull(),
                anyString(),
                anyString(),
                eq(ClashClaimStatus.ACCEPTED),
                isNull()
        );
    }

    @Test
    void repeatSameClaimReturnsAlreadyProcessedWithStablePayload() throws SQLException {
        ClashClaim stored = sampleClaim(false);
        when(repository.findByUserIdAndClaimId(USER_ID, CLAIM_ID))
                .thenReturn(Optional.of(stored));

        ClashClaimResponse firstRead = service.processClaimForUser(USER_ID, validRequest(null));
        ClashClaimResponse secondRead = service.processClaimForUser(USER_ID, validRequest(null));

        assertTrue(firstRead.alreadyProcessed());
        assertTrue(secondRead.alreadyProcessed());
        assertEquals(firstRead.claimId(), secondRead.claimId());
        assertEquals(firstRead.status(), secondRead.status());
        assertEquals(firstRead.message(), secondRead.message());
        verify(repository, never()).insert(
                anyLong(), anyString(), anyString(), anyString(), any(), anyString(), anyString(), anyString(), any()
        );
    }

    @Test
    void sameClaimIdForDifferentUsersDoesNotCollide() throws SQLException {
        when(repository.findByUserIdAndClaimId(OTHER_USER_ID, CLAIM_ID)).thenReturn(Optional.empty());
        when(repository.insert(
                eq(OTHER_USER_ID),
                eq(CLAIM_ID),
                eq("gift"),
                eq("gift-welcome"),
                isNull(),
                anyString(),
                anyString(),
                eq(ClashClaimStatus.ACCEPTED),
                isNull()
        )).thenReturn(sampleClaimForUser(OTHER_USER_ID, false));

        ClashClaimResponse response = service.processClaimForUser(OTHER_USER_ID, validRequest(null));

        assertFalse(response.alreadyProcessed());
        verify(repository).insert(
                eq(OTHER_USER_ID),
                eq(CLAIM_ID),
                eq("gift"),
                eq("gift-welcome"),
                isNull(),
                anyString(),
                anyString(),
                eq(ClashClaimStatus.ACCEPTED),
                isNull()
        );
    }

    @Test
    void invalidRequestMissingClaimIdThrows400() {
        ClashClaimRequest request = new ClashClaimRequest(
                " ",
                "gift",
                "gift-welcome",
                null,
                null,
                null
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> service.processClaimForUser(USER_ID, request)
        );
    }

    @Test
    void invalidRequestMissingClaimTypeThrows400() {
        ClashClaimRequest request = new ClashClaimRequest(
                CLAIM_ID,
                " ",
                "gift-welcome",
                null,
                null,
                null
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> service.processClaimForUser(USER_ID, request)
        );
    }

    @Test
    void invalidRequestMissingSourceIdThrows400() {
        ClashClaimRequest request = new ClashClaimRequest(
                CLAIM_ID,
                "gift",
                " ",
                null,
                null,
                null
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> service.processClaimForUser(USER_ID, request)
        );
    }

    @Test
    void requestDoesNotIncludeUserIdField() throws SQLException {
        when(repository.findByUserIdAndClaimId(USER_ID, CLAIM_ID)).thenReturn(Optional.empty());
        when(repository.insert(
                anyLong(),
                anyString(),
                anyString(),
                anyString(),
                any(),
                anyString(),
                anyString(),
                anyString(),
                any()
        )).thenReturn(sampleClaim(false));

        service.processClaimForUser(USER_ID, validRequest(null));

        ArgumentCaptor<String> requestJsonCaptor = ArgumentCaptor.forClass(String.class);
        verify(repository).insert(
                eq(USER_ID),
                eq(CLAIM_ID),
                eq("gift"),
                eq("gift-welcome"),
                isNull(),
                requestJsonCaptor.capture(),
                anyString(),
                eq(ClashClaimStatus.ACCEPTED),
                isNull()
        );
        assertFalse(requestJsonCaptor.getValue().contains("userId"));
        assertFalse(requestJsonCaptor.getValue().contains("idUsuario"));
    }

    @Test
    void duplicateInsertRaceReturnsAlreadyProcessed() throws SQLException {
        when(repository.findByUserIdAndClaimId(USER_ID, CLAIM_ID))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(sampleClaim(false)));
        when(repository.insert(
                anyLong(),
                anyString(),
                anyString(),
                anyString(),
                any(),
                anyString(),
                anyString(),
                anyString(),
                any()
        )).thenThrow(new SQLException("Duplicate entry '42-gift:gift-welcome' for key 'uk_clash_claim_usuario_claim'"));

        ClashClaimResponse response = service.processClaimForUser(USER_ID, validRequest(null));

        assertTrue(response.alreadyProcessed());
        assertEquals(CLAIM_ID, response.claimId());
    }

    private static ClashClaimRequest validRequest(Integer expectedRevision) {
        ObjectNode payload = JSON.createObjectNode();
        payload.put("note", "optional");
        return new ClashClaimRequest(
                CLAIM_ID,
                "gift",
                "gift-welcome",
                null,
                expectedRevision,
                payload
        );
    }

    private static ClashClaim sampleClaim(boolean alreadyProcessed) throws SQLException {
        return sampleClaimForUser(USER_ID, alreadyProcessed);
    }

    private static ClashClaim sampleClaimForUser(long userId, boolean alreadyProcessed)
            throws SQLException {
        ClashClaimResponse response = new ClashClaimResponse(
                CLAIM_ID,
                ClashClaimStatus.ACCEPTED,
                alreadyProcessed,
                null,
                null,
                "Claim registrado. La concesión de recompensas server-side llegará en una fase posterior."
        );
        try {
            return new ClashClaim(
                    1L,
                    userId,
                    CLAIM_ID,
                    "gift",
                    "gift-welcome",
                    null,
                    JSON.writeValueAsString(validRequest(null)),
                    JSON.writeValueAsString(response),
                    ClashClaimStatus.ACCEPTED,
                    null,
                    NOW,
                    NOW
            );
        } catch (Exception e) {
            throw new SQLException(e);
        }
    }
}
