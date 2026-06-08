package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.exception.EmailDeliveryException;
import com.eternalxi.eternalxi_api.util.PublicApiUrlBuilder;
import com.eternalxi.eternalxi_api.util.SecureTokenHasher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Service
public class AccountDeletionService {

    private static final Logger log = LoggerFactory.getLogger(AccountDeletionService.class);
    private static final int CODE_LENGTH = 6;
    private static final int TOKEN_BYTES = 32;
    private static final int EXPIRY_MINUTES = 30;
    static final String REDACTED_EMAIL_SNAPSHOT = "";

    private final EmailService emailService;
    private final LeagueService leagueService;
    private final String userPhotosDir;
    private final String publicApiBaseUrl;

    public AccountDeletionService(
            EmailService emailService,
            LeagueService leagueService,
            @Value("${app.user-photos-dir:/opt/eternalxi/uploads/user-photos}") String userPhotosDir,
            @Value("${eternalxi.app.public-api-base-url:https://api.eternalxi.com}") String publicApiBaseUrl
    ) {
        this.emailService = emailService;
        this.leagueService = leagueService;
        this.userPhotosDir = userPhotosDir;
        this.publicApiBaseUrl = PublicApiUrlBuilder.normalizePublicApiBaseUrl(publicApiBaseUrl);
    }

    public void requestDeletion(long userId) throws SQLException {
        String correo = loadCorreoById(userId);
        if (correo == null || correo.isBlank()) {
            throw new IllegalArgumentException("Usuario no encontrado");
        }

        String codigo = generarCodigo();
        String token = generarToken();
        String codeHash = SecureTokenHasher.sha256Hex(codigo);
        String tokenHash = SecureTokenHasher.sha256Hex(token);
        Instant expiresAt = Instant.now().plus(EXPIRY_MINUTES, ChronoUnit.MINUTES);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement del = conn.prepareStatement(
                        "DELETE FROM account_deletion_requests WHERE id_usuario = ? AND used_at IS NULL")) {
                    del.setLong(1, userId);
                    del.executeUpdate();
                }

                try (PreparedStatement ins = conn.prepareStatement("""
                        INSERT INTO account_deletion_requests
                            (id_usuario, email_snapshot, code_hash, token_hash, expires_at)
                        VALUES (?, ?, ?, ?, ?)
                        """)) {
                    ins.setLong(1, userId);
                    ins.setString(2, correo);
                    ins.setString(3, codeHash);
                    ins.setString(4, tokenHash);
                    ins.setTimestamp(5, Timestamp.from(expiresAt));
                    ins.executeUpdate();
                }
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }

        String confirmUrl = PublicApiUrlBuilder.buildAccountDeletionConfirmUrl(publicApiBaseUrl, token);
        try {
            emailService.enviarConfirmacionEliminacionCuenta(correo, codigo, confirmUrl);
        } catch (EmailDeliveryException e) {
            invalidatePendingRequests(userId);
            throw e;
        }

        log.info("Solicitud de eliminación de cuenta creada para userId={}", userId);
    }

    public void confirmDeletionByCode(long userId, String codigo) throws SQLException {
        if (codigo == null || codigo.isBlank()) {
            throw new IllegalArgumentException("Código obligatorio");
        }
        String normalized = codigo.trim().toUpperCase();
        PendingDeletionRequest pending = loadPendingByUserAndCodeHash(userId, SecureTokenHasher.sha256Hex(normalized));
        if (pending == null) {
            throw new IllegalArgumentException("Código inválido o expirado");
        }
        executeConfirmedDeletion(pending);
    }

    public String invalidConfirmationLinkHtml() {
        return renderHtmlPage(
                "Enlace no válido",
                "El enlace ha expirado, ya se usó o no es válido. Solicita una nueva eliminación desde la app Eternal XI.",
                false
        );
    }

    public String confirmDeletionByToken(String token) throws SQLException {
        if (token == null || token.isBlank()) {
            return invalidConfirmationLinkHtml();
        }
        PendingDeletionRequest pending = loadPendingByTokenHash(SecureTokenHasher.sha256Hex(token.trim()));
        if (pending == null) {
            return renderHtmlPage(
                    "Enlace no válido",
                    "El enlace ha expirado, ya se usó o no es válido. Solicita una nueva eliminación desde la app Eternal XI.",
                    false
            );
        }
        executeConfirmedDeletion(pending);
        return renderHtmlPage(
                "Cuenta eliminada",
                "Tu cuenta de Eternal XI y los datos asociados se han eliminado correctamente.",
                true
        );
    }

    private void executeConfirmedDeletion(PendingDeletionRequest pending) throws SQLException {
        if (pending.usedAt() != null) {
            throw new IllegalArgumentException("La solicitud ya fue utilizada");
        }
        if (pending.expiresAt().isBefore(Instant.now())) {
            throw new IllegalArgumentException("La solicitud ha expirado");
        }

        long userId = pending.userId();
        leagueService.removeUserFromAllLeaguesForAccountDeletion(userId);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                deleteUserScopedData(conn, userId);
                deleteUserPhotoIfAny(conn, userId);
                deleteUsuario(conn, userId);
                markRequestUsed(conn, pending.id());
                conn.commit();
                log.info("Cuenta eliminada userId={}", userId);
            } catch (Exception e) {
                conn.rollback();
                if (e instanceof SQLException sql) {
                    throw sql;
                }
                throw new SQLException("Error eliminando cuenta: " + e.getMessage(), e);
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void deleteUserScopedData(Connection conn, long userId) throws SQLException {
        anonymizeActivityActor(conn, userId);

        String[] deletes = {
                "DELETE FROM usuario_notificaciones WHERE id_usuario = ?",
                "DELETE FROM usuario_push_tokens WHERE id_usuario = ?",
                "DELETE FROM liga_notificaciones_enviadas WHERE id_usuario = ?",
                "DELETE FROM liga_movimientos_economicos WHERE id_usuario = ?",
                "DELETE FROM usuario_temporadas WHERE id_usuario = ?",
                "DELETE FROM usuario_recursos WHERE id_usuario = ?"
        };

        for (String sql : deletes) {
            executeOptionalDelete(conn, sql, userId);
        }

        String correo = loadCorreoById(conn, userId);
        if (correo != null && !correo.isBlank()) {
            executeOptionalDeleteByString(
                    conn,
                    "DELETE FROM codigos_verificacion WHERE LOWER(correo) = LOWER(?)",
                    correo
            );
        }
    }

    private void anonymizeActivityActor(Connection conn, long userId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("""
                UPDATE liga_actividad
                SET id_actor_usuario = NULL
                WHERE id_actor_usuario = ?
                """)) {
            ps.setLong(1, userId);
            ps.executeUpdate();
        }
    }

    private void deleteUsuario(Connection conn, long userId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("DELETE FROM usuarios WHERE id = ?")) {
            ps.setLong(1, userId);
            int rows = ps.executeUpdate();
            if (rows <= 0) {
                throw new IllegalArgumentException("Usuario no encontrado");
            }
        }
    }

    private void deleteUserPhotoIfAny(Connection conn, long userId) throws SQLException {
        String foto;
        try (PreparedStatement ps = conn.prepareStatement("SELECT foto FROM usuarios WHERE id = ?")) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return;
                }
                foto = rs.getString("foto");
            }
        }
        if (foto == null || foto.isBlank()) {
            return;
        }
        try {
            Path filePath = Paths.get(userPhotosDir).resolve(foto).normalize();
            Files.deleteIfExists(filePath);
        } catch (IOException ignored) {
        }
    }

    private void markRequestUsed(Connection conn, long requestId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("""
                UPDATE account_deletion_requests
                SET used_at = CURRENT_TIMESTAMP(3),
                    email_snapshot = ?
                WHERE id = ?
                """)) {
            ps.setString(1, REDACTED_EMAIL_SNAPSHOT);
            ps.setLong(2, requestId);
            ps.executeUpdate();
        }
    }

    private void invalidatePendingRequests(long userId) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM account_deletion_requests WHERE id_usuario = ? AND used_at IS NULL")) {
            ps.setLong(1, userId);
            ps.executeUpdate();
        }
    }

    private PendingDeletionRequest loadPendingByUserAndCodeHash(long userId, String codeHash) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("""
                     SELECT id, id_usuario, expires_at, used_at
                     FROM account_deletion_requests
                     WHERE id_usuario = ?
                       AND code_hash = ?
                       AND used_at IS NULL
                       AND expires_at > CURRENT_TIMESTAMP(3)
                     ORDER BY created_at DESC
                     LIMIT 1
                     """)) {
            ps.setLong(1, userId);
            ps.setString(2, codeHash);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return mapPending(rs);
            }
        }
    }

    private PendingDeletionRequest loadPendingByTokenHash(String tokenHash) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("""
                     SELECT id, id_usuario, expires_at, used_at
                     FROM account_deletion_requests
                     WHERE token_hash = ?
                       AND used_at IS NULL
                       AND expires_at > CURRENT_TIMESTAMP(3)
                     ORDER BY created_at DESC
                     LIMIT 1
                     """)) {
            ps.setString(1, tokenHash);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return mapPending(rs);
            }
        }
    }

    private PendingDeletionRequest mapPending(ResultSet rs) throws SQLException {
        Timestamp expires = rs.getTimestamp("expires_at");
        Timestamp used = rs.getTimestamp("used_at");
        return new PendingDeletionRequest(
                rs.getLong("id"),
                rs.getLong("id_usuario"),
                expires == null ? Instant.EPOCH : expires.toInstant(),
                used == null ? null : used.toInstant()
        );
    }

    private String loadCorreoById(long userId) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            return loadCorreoById(conn, userId);
        }
    }

    private String loadCorreoById(Connection conn, long userId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT correo FROM usuarios WHERE id = ?")) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("correo") : null;
            }
        }
    }

    private String generarCodigo() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private String generarToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        new SecureRandom().nextBytes(bytes);
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private void executeOptionalDelete(Connection conn, String sql, long userId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try {
                ps.executeUpdate();
            } catch (SQLException e) {
                if (!isMissingTableOrColumn(e)) {
                    throw e;
                }
            }
        }
    }

    private void executeOptionalDeleteByString(Connection conn, String sql, String value) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value);
            try {
                ps.executeUpdate();
            } catch (SQLException e) {
                if (!isMissingTableOrColumn(e)) {
                    throw e;
                }
            }
        }
    }

    private boolean isMissingTableOrColumn(SQLException e) {
        String state = e.getSQLState();
        return "42S02".equals(state) || "42S22".equals(state);
    }

    private String renderHtmlPage(String title, String message, boolean success) {
        String color = success ? "#34a853" : "#ea4335";
        return """
                <!DOCTYPE html>
                <html lang="es">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>%s — Eternal XI</title>
                  <style>
                    body { font-family: system-ui, sans-serif; background:#0b1020; color:#e8ecf4; margin:0; padding:2rem; }
                    main { max-width:560px; margin:0 auto; background:#141b2d; border:1px solid #24304a; border-radius:12px; padding:1.5rem; }
                    h1 { color:%s; font-size:1.35rem; margin-top:0; }
                    p { line-height:1.6; }
                  </style>
                </head>
                <body>
                  <main>
                    <h1>%s</h1>
                    <p>%s</p>
                    <p style="color:#9aa6bd;font-size:0.9rem;">Eternal XI · es.eternalxi.app</p>
                  </main>
                </body>
                </html>
                """.formatted(escapeHtml(title), color, escapeHtml(title), escapeHtml(message));
    }

    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private record PendingDeletionRequest(long id, long userId, Instant expiresAt, Instant usedAt) {
    }
}
