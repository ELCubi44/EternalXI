package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.user.MarkProgressEventsSeenRequest;
import com.eternalxi.eternalxi_api.dto.user.UserProgressResponse;
import com.eternalxi.eternalxi_api.services.AccountProgressService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/users/{id}/progress")
public class UserProgressController {

    private static final Logger log = LoggerFactory.getLogger(UserProgressController.class);

    private final AccountProgressService accountProgressService;

    public UserProgressController(AccountProgressService accountProgressService) {
        this.accountProgressService = accountProgressService;
    }

    @GetMapping
    public ResponseEntity<?> getProgress(@PathVariable Long id) {
        try {
            UserProgressResponse progress = accountProgressService.loadProgress(id);
            return ResponseEntity.ok(progress);
        } catch (SQLException e) {
            log.error("Error cargando progreso id={}: {}", id, e.getMessage(), e);
            if (e.getMessage() != null && e.getMessage().contains("no encontrado")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiMessageResponse("Usuario no encontrado"));
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiMessageResponse("No se pudo cargar el progreso: " + e.getMessage()));
        }
    }

    @PostMapping("/events/seen")
    public ResponseEntity<?> markEventsSeen(
            @PathVariable Long id,
            @RequestBody MarkProgressEventsSeenRequest request
    ) {
        try {
            UserProgressResponse progress = accountProgressService.markEventsSeen(
                    id,
                    request == null ? null : request.idsEventos()
            );
            return ResponseEntity.ok(progress);
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiMessageResponse("No se pudieron marcar los eventos"));
        }
    }
}
