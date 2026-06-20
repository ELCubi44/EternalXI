package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.clash.ClashClaimRequest;
import com.eternalxi.eternalxi_api.dto.clash.ClashClaimResponse;
import com.eternalxi.eternalxi_api.model.ClashClaim;
import com.eternalxi.eternalxi_api.model.ClashClaimStatus;
import com.eternalxi.eternalxi_api.repository.ClashClaimRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.NullNode;
import org.springframework.stereotype.Service;

import java.sql.SQLException;
import java.util.Optional;

@Service
public class ClashClaimService {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final String ACCEPTED_MESSAGE =
            "Claim registrado. La concesión de recompensas server-side llegará en una fase posterior.";

    private final ClashClaimRepository clashClaimRepository;

    public ClashClaimService(ClashClaimRepository clashClaimRepository) {
        this.clashClaimRepository = clashClaimRepository;
    }

    /**
     * Procesa un claim idempotente para el usuario autenticado (resuelto en controller).
     * No modifica {@code clash_save} ni concede economía real en esta fase.
     */
    public ClashClaimResponse processClaimForUser(long userId, ClashClaimRequest request)
            throws SQLException {
        validateRequest(request);

        var existing = clashClaimRepository.findByUserIdAndClaimId(userId, request.claimId().trim());
        if (existing.isPresent()) {
            return toStoredResponse(existing.get(), true);
        }

        ClashClaimResponse accepted = buildAcceptedResponse(request);
        String requestJson = serializeRequestSnapshot(request);
        String responseJson = serializeResponse(accepted);

        try {
            clashClaimRepository.insert(
                    userId,
                    request.claimId().trim(),
                    request.claimType().trim(),
                    request.sourceId().trim(),
                    normalizeOptionalText(request.stageId()),
                    requestJson,
                    responseJson,
                    ClashClaimStatus.ACCEPTED,
                    request.expectedServerRevision()
            );
        } catch (SQLException e) {
            if (isDuplicateKey(e)) {
                Optional<ClashClaim> reread =
                        clashClaimRepository.findByUserIdAndClaimId(userId, request.claimId().trim());
                if (reread.isPresent()) {
                    return toStoredResponse(reread.get(), true);
                }
            }
            throw e;
        }

        return accepted;
    }

    private void validateRequest(ClashClaimRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("El cuerpo de la petición es obligatorio");
        }
        if (isBlank(request.claimId())) {
            throw new IllegalArgumentException("claimId es obligatorio");
        }
        if (isBlank(request.claimType())) {
            throw new IllegalArgumentException("claimType es obligatorio");
        }
        if (isBlank(request.sourceId())) {
            throw new IllegalArgumentException("sourceId es obligatorio");
        }
        if (request.expectedServerRevision() != null && request.expectedServerRevision() < 1) {
            throw new IllegalArgumentException("expectedServerRevision debe ser >= 1");
        }
    }

    private ClashClaimResponse buildAcceptedResponse(ClashClaimRequest request) {
        return new ClashClaimResponse(
                request.claimId().trim(),
                ClashClaimStatus.ACCEPTED,
                false,
                request.expectedServerRevision(),
                NullNode.getInstance(),
                ACCEPTED_MESSAGE
        );
    }

    private ClashClaimResponse toStoredResponse(ClashClaim claim, boolean alreadyProcessed)
            throws SQLException {
        try {
            ClashClaimResponse stored = JSON.readValue(claim.responseJson(), ClashClaimResponse.class);
            return new ClashClaimResponse(
                    stored.claimId(),
                    stored.status(),
                    alreadyProcessed,
                    stored.serverRevision(),
                    stored.rewards(),
                    stored.message()
            );
        } catch (JsonProcessingException e) {
            throw new SQLException("response_json inválido para claim " + claim.claimId(), e);
        }
    }

    private String serializeRequestSnapshot(ClashClaimRequest request) {
        try {
            return JSON.writeValueAsString(request);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("No se pudo serializar la petición de claim", e);
        }
    }

    private String serializeResponse(ClashClaimResponse response) throws SQLException {
        try {
            return JSON.writeValueAsString(response);
        } catch (JsonProcessingException e) {
            throw new SQLException("No se pudo serializar la respuesta de claim", e);
        }
    }

    private static String normalizeOptionalText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static boolean isDuplicateKey(SQLException e) {
        if (e.getErrorCode() == 1062) {
            return true;
        }
        String message = e.getMessage();
        return message != null && message.toLowerCase().contains("duplicate");
    }
}
