package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.RegisterAvatarUnlocksRequest;
import com.eternalxi.eternalxi_api.dto.user.UpdateFavoritePlayerRequest;
import com.eternalxi.eternalxi_api.dto.user.UserPublicProfileResponse;
import com.eternalxi.eternalxi_api.services.AccountProgressService;
import com.eternalxi.eternalxi_api.services.UserPublicProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/users")
public class UserPublicProfileController {

    private final UserPublicProfileService userPublicProfileService;
    private final AccountProgressService accountProgressService;

    public UserPublicProfileController(
            UserPublicProfileService userPublicProfileService,
            AccountProgressService accountProgressService
    ) {
        this.userPublicProfileService = userPublicProfileService;
        this.accountProgressService = accountProgressService;
    }

    @GetMapping("/{id}/public-profile")
    public ResponseEntity<?> getPublicProfile(
            @PathVariable Long id,
            @RequestParam(name = "idUsuario", required = false) Long viewerId
    ) throws SQLException {
        try {
            UserPublicProfileResponse profile = userPublicProfileService.loadProfile(viewerId, id);
            return ResponseEntity.ok(profile);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(ex.getMessage()));
        }
    }

    @GetMapping("/{id}/public-progress")
    public ResponseEntity<?> getPublicProgress(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(accountProgressService.loadPublicProgress(id));
        } catch (SQLException e) {
            return ResponseEntity.internalServerError()
                    .body(new ApiMessageResponse("No se pudo cargar el progreso"));
        }
    }

    @GetMapping("/{id}/favorite-player-options")
    public ResponseEntity<?> getFavoritePlayerOptions(@PathVariable Long id) throws SQLException {
        try {
            return ResponseEntity.ok(userPublicProfileService.listEligibleFavoritePlayers(id));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(ex.getMessage()));
        }
    }

    @PostMapping("/{id}/avatar-unlocks")
    public ResponseEntity<?> registerAvatarUnlocks(
            @PathVariable Long id,
            @RequestBody RegisterAvatarUnlocksRequest body
    ) throws SQLException {
        try {
            userPublicProfileService.registerAvatarUnlocks(
                    id,
                    body.playerIds(),
                    body.origen()
            );
            return ResponseEntity.ok(new ApiMessageResponse("Avatares desbloqueados"));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(ex.getMessage()));
        }
    }

    @PatchMapping("/{id}/favorite-player")
    public ResponseEntity<?> updateFavoritePlayer(
            @PathVariable Long id,
            @RequestBody UpdateFavoritePlayerRequest body
    ) throws SQLException {
        try {
            userPublicProfileService.updateFavoritePlayer(id, body.idJugador());
            return ResponseEntity.ok(new ApiMessageResponse("Jugador favorito actualizado"));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(ex.getMessage()));
        }
    }
}
