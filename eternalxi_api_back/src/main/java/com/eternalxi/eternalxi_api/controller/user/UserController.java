package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.validation.InputValidator;
import com.eternalxi.eternalxi_api.dto.user.UpdateUserPreferencesRequest;
import com.eternalxi.eternalxi_api.dto.user.UpdateUserRequest;
import com.eternalxi.eternalxi_api.dto.user.UserPreferencesResponse;
import com.eternalxi.eternalxi_api.dto.user.UserResourcesResponse;
import com.eternalxi.eternalxi_api.dto.user.UserResponse;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    @Value("${app.user-photos-dir:/opt/eternalxi/uploads/user-photos}")
    private String userPhotosDir;

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) throws SQLException {

        String sql = "SELECT id, correo, nickname, nivel, foto FROM usuarios WHERE id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }

                UserResponse user = new UserResponse(
                        rs.getLong("id"),
                        rs.getString("correo"),
                        rs.getString("nickname"),
                        rs.getInt("nivel"),
                        LeagueAssetUrls.userPhotoIfStored(rs.getLong("id"), rs.getString("foto"))
                );

                return ResponseEntity.ok(user);
            }
        }
    }

    @GetMapping("/{id}/resources")
    public ResponseEntity<?> getResources(@PathVariable Long id) throws SQLException {

        String sql = """
                SELECT u.id,
                       COALESCE(ur.fichas, 0) AS fichas,
                       COALESCE(ur.puntos_recompensa, 0) AS puntos_recompensa
                FROM usuarios u
                LEFT JOIN usuario_recursos ur
                    ON ur.id_usuario = u.id
                WHERE u.id = ?
                LIMIT 1
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }

                UserResourcesResponse response = new UserResourcesResponse(
                        rs.getLong("id"),
                        rs.getInt("fichas"),
                        rs.getLong("puntos_recompensa")
                );

                return ResponseEntity.ok(response);
            }
        }
    }

    @GetMapping("/{id}/preferences")
    public ResponseEntity<?> getPreferences(@PathVariable Long id) throws SQLException {

        String sql = """
                SELECT u.id,
                       up.theme_mode,
                       up.language_code
                FROM usuarios u
                LEFT JOIN usuario_preferencias up
                    ON up.id_usuario = u.id
                WHERE u.id = ?
                LIMIT 1
                """;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }

                UserPreferencesResponse response = new UserPreferencesResponse(
                        rs.getLong("id"),
                        normalizeThemeMode(rs.getString("theme_mode")),
                        normalizeLanguageCode(rs.getString("language_code"))
                );

                return ResponseEntity.ok(response);
            }
        }
    }

    @PutMapping("/{id}/preferences")
    public ResponseEntity<?> updatePreferences(
            @PathVariable Long id,
            @RequestBody UpdateUserPreferencesRequest request
    ) throws SQLException {
        if (request == null) {
            return ResponseEntity.badRequest()
                    .body(new ApiMessageResponse("Debes enviar las preferencias"));
        }

        String upsertSql = """
                INSERT INTO usuario_preferencias (
                    id_usuario,
                    theme_mode,
                    language_code
                )
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    theme_mode = VALUES(theme_mode),
                    language_code = VALUES(language_code)
                """;

        try (Connection conn = DBConnection.getConnection()) {
            if (!userExists(conn, id)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiMessageResponse("Usuario no encontrado"));
            }

            CurrentPreferences current = loadCurrentPreferences(conn, id);

            String themeMode = request.themeMode() != null
                    ? normalizeThemeMode(request.themeMode())
                    : current.themeMode();

            String languageCode = request.languageCode() != null
                    ? normalizeLanguageCode(request.languageCode())
                    : current.languageCode();

            try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
                ps.setLong(1, id);
                ps.setString(2, themeMode);
                ps.setString(3, languageCode);
                ps.executeUpdate();
            }

            return ResponseEntity.ok(new UserPreferencesResponse(
                    id,
                    themeMode,
                    languageCode
            ));
        }
    }

    @PatchMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody UpdateUserRequest request) throws SQLException {

        String sqlSelect = "SELECT id, correo, nickname, nivel, foto FROM usuarios WHERE id = ?";
        String sqlUpdate = "UPDATE usuarios SET nickname = ? WHERE id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {

            psSelect.setLong(1, id);

            String correoActual;
            String nicknameActual;
            int nivelActual;
            String fotoActual;

            try (ResultSet rs = psSelect.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }

                correoActual = rs.getString("correo");
                nicknameActual = rs.getString("nickname");
                nivelActual = rs.getInt("nivel");
                fotoActual = rs.getString("foto");
            }

            String nuevoNickname = request.nickname() != null
                    ? InputValidator.validateNickname(request.nickname())
                    : nicknameActual;

            psUpdate.setString(1, nuevoNickname);
            psUpdate.setLong(2, id);

            int filas = psUpdate.executeUpdate();

            if (filas <= 0) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(new ApiMessageResponse("No se pudo actualizar el usuario"));
            }

            UserResponse user = new UserResponse(
                    id,
                    correoActual,
                    nuevoNickname,
                    nivelActual,
                    fotoActual
            );

            return ResponseEntity.ok(user);
        }
    }

    @PutMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadUserPhoto(@PathVariable Long id, @RequestParam("file") MultipartFile file)
            throws SQLException, IOException {

        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Debes seleccionar una imagen"));
        }

        if (file.getContentType() == null || !file.getContentType().startsWith("image/")) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("El archivo enviado no es una imagen válida"));
        }

        String sqlExists = "SELECT id FROM usuarios WHERE id = ?";
        String sqlUpdate = "UPDATE usuarios SET foto = ? WHERE id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psExists = conn.prepareStatement(sqlExists)) {

            psExists.setLong(1, id);

            try (ResultSet rs = psExists.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }
            }

            BufferedImage bufferedImage = ImageIO.read(file.getInputStream());

            if (bufferedImage == null) {
                return ResponseEntity.badRequest()
                        .body(new ApiMessageResponse("No se ha podido procesar la imagen"));
            }

            Path uploadDir = Paths.get(userPhotosDir);
            Files.createDirectories(uploadDir);

            String fileName = id + ".png";
            Path filePath = uploadDir.resolve(fileName).normalize();

            try (OutputStream os = Files.newOutputStream(
                    filePath,
                    StandardOpenOption.CREATE,
                    StandardOpenOption.TRUNCATE_EXISTING,
                    StandardOpenOption.WRITE
            )) {
                boolean written = ImageIO.write(bufferedImage, "png", os);

                if (!written) {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(new ApiMessageResponse("No se ha podido guardar la imagen en formato PNG"));
                }
            }

            try (PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {
                psUpdate.setString(1, fileName);
                psUpdate.setLong(2, id);

                int filas = psUpdate.executeUpdate();

                if (filas <= 0) {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(new ApiMessageResponse("No se ha podido actualizar la foto del usuario"));
                }
            }

            return ResponseEntity.ok(new ApiMessageResponse("Foto actualizada correctamente"));
        }
    }

    @GetMapping("/{id}/photo")
    public ResponseEntity<?> getUserPhoto(@PathVariable Long id) throws SQLException, IOException {

        String sql = "SELECT foto FROM usuarios WHERE id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("Usuario no encontrado"));
                }

                String foto = rs.getString("foto");

                if (foto == null || foto.isBlank()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("El usuario no tiene foto de perfil"));
                }

                Path filePath = Paths.get(userPhotosDir).resolve(foto).normalize();

                if (!Files.exists(filePath)) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No se ha encontrado el archivo de la foto"));
                }

                Resource resource = new UrlResource(filePath.toUri());

                if (!resource.exists() || !resource.isReadable()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No se puede leer la foto de perfil"));
                }

                return ResponseEntity.ok()
                        .contentType(MediaType.IMAGE_PNG)
                        .body(resource);
            }
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        return ResponseEntity.status(HttpStatus.GONE)
                .body(new ApiMessageResponse(
                        "La eliminación directa ya no está disponible. "
                                + "Usa Perfil > Eliminar cuenta en la app o POST /api/v1/account/deletion/request."
                ));
    }

    private boolean userExists(Connection conn, Long id) throws SQLException {
        String sql = """
                SELECT 1
                FROM usuarios
                WHERE id = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private CurrentPreferences loadCurrentPreferences(Connection conn, Long idUsuario) throws SQLException {
        String sql = """
                SELECT theme_mode, language_code
                FROM usuario_preferencias
                WHERE id_usuario = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return new CurrentPreferences("SYSTEM", "SYSTEM");
                }

                return new CurrentPreferences(
                        normalizeThemeMode(rs.getString("theme_mode")),
                        normalizeLanguageCode(rs.getString("language_code"))
                );
            }
        }
    }

    private String normalizeThemeMode(String raw) {
        if (raw == null || raw.isBlank()) {
            return "SYSTEM";
        }

        String value = raw.trim().toUpperCase(Locale.ROOT);

        return switch (value) {
            case "SYSTEM", "LIGHT", "DARK" -> value;
            default -> throw new IllegalArgumentException("themeMode debe ser SYSTEM, LIGHT o DARK");
        };
    }

    private String normalizeLanguageCode(String raw) {
        if (raw == null || raw.isBlank()) {
            return "SYSTEM";
        }

        String value = raw.trim();

        if ("SYSTEM".equalsIgnoreCase(value)) {
            return "SYSTEM";
        }

        if ("es".equalsIgnoreCase(value)) {
            return "es";
        }

        if ("en".equalsIgnoreCase(value)) {
            return "en";
        }

        throw new IllegalArgumentException("languageCode debe ser SYSTEM, es o en");
    }

    private record CurrentPreferences(String themeMode, String languageCode) {
    }
}
