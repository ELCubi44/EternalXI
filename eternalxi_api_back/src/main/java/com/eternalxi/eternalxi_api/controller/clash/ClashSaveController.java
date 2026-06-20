package com.eternalxi.eternalxi_api.controller.clash;

import com.eternalxi.eternalxi_api.dto.clash.ClashSaveUpdateRequest;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.ClashSaveService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/clash/save")
public class ClashSaveController {

    private final ClashSaveService clashSaveService;

    public ClashSaveController(ClashSaveService clashSaveService) {
        this.clashSaveService = clashSaveService;
    }

    @GetMapping
    public ResponseEntity<?> getSave() throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        return ResponseEntity.ok(clashSaveService.getSaveForUser(userId));
    }

    @PostMapping
    public ResponseEntity<?> createSave(@RequestBody ClashSaveUpdateRequest request) throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        return ResponseEntity.status(201).body(clashSaveService.createInitialSaveForUser(userId, request));
    }

    @PutMapping
    public ResponseEntity<?> updateSave(@RequestBody ClashSaveUpdateRequest request) throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        return ResponseEntity.ok(clashSaveService.updateSaveForUser(userId, request));
    }
}
