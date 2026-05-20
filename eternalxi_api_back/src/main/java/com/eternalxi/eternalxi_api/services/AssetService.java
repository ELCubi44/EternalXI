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

@Service
public class AssetService {

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

                Path filePath;
                try {
                    filePath = Paths.get(foto).normalize();
                } catch (InvalidPathException | SecurityException e) {
                    return null;
                }

                if (!Files.exists(filePath)) {
                    return null;
                }

                if (!Files.isReadable(filePath) || Files.isDirectory(filePath)) {
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
        }
    }
}