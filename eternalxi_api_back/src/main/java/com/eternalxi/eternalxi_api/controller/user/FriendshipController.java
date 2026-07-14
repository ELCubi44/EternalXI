package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.FriendRequestBody;
import com.eternalxi.eternalxi_api.dto.user.FriendshipResponse;
import com.eternalxi.eternalxi_api.dto.user.UserSearchResultResponse;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.FriendshipService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
public class FriendshipController {

    private final FriendshipService friendshipService;

    public FriendshipController(FriendshipService friendshipService) {
        this.friendshipService = friendshipService;
    }

    @GetMapping("/{idUsuario}/friends")
    public ResponseEntity<List<FriendshipResponse>> listFriends(
            @PathVariable Long idUsuario
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        return ResponseEntity.ok(friendshipService.listFriendships(idUsuario));
    }

    @GetMapping("/{idUsuario}/friends/search")
    public ResponseEntity<List<UserSearchResultResponse>> searchUsers(
            @PathVariable Long idUsuario,
            @RequestParam String q
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        return ResponseEntity.ok(friendshipService.searchUsers(idUsuario, q));
    }

    @PostMapping("/{idUsuario}/friends")
    public ResponseEntity<?> sendFriendRequest(
            @PathVariable Long idUsuario,
            @RequestBody FriendRequestBody body
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        if (body.idAmigo() == null) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Falta el usuario"));
        }
        try {
            FriendshipResponse row = friendshipService.sendRequest(idUsuario, body.idAmigo());
            return ResponseEntity.status(HttpStatus.CREATED).body(row);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/{idUsuario}/friends/{idAmistad}/accept")
    public ResponseEntity<?> acceptFriendRequest(
            @PathVariable Long idUsuario,
            @PathVariable Long idAmistad
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        try {
            FriendshipResponse row = friendshipService.accept(idUsuario, idAmistad);
            return ResponseEntity.ok(row);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{idUsuario}/friends/requests/{idAmistad}")
    public ResponseEntity<?> rejectFriendRequest(
            @PathVariable Long idUsuario,
            @PathVariable Long idAmistad
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        try {
            friendshipService.reject(idUsuario, idAmistad);
            return ResponseEntity.ok(new ApiMessageResponse("Solicitud rechazada"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{idUsuario}/friends/{idAmigo}")
    public ResponseEntity<?> removeFriend(
            @PathVariable Long idUsuario,
            @PathVariable Long idAmigo
    ) throws SQLException {
        AuthenticatedUser.assertSameUser(idUsuario);
        friendshipService.remove(idUsuario, idAmigo);
        return ResponseEntity.ok(new ApiMessageResponse("Amistad eliminada"));
    }
}
