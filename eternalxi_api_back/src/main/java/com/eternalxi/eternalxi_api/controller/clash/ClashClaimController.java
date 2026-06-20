package com.eternalxi.eternalxi_api.controller.clash;

import com.eternalxi.eternalxi_api.dto.clash.ClashClaimRequest;
import com.eternalxi.eternalxi_api.dto.clash.ClashClaimResponse;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.ClashClaimService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/clash/claims")
public class ClashClaimController {

    private final ClashClaimService clashClaimService;

    public ClashClaimController(ClashClaimService clashClaimService) {
        this.clashClaimService = clashClaimService;
    }

    @PostMapping
    public ResponseEntity<ClashClaimResponse> processClaim(@RequestBody ClashClaimRequest request)
            throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        ClashClaimResponse response = clashClaimService.processClaimForUser(userId, request);
        HttpStatus status = response.alreadyProcessed() ? HttpStatus.OK : HttpStatus.CREATED;
        return ResponseEntity.status(status).body(response);
    }
}
