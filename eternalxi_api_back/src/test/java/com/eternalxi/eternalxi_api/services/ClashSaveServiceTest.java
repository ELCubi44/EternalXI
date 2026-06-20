package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.clash.ClashSaveResponse;
import com.eternalxi.eternalxi_api.dto.clash.ClashSaveUpdateRequest;
import com.eternalxi.eternalxi_api.exception.ClashSaveAlreadyExistsException;
import com.eternalxi.eternalxi_api.exception.ClashSaveNotFoundException;
import com.eternalxi.eternalxi_api.exception.ClashSaveRevisionConflictException;
import com.eternalxi.eternalxi_api.model.ClashSave;
import com.eternalxi.eternalxi_api.repository.ClashSaveRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.sql.SQLException;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ClashSaveServiceTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final long USER_ID = 42L;
    private static final Instant NOW = Instant.parse("2026-06-20T12:00:00Z");

    @Mock
    private ClashSaveRepository repository;

    private ClashSaveService service;

    @BeforeEach
    void setUp() {
        service = new ClashSaveService(repository);
    }

    @Test
    void getSaveForUserNotFoundThrows404() throws SQLException {
        when(repository.findByUserId(USER_ID)).thenReturn(Optional.empty());

        assertThrows(ClashSaveNotFoundException.class, () -> service.getSaveForUser(USER_ID));
    }

    @Test
    void createInitialSaveCreatesRevisionOne() throws SQLException {
        when(repository.existsByUserId(USER_ID)).thenReturn(false);
        when(repository.insert(eq(USER_ID), eq(1), eq(1), anyString()))
                .thenReturn(sampleSave(1, "{\"wallet\":{\"coins\":100}}"));

        ClashSaveResponse response = service.createInitialSaveForUser(USER_ID, validRequest(null));

        assertEquals(1, response.serverRevision());
        assertEquals(100, response.saveData().path("wallet").path("coins").asInt());
        verify(repository).insert(eq(USER_ID), eq(1), eq(1), anyString());
    }

    @Test
    void createInitialSaveDuplicateThrows409() throws SQLException {
        when(repository.existsByUserId(USER_ID)).thenReturn(true);

        assertThrows(
                ClashSaveAlreadyExistsException.class,
                () -> service.createInitialSaveForUser(USER_ID, validRequest(null))
        );
        verify(repository, never()).insert(anyLong(), anyInt(), anyInt(), anyString());
    }

    @Test
    void updateSaveIncrementsRevisionWhenExpectedMatches() throws SQLException {
        when(repository.findByUserId(USER_ID))
                .thenReturn(Optional.of(sampleSave(1, "{\"wallet\":{\"coins\":100}}")))
                .thenReturn(Optional.of(sampleSave(2, "{\"wallet\":{\"coins\":200}}")));
        when(repository.updateWithExpectedRevision(
                eq(USER_ID), eq(1), eq(1), eq(1), eq(2), anyString()
        )).thenReturn(1);

        ClashSaveUpdateRequest request;
        ObjectNode saveData = JSON.createObjectNode();
        saveData.putObject("wallet").put("coins", 200);
        request = new ClashSaveUpdateRequest(1, 1, 1, saveData, NOW);

        ClashSaveResponse response = service.updateSaveForUser(USER_ID, request);

        assertEquals(2, response.serverRevision());
        assertEquals(200, response.saveData().path("wallet").path("coins").asInt());
    }

    @Test
    void updateSaveWrongExpectedRevisionThrowsConflict() throws SQLException {
        when(repository.findByUserId(USER_ID))
                .thenReturn(Optional.of(sampleSave(2, "{\"wallet\":{\"coins\":150}}")));

        ClashSaveRevisionConflictException conflict = assertThrows(
                ClashSaveRevisionConflictException.class,
                () -> service.updateSaveForUser(USER_ID, validRequest(1))
        );

        assertEquals(2, conflict.getConflictResponse().serverRevision());
        assertEquals(150, conflict.getConflictResponse().serverSaveData().path("wallet").path("coins").asInt());
        verify(repository, never()).updateWithExpectedRevision(
                anyLong(), anyInt(), anyInt(), anyInt(), anyInt(), anyString()
        );
    }

    @Test
    void updateSaveMissingSaveThrows404() throws SQLException {
        when(repository.findByUserId(USER_ID)).thenReturn(Optional.empty());

        assertThrows(
                ClashSaveNotFoundException.class,
                () -> service.updateSaveForUser(USER_ID, validRequest(1))
        );
    }

    @Test
    void invalidRequestMissingSaveDataThrows400() {
        ClashSaveUpdateRequest request = new ClashSaveUpdateRequest(null, 1, 1, null, NOW);

        assertThrows(
                IllegalArgumentException.class,
                () -> service.createInitialSaveForUser(USER_ID, request)
        );
    }

    @Test
    void putRequiresExpectedServerRevision() {
        ClashSaveUpdateRequest request = validRequest(null);

        assertThrows(
                IllegalArgumentException.class,
                () -> service.updateSaveForUser(USER_ID, request)
        );
    }

    private static ClashSaveUpdateRequest validRequest(Integer expectedRevision) {
        ObjectNode saveData = JSON.createObjectNode();
        saveData.putObject("wallet").put("coins", 100);
        return new ClashSaveUpdateRequest(expectedRevision, 1, 1, saveData, NOW);
    }

    private static ClashSave sampleSave(int revision, String json) {
        return new ClashSave(
                1L,
                USER_ID,
                1,
                1,
                revision,
                json,
                NOW,
                NOW,
                NOW
        );
    }
}
