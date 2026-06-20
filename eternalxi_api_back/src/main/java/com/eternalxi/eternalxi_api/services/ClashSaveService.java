package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.clash.ClashSaveConflictResponse;
import com.eternalxi.eternalxi_api.dto.clash.ClashSaveResponse;
import com.eternalxi.eternalxi_api.dto.clash.ClashSaveUpdateRequest;
import com.eternalxi.eternalxi_api.exception.ClashSaveAlreadyExistsException;
import com.eternalxi.eternalxi_api.exception.ClashSaveNotFoundException;
import com.eternalxi.eternalxi_api.exception.ClashSaveRevisionConflictException;
import com.eternalxi.eternalxi_api.model.ClashSave;
import com.eternalxi.eternalxi_api.repository.ClashSaveRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.sql.SQLException;

@Service
public class ClashSaveService {

    private static final ObjectMapper JSON = new ObjectMapper();

    private final ClashSaveRepository clashSaveRepository;

    public ClashSaveService(ClashSaveRepository clashSaveRepository) {
        this.clashSaveRepository = clashSaveRepository;
    }

    public ClashSaveResponse getSaveForUser(long userId) throws SQLException {
        ClashSave save = clashSaveRepository.findByUserId(userId)
                .orElseThrow(ClashSaveNotFoundException::new);
        return toResponse(save);
    }

    public ClashSaveResponse createInitialSaveForUser(long userId, ClashSaveUpdateRequest request)
            throws SQLException {
        validateSaveRequest(request, false);

        if (clashSaveRepository.existsByUserId(userId)) {
            throw new ClashSaveAlreadyExistsException();
        }

        String saveDataJson = serializeSaveData(request.saveData());
        ClashSave created = clashSaveRepository.insert(
                userId,
                request.contractVersion(),
                request.schemaVersion(),
                saveDataJson
        );
        return toResponse(created);
    }

    public ClashSaveResponse updateSaveForUser(long userId, ClashSaveUpdateRequest request)
            throws SQLException {
        validateSaveRequest(request, true);

        ClashSave current = clashSaveRepository.findByUserId(userId)
                .orElseThrow(ClashSaveNotFoundException::new);

        Integer expectedRevision = request.expectedServerRevision();
        if (expectedRevision == null || expectedRevision != current.serverRevision()) {
            throw new ClashSaveRevisionConflictException(buildConflictResponse(
                    current,
                    expectedRevision,
                    current.serverRevision()
            ));
        }

        String saveDataJson = serializeSaveData(request.saveData());
        int updatedRows = clashSaveRepository.updateWithExpectedRevision(
                userId,
                expectedRevision,
                request.contractVersion(),
                request.schemaVersion(),
                current.serverRevision() + 1,
                saveDataJson
        );

        if (updatedRows == 0) {
            ClashSave latest = clashSaveRepository.findByUserId(userId)
                    .orElseThrow(ClashSaveNotFoundException::new);
            throw new ClashSaveRevisionConflictException(buildConflictResponse(
                    latest,
                    expectedRevision,
                    latest.serverRevision()
            ));
        }

        return getSaveForUser(userId);
    }

    private void validateSaveRequest(ClashSaveUpdateRequest request, boolean requireExpectedRevision) {
        if (request == null) {
            throw new IllegalArgumentException("El cuerpo de la petición es obligatorio");
        }
        if (request.saveData() == null || request.saveData().isNull()) {
            throw new IllegalArgumentException("saveData es obligatorio");
        }
        if (request.contractVersion() < 1) {
            throw new IllegalArgumentException("contractVersion debe ser >= 1");
        }
        if (request.schemaVersion() < 1) {
            throw new IllegalArgumentException("schemaVersion debe ser >= 1");
        }
        if (requireExpectedRevision) {
            if (request.expectedServerRevision() == null) {
                throw new IllegalArgumentException("expectedServerRevision es obligatorio en PUT");
            }
            if (request.expectedServerRevision() < 1) {
                throw new IllegalArgumentException("expectedServerRevision debe ser >= 1");
            }
        }
    }

    private ClashSaveResponse toResponse(ClashSave save) throws SQLException {
        try {
            JsonNode saveData = JSON.readTree(save.saveDataJson());
            return new ClashSaveResponse(
                    save.serverRevision(),
                    save.contractVersion(),
                    save.schemaVersion(),
                    saveData,
                    save.updatedAt()
            );
        } catch (JsonProcessingException e) {
            throw new SQLException("save_data_json inválido para usuario " + save.userId(), e);
        }
    }

    private ClashSaveConflictResponse buildConflictResponse(
            ClashSave current,
            Integer expectedRevision,
            int actualRevision
    ) throws SQLException {
        try {
            JsonNode serverSaveData = JSON.readTree(current.saveDataJson());
            String reason = expectedRevision == null
                    ? "expectedServerRevision es obligatorio"
                    : "expectedServerRevision " + expectedRevision + " != current " + actualRevision;
            return new ClashSaveConflictResponse(
                    actualRevision,
                    serverSaveData,
                    reason
            );
        } catch (JsonProcessingException e) {
            throw new SQLException("save_data_json inválido en conflicto", e);
        }
    }

    private String serializeSaveData(JsonNode saveData) {
        return saveData.toString();
    }
}
