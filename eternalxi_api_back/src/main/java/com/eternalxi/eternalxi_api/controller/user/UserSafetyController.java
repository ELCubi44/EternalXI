package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.BlockUserRequest;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.UserSafetyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/users")
public class UserSafetyController {

    private final UserSafetyService userSafetyService;

    public UserSafetyController(UserSafetyService userSafetyService) {
        this.userSafetyService = userSafetyService;
    }

    @PostMapping("/block")
    public ResponseEntity<?> blockUser(@RequestBody BlockUserRequest request) throws SQLException {
        if (request.idUsuario() == null || request.idUsuarioBloqueado() == null) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Faltan datos obligatorios"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        try {
            userSafetyService.blockUser(request.idUsuario(), request.idUsuarioBloqueado());
            return ResponseEntity.ok(new ApiMessageResponse("Usuario bloqueado"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{idUsuario}/block/{idUsuarioBloqueado}")
    public ResponseEntity<?> unblockUser(
            @PathVariable Long idUsuario,
            @PathVariable Long idUsuarioBloqueado
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        userSafetyService.unblockUser(idUsuario, idUsuarioBloqueado);
        return ResponseEntity.ok(new ApiMessageResponse("Usuario desbloqueado"));
    }
}
