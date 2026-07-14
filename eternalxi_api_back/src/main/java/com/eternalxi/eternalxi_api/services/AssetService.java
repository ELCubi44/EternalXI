package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;

import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

@Service
public class AssetService {

    private static final Path ETERNALXI_ROOT = Paths.get("/opt/eternalxi");

    private static final Map<String, String> TABLE_ASSET_DIRS = Map.of(
            "jugadores", "players",
            "equipos", "teams",
            "temporadas", "season",
            "jugadores_cedidos_temporada", "players",
            "entrenadores", "managers"
    );

    public Resource getPlayerPhoto(Long id) throws SQLException {
        return getPhotoResource("jugadores", id);
    }

    public Resource getTeamPhoto(Long id) throws SQLException {
        return getPhotoResource("equipos", id);
    }

    public Resource getSeasonPhoto(Long id) throws SQLException {
        return getPhotoResource("temporadas", id);
    }

    public Resource getLoanPlayerPhoto(Long id) throws SQLException {
        return getPhotoResource("jugadores_cedidos_temporada", id);
    }

    public Resource getManagerPhoto(Long id) throws SQLException {
        return getPhotoResource("entrenadores", id);
    }

    public Resource getClashCardsCatalog() {
        return toReadableResource(ETERNALXI_ROOT.resolve("assets/clash/cards.json"));
    }

    private Resource getPhotoResource(String tableName, Long id) throws SQLException {
        String sql = "SELECT foto FROM " + tableName + " WHERE id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                String foto = rs.getString("foto");
                if (foto == null || foto.isBlank()) {
                    return null;
                }

                Path resolvedPath = resolveAssetPath(tableName, foto);
                if (resolvedPath == null) {
                    return null;
                }

                return toReadableResource(resolvedPath);
            }
        }
    }

    private Resource toReadableResource(Path filePath) {
        if (filePath == null) {
            return null;
        }

        Resource resource;
        try {
            resource = new UrlResource(filePath.toUri());
        } catch (Exception e) {
            return null;
        }

        if (!resource.exists() || !resource.isReadable()) {
            return null;
        }

        return resource;
    }

    private Path resolveAssetPath(String tableName, String foto) {
        Path primary = toExistingFile(foto);
        if (primary != null) {
            return primary;
        }

        String assetDir = TABLE_ASSET_DIRS.get(tableName);
        if (assetDir == null) {
            return null;
        }

        String normalized = foto.trim().replace('\\', '/');
        String fileName = Paths.get(normalized).getFileName().toString();
        if (fileName.isBlank()) {
            return null;
        }

        return toExistingFile(ETERNALXI_ROOT.resolve(assetDir).resolve(fileName).toString());
    }

    private Path toExistingFile(String pathValue) {
        if (pathValue == null || pathValue.isBlank()) {
            return null;
        }

        Path filePath;
        try {
            filePath = Paths.get(pathValue.trim()).normalize();
        } catch (InvalidPathException | SecurityException e) {
            return null;
        }

        if (!Files.exists(filePath) || !Files.isReadable(filePath) || Files.isDirectory(filePath)) {
            return null;
        }

        return filePath;
    }
}
