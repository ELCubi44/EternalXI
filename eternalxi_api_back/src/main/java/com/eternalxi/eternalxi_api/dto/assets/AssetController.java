package com.eternalxi.eternalxi_api.dto.assets;

import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.services.AssetService;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/assets")
public class AssetController {

    private final AssetService assetService;

    public AssetController(AssetService assetService) {
        this.assetService = assetService;
    }

    @GetMapping("/players/{id}")
    public ResponseEntity<?> getPlayerPhoto(@PathVariable Long id) throws SQLException {
        Resource resource = assetService.getPlayerPhoto(id);
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse("No se ha encontrado la foto del jugador"));
        }
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(resource);
    }

    @GetMapping("/teams/{id}")
    public ResponseEntity<?> getTeamPhoto(@PathVariable Long id) throws SQLException {
        Resource resource = assetService.getTeamPhoto(id);
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse("No se ha encontrado la foto del equipo"));
        }
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(resource);
    }

    @GetMapping("/seasons/{id}")
    public ResponseEntity<?> getSeasonPhoto(@PathVariable Long id) throws SQLException {
        Resource resource = assetService.getSeasonPhoto(id);
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse("No se ha encontrado la foto de la temporada"));
        }
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(resource);
    }

    @GetMapping("/loan-players/{id}")
    public ResponseEntity<?> getLoanPlayerPhoto(@PathVariable Long id) throws SQLException {
        Resource resource = assetService.getLoanPlayerPhoto(id);
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse("No se ha encontrado la foto del jugador cedido"));
        }
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(resource);
    }

    @GetMapping("/managers/{id}")
    public ResponseEntity<?> getManagerPhoto(@PathVariable Long id) throws SQLException {
        Resource resource = assetService.getManagerPhoto(id);
        if (resource == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiMessageResponse("No se ha encontrado la foto del entrenador"));
        }
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(resource);
    }
}
