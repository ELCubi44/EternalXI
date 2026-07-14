package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.auth.AuthResponse;
import com.eternalxi.eternalxi_api.dto.auth.OAuthProvidersResponse;
import com.eternalxi.eternalxi_api.dto.user.UserResponse;
import com.eternalxi.eternalxi_api.security.JwtTokenService;
import com.eternalxi.eternalxi_api.security.PasswordHashService;
import com.eternalxi.eternalxi_api.security.oauth.OAuthTokenVerifier;
import com.eternalxi.eternalxi_api.util.UserMapper;
import com.eternalxi.eternalxi_api.validation.InputValidator;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.Locale;
import java.util.UUID;

@Service
public class OAuthAuthService {

    private static final long[] DEFAULT_TEMPORADA_IDS = {1L, 2L};
    private static final LocalDate OAUTH_DEFAULT_BIRTH_DATE = LocalDate.of(2000, 1, 1);

    private final OAuthTokenVerifier tokenVerifier;
    private final JwtTokenService jwtTokenService;
    private final PasswordHashService passwordHashService;

    public OAuthAuthService(
            OAuthTokenVerifier tokenVerifier,
            JwtTokenService jwtTokenService,
            PasswordHashService passwordHashService
    ) {
        this.tokenVerifier = tokenVerifier;
        this.jwtTokenService = jwtTokenService;
        this.passwordHashService = passwordHashService;
    }

    public AuthResponse loginWithGoogle(String idToken, Boolean aceptaTerminos, String nickname)
            throws SQLException {
        OAuthTokenVerifier.VerifiedOAuthIdentity identity = tokenVerifier.verifyGoogle(idToken);
        return loginOrRegister(identity, aceptaTerminos, nickname);
    }

    public AuthResponse loginWithApple(String idToken, Boolean aceptaTerminos, String nickname)
            throws SQLException {
        OAuthTokenVerifier.VerifiedOAuthIdentity identity = tokenVerifier.verifyApple(idToken);
        return loginOrRegister(identity, aceptaTerminos, nickname);
    }

    public void linkGoogle(Long userId, String idToken) throws SQLException {
        OAuthTokenVerifier.VerifiedOAuthIdentity identity = tokenVerifier.verifyGoogle(idToken);
        linkProvider(userId, identity);
    }

    public void linkApple(Long userId, String idToken) throws SQLException {
        OAuthTokenVerifier.VerifiedOAuthIdentity identity = tokenVerifier.verifyApple(idToken);
        linkProvider(userId, identity);
    }

    public OAuthProvidersResponse listProviders(Long userId) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            return new OAuthProvidersResponse(
                    hasProvider(conn, userId, "GOOGLE"),
                    hasProvider(conn, userId, "APPLE")
            );
        }
    }

    private AuthResponse loginOrRegister(
            OAuthTokenVerifier.VerifiedOAuthIdentity identity,
            Boolean aceptaTerminos,
            String nickname
    ) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            Long linkedUserId = findUserIdByProvider(conn, identity.provider(), identity.providerUserId());
            if (linkedUserId != null) {
                return buildAuthResponse(conn, linkedUserId);
            }

            if (identity.email() != null && !identity.email().isBlank()) {
                Long existingByEmail = findUserIdByEmail(conn, identity.email());
                if (existingByEmail != null) {
                    insertProviderLink(conn, existingByEmail, identity);
                    return buildAuthResponse(conn, existingByEmail);
                }
            }

            if (!Boolean.TRUE.equals(aceptaTerminos)) {
                throw new IllegalArgumentException("Debes aceptar los terminos de servicio");
            }

            long newUserId = createOAuthUser(conn, identity, nickname);
            insertProviderLink(conn, newUserId, identity);
            return buildAuthResponse(conn, newUserId);
        }
    }

    private void linkProvider(Long userId, OAuthTokenVerifier.VerifiedOAuthIdentity identity)
            throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            Long otherUser = findUserIdByProvider(conn, identity.provider(), identity.providerUserId());
            if (otherUser != null && !otherUser.equals(userId)) {
                throw new IllegalArgumentException("Esta cuenta ya esta vinculada a otro usuario");
            }
            if (hasProvider(conn, userId, identity.provider())) {
                return;
            }
            if (identity.email() != null && !identity.email().isBlank()) {
                Long emailOwner = findUserIdByEmail(conn, identity.email());
                if (emailOwner != null && !emailOwner.equals(userId)) {
                    throw new IllegalArgumentException("El correo ya pertenece a otra cuenta");
                }
            }
            insertProviderLink(conn, userId, identity);
        }
    }

    private AuthResponse buildAuthResponse(Connection conn, long userId) throws SQLException {
        UserResponse user = loadUser(conn, userId);
        return new AuthResponse(
                jwtTokenService.createAccessToken(userId, user.correo()),
                jwtTokenService.createRefreshToken(userId, user.correo()),
                "Bearer",
                user
        );
    }

    private UserResponse loadUser(Connection conn, long userId) throws SQLException {
        String sql = """
                SELECT id, correo, nickname, nivel, foto, fecha_nacimiento
                FROM usuarios WHERE id = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Usuario no encontrado");
                }
                return UserMapper.fromResultSet(rs, userId);
            }
        }
    }

    private long createOAuthUser(
            Connection conn,
            OAuthTokenVerifier.VerifiedOAuthIdentity identity,
            String nickname
    ) throws SQLException {
        String email = identity.email();
        if (email == null || email.isBlank()) {
            email = identity.provider().toLowerCase(Locale.ROOT)
                    + "_" + identity.providerUserId().substring(0, Math.min(12, identity.providerUserId().length()))
                    + "@oauth.eternalxi.local";
        }
        String resolvedNickname = resolveNickname(conn, nickname, identity.displayName(), email);
        String unusablePassword = passwordHashService.hashForStorage(
                "oauth:" + UUID.randomUUID() + ":" + identity.providerUserId()
        );

        conn.setAutoCommit(false);
        try {
            String sqlInsertUsuario =
                    "INSERT INTO usuarios (correo, contrasena, nickname, nivel, fecha_nacimiento) VALUES (?, ?, ?, ?, ?)";
            long userId;
            try (PreparedStatement ps = conn.prepareStatement(sqlInsertUsuario, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, email);
                ps.setString(2, unusablePassword);
                ps.setString(3, resolvedNickname);
                ps.setInt(4, 1);
                ps.setDate(5, Date.valueOf(OAUTH_DEFAULT_BIRTH_DATE));
                if (ps.executeUpdate() <= 0) {
                    throw new SQLException("No se pudo crear el usuario OAuth");
                }
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("No se pudo obtener el id del usuario OAuth");
                    }
                    userId = keys.getLong(1);
                }
            }

            String sqlInsertUsuarioTemporada = "INSERT INTO usuario_temporadas (id_usuario, id_temporada) VALUES (?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sqlInsertUsuarioTemporada)) {
                for (long idTemporada : DEFAULT_TEMPORADA_IDS) {
                    ps.setLong(1, userId);
                    ps.setLong(2, idTemporada);
                    ps.executeUpdate();
                }
            }

            conn.commit();
            return userId;
        } catch (Exception e) {
            conn.rollback();
            if (e instanceof SQLException sqlException) {
                throw sqlException;
            }
            if (e instanceof IllegalArgumentException illegalArgumentException) {
                throw illegalArgumentException;
            }
            throw new SQLException("Error creando usuario OAuth: " + e.getMessage(), e);
        } finally {
            conn.setAutoCommit(true);
        }
    }

    private String resolveNickname(
            Connection conn,
            String requested,
            String displayName,
            String email
    ) throws SQLException {
        if (requested != null && !requested.isBlank()) {
            return InputValidator.validateNickname(requested.trim());
        }
        if (displayName != null && !displayName.isBlank()) {
            try {
                return InputValidator.validateNickname(sanitizeNickname(displayName));
            } catch (IllegalArgumentException ignored) {
                // fallback below
            }
        }
        String fromEmail = email == null ? "" : email.split("@")[0];
        String base = sanitizeNickname(fromEmail);
        if (base.length() < 3) {
            base = "player";
        }
        return ensureUniqueNickname(conn, base);
    }

    private String ensureUniqueNickname(Connection conn, String base) throws SQLException {
        String candidate = base;
        int suffix = 1;
        while (nicknameExists(conn, candidate)) {
            candidate = base + suffix;
            suffix++;
            if (suffix > 9999) {
                candidate = base + UUID.randomUUID().toString().substring(0, 4);
                break;
            }
        }
        return InputValidator.validateNickname(candidate);
    }

    private boolean nicknameExists(Connection conn, String nickname) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM usuarios WHERE LOWER(nickname) = ? LIMIT 1")) {
            ps.setString(1, nickname.toLowerCase(Locale.ROOT));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String sanitizeNickname(String raw) {
        String cleaned = raw.trim().replaceAll("[^a-zA-Z0-9_]", "");
        if (cleaned.length() > 20) {
            cleaned = cleaned.substring(0, 20);
        }
        if (cleaned.length() < 3) {
            return "player" + (System.currentTimeMillis() % 10000);
        }
        return cleaned;
    }

    private void insertProviderLink(
            Connection conn,
            long userId,
            OAuthTokenVerifier.VerifiedOAuthIdentity identity
    ) throws SQLException {
        String sql = """
                INSERT INTO usuario_oauth (id_usuario, proveedor, proveedor_usuario_id, email)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE email = VALUES(email)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, identity.provider());
            ps.setString(3, identity.providerUserId());
            ps.setString(4, identity.email());
            ps.executeUpdate();
        }
    }

    private Long findUserIdByProvider(Connection conn, String provider, String providerUserId)
            throws SQLException {
        String sql = """
                SELECT id_usuario FROM usuario_oauth
                WHERE proveedor = ? AND proveedor_usuario_id = ?
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, provider);
            ps.setString(2, providerUserId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id_usuario") : null;
            }
        }
    }

    private Long findUserIdByEmail(Connection conn, String email) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM usuarios WHERE LOWER(correo) = ? LIMIT 1")) {
            ps.setString(1, email.toLowerCase(Locale.ROOT));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    private boolean hasProvider(Connection conn, Long userId, String provider) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM usuario_oauth WHERE id_usuario = ? AND proveedor = ? LIMIT 1")) {
            ps.setLong(1, userId);
            ps.setString(2, provider);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}
