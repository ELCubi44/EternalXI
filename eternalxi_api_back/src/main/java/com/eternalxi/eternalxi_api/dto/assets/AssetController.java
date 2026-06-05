package com.eternalxi.eternalxi_api.dto.assets;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.services.AssetService;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.Locale;

@RestController
@RequestMapping("/api/v1/assets")
public class AssetController {

    private final AssetService assetService;

    public AssetController(AssetService assetService) {
        this.assetService = assetService;
    }

    @GetMapping("/players/{id}")
    public ResponseEntity<?> getPlayerPhoto(@PathVariable Long id) throws SQLException {
        return photoResponse(assetService.getPlayerPhoto(id), "No se ha encontrado la foto del jugador");
    }

    @GetMapping("/teams/{id}")
    public ResponseEntity<?> getTeamPhoto(@PathVariable Long id) throws SQLException {
        return photoResponse(assetService.getTeamPhoto(id), "No se ha encontrado la foto del equipo");
    }

    @GetMapping("/seasons/{id}")
    public ResponseEntity<?> getSeasonPhoto(@PathVariable Long id) throws SQLException {
        return photoResponse(assetService.getSeasonPhoto(id), "No se ha encontrado la foto de la temporada");
    }

    @GetMapping("/loan-players/{id}")
    public ResponseEntity<?> getLoanPlayerPhoto(@PathVariable Long id) throws SQLException {
        return photoResponse(assetService.getLoanPlayerPhoto(id), "No se ha encontrado la foto del jugador cedido");
    }

    @GetMapping("/managers/{id}")
    public ResponseEntity<?> getManagerPhoto(@PathVariable Long id) throws SQLException {
        return photoResponse(assetService.getManagerPhoto(id), "No se ha encontrado la foto del entrenador");
    }

    private ResponseEntity<?> photoResponse(Resource resource, String notFoundMessage) {
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse(notFoundMessage));
        }
        return ResponseEntity.ok().contentType(mediaTypeFor(resource)).body(resource);
    }

    private MediaType mediaTypeFor(Resource resource) {
        try {
            String filename = resource.getFilename();
            if (filename != null) {
                String lower = filename.toLowerCase(Locale.ROOT);
                if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
                    return MediaType.IMAGE_JPEG;
                }
                if (lower.endsWith(".webp")) {
                    return MediaType.parseMediaType("image/webp");
                }
                if (lower.endsWith(".gif")) {
                    return MediaType.IMAGE_GIF;
                }
            }
        } catch (Exception ignored) {
            // PNG por defecto
        }
        return MediaType.IMAGE_PNG;
    }
}
