package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.RegisterPushTokenRequest;
import com.eternalxi.eternalxi_api.services.UserPushTokenService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/users")
public class UserPushController {

    private final UserPushTokenService userPushTokenService;

    public UserPushController(UserPushTokenService userPushTokenService) {
        this.userPushTokenService = userPushTokenService;
    }

    @PostMapping("/push-token")
    public ResponseEntity<?> registerPushToken(@RequestBody RegisterPushTokenRequest request) throws SQLException {
        userPushTokenService.saveOrUpdateToken(
                request.idUsuario(),
                request.token(),
                request.plataforma(),
                request.deviceId()
        );
        return ResponseEntity.ok(new ApiMessageResponse("Token push registrado correctamente"));
    }
}
