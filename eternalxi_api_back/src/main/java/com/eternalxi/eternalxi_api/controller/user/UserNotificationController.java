package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.MarkUserNotificationsReadRequest;
import com.eternalxi.eternalxi_api.dto.user.UserNotificationsListResponse;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.UserNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserNotificationController {

    private final UserNotificationService userNotificationService;

    public UserNotificationController(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    @GetMapping("/{idUsuario}/notifications")
    public ResponseEntity<?> listNotifications(
            @PathVariable Long idUsuario,
            @RequestParam(required = false) Long idLiga,
            @RequestParam(required = false) Integer limit
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        UserNotificationsListResponse response =
                userNotificationService.listForUser(idUsuario, idLiga, limit);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{idUsuario}/notifications/unread-count")
    public ResponseEntity<?> unreadCount(
            @PathVariable Long idUsuario,
            @RequestParam(required = false) Long idLiga
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        int count = userNotificationService.countUnread(idUsuario, idLiga);
        return ResponseEntity.ok(Map.of("noLeidas", count));
    }

    @PostMapping("/notifications/mark-read")
    public ResponseEntity<?> markRead(@RequestBody MarkUserNotificationsReadRequest request) throws SQLException {
        if (request == null || request.idUsuario() == null || request.idUsuario() <= 0) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        userNotificationService.markRead(
                request.idUsuario(),
                request.ids(),
                request.idLiga(),
                request.marcarTodas()
        );
        return ResponseEntity.ok(new ApiMessageResponse("Notificaciones marcadas como leídas"));
    }
}
