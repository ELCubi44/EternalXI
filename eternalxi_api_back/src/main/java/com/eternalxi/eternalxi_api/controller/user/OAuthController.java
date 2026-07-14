package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.auth.AuthResponse;
import com.eternalxi.eternalxi_api.dto.auth.OAuthLinkRequest;
import com.eternalxi.eternalxi_api.dto.auth.OAuthLoginRequest;
import com.eternalxi.eternalxi_api.dto.auth.OAuthProvidersResponse;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.OAuthAuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/auth/oauth")
public class OAuthController {

    private final OAuthAuthService oauthAuthService;

    public OAuthController(OAuthAuthService oauthAuthService) {
        this.oauthAuthService = oauthAuthService;
    }

    @PostMapping("/google")
    public ResponseEntity<?> loginGoogle(@RequestBody OAuthLoginRequest request) throws SQLException {
        if (request == null || request.idToken() == null || request.idToken().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Token de Google obligatorio"));
        }
        try {
            AuthResponse response = oauthAuthService.loginWithGoogle(
                    request.idToken(),
                    request.aceptaTerminos(),
                    request.nickname()
            );
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/apple")
    public ResponseEntity<?> loginApple(@RequestBody OAuthLoginRequest request) throws SQLException {
        if (request == null || request.idToken() == null || request.idToken().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Token de Apple obligatorio"));
        }
        try {
            AuthResponse response = oauthAuthService.loginWithApple(
                    request.idToken(),
                    request.aceptaTerminos(),
                    request.nickname()
            );
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/link/google")
    public ResponseEntity<?> linkGoogle(@RequestBody OAuthLinkRequest request) throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        if (request == null || request.idToken() == null || request.idToken().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Token de Google obligatorio"));
        }
        try {
            oauthAuthService.linkGoogle(userId, request.idToken());
            return ResponseEntity.ok(new ApiMessageResponse("Cuenta de Google vinculada"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/link/apple")
    public ResponseEntity<?> linkApple(@RequestBody OAuthLinkRequest request) throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        if (request == null || request.idToken() == null || request.idToken().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Token de Apple obligatorio"));
        }
        try {
            oauthAuthService.linkApple(userId, request.idToken());
            return ResponseEntity.ok(new ApiMessageResponse("Cuenta de Apple vinculada"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @GetMapping("/providers")
    public ResponseEntity<OAuthProvidersResponse> providers() throws SQLException {
        long userId = AuthenticatedUser.requireUserId();
        return ResponseEntity.ok(oauthAuthService.listProviders(userId));
    }
}
