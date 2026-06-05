package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.auth.AuthResponse;
import com.eternalxi.eternalxi_api.dto.auth.CodeVerificationRequest;
import com.eternalxi.eternalxi_api.dto.auth.EmailChangeConfirmRequest;
import com.eternalxi.eternalxi_api.dto.auth.EmailChangeConfirmResponse;
import com.eternalxi.eternalxi_api.dto.auth.EmailChangeRequest;
import com.eternalxi.eternalxi_api.dto.auth.EmailRequest;
import com.eternalxi.eternalxi_api.dto.auth.LoginRequest;
import com.eternalxi.eternalxi_api.dto.auth.NicknameChangeConfirmRequest;
import com.eternalxi.eternalxi_api.dto.auth.NicknameChangeRequest;
import com.eternalxi.eternalxi_api.dto.auth.PasswordResetConfirmRequest;
import com.eternalxi.eternalxi_api.dto.auth.RegisterRequest;
import com.eternalxi.eternalxi_api.dto.auth.RegisterResponse;
import com.eternalxi.eternalxi_api.dto.user.UserResponse;
import com.eternalxi.eternalxi_api.dto.auth.RefreshTokenRequest;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.security.JwtTokenService;
import com.eternalxi.eternalxi_api.security.PasswordHashService;
import com.eternalxi.eternalxi_api.services.EmailService;
import io.jsonwebtoken.JwtException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.eternalxi.eternalxi_api.validation.InputValidator;
import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private static final long[] DEFAULT_TEMPORADA_IDS = {1L, 2L};

    private final EmailService emailService;
    private final PasswordHashService passwordHashService;
    private final JwtTokenService jwtTokenService;

    public AuthController(
            EmailService emailService,
            PasswordHashService passwordHashService,
            JwtTokenService jwtTokenService
    ) {
        this.emailService = emailService;
        this.passwordHashService = passwordHashService;
        this.jwtTokenService = jwtTokenService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) throws SQLException {

        String correo = InputValidator.validateEmail(request.correo());
        String contrasena = InputValidator.validatePassword(request.contrasena());
        String nickname = InputValidator.validateNickname(request.nickname());

        if (existeCorreo(correo)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiMessageResponse("El correo ya está registrado"));
        }

        String sqlInsertUsuario = "INSERT INTO usuarios (correo, contrasena, nickname, nivel) VALUES (?, ?, ?, ?)";
        String sqlInsertUsuarioTemporada = "INSERT INTO usuario_temporadas (id_usuario, id_temporada) VALUES (?, ?)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try (PreparedStatement psUsuario = conn.prepareStatement(sqlInsertUsuario, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement psUsuarioTemporada = conn.prepareStatement(sqlInsertUsuarioTemporada)) {

                psUsuario.setString(1, correo);
                psUsuario.setString(2, passwordHashService.hashForStorage(contrasena));
                psUsuario.setString(3, nickname);
                psUsuario.setInt(4, 1);

                int filas = psUsuario.executeUpdate();

                if (filas <= 0) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(new ApiMessageResponse("No se ha podido crear el usuario"));
                }

                Long id = null;
                try (ResultSet rs = psUsuario.getGeneratedKeys()) {
                    if (rs.next()) {
                        id = rs.getLong(1);
                    }
                }

                if (id == null) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(new ApiMessageResponse("No se ha podido obtener el id del usuario creado"));
                }

                for (long idTemporada : DEFAULT_TEMPORADA_IDS) {
                    psUsuarioTemporada.setLong(1, id);
                    psUsuarioTemporada.setLong(2, idTemporada);
                    int filasTemporada = psUsuarioTemporada.executeUpdate();
                    if (filasTemporada <= 0) {
                        conn.rollback();
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                .body(new ApiMessageResponse("No se ha podido asignar la temporada inicial al usuario"));
                    }
                }

                conn.commit();

                UserResponse user = new UserResponse(
                        id,
                        correo,
                        nickname,
                        1,
                        null
                );

                return ResponseEntity.status(HttpStatus.CREATED)
                        .body(new RegisterResponse("Usuario creado correctamente", user));

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) throws SQLException {

        String correo;
        try {
            correo = InputValidator.validateEmail(request.correo());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        if (request.contrasena() == null || request.contrasena().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Contraseña no válida"));
        }

        String sql = "SELECT id, correo, contrasena, nickname, nivel, foto FROM usuarios WHERE LOWER(correo) = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, correo);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new ApiMessageResponse("Correo o contraseña incorrectos"));
                }

                long userId = rs.getLong("id");
                String storedHash = rs.getString("contrasena");
                PasswordHashService.PasswordMatchResult match =
                        passwordHashService.verifyAndMaybeUpgrade(request.contrasena(), storedHash);
                if (!match.matches()) {
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new ApiMessageResponse("Correo o contraseña incorrectos"));
                }
                if (match.upgradedHashIfAny() != null) {
                    updateStoredPassword(conn, userId, match.upgradedHashIfAny());
                }

                UserResponse user = new UserResponse(
                        userId,
                        rs.getString("correo"),
                        rs.getString("nickname"),
                        rs.getInt("nivel"),
                        LeagueAssetUrls.userPhotoIfStored(userId, rs.getString("foto"))
                );

                AuthResponse response = new AuthResponse(
                        jwtTokenService.createAccessToken(userId, user.correo()),
                        jwtTokenService.createRefreshToken(userId, user.correo()),
                        "Bearer",
                        user
                );

                return ResponseEntity.ok(response);
            }
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody RefreshTokenRequest request) {
        if (request == null || request.refreshToken() == null || request.refreshToken().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Refresh token obligatorio"));
        }
        try {
            JwtTokenService.ParsedToken parsed =
                    jwtTokenService.parse(request.refreshToken(), JwtTokenService.TYPE_REFRESH);
            UserResponse user = loadUserByIdSimple(parsed.userId());
            if (user == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ApiMessageResponse("Sesión no válida"));
            }
            AuthResponse response = new AuthResponse(
                    jwtTokenService.createAccessToken(user.id(), user.correo()),
                    jwtTokenService.createRefreshToken(user.id(), user.correo()),
                    "Bearer",
                    user
            );
            return ResponseEntity.ok(response);
        } catch (JwtException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiMessageResponse("Sesión expirada. Vuelve a iniciar sesión."));
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiMessageResponse("No se pudo renovar la sesión"));
        }
    }

    @PostMapping("/email-verification/request")
    public ResponseEntity<?> requestEmailVerification(@RequestBody EmailRequest request) throws SQLException {

        if (request.correo() == null || request.correo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Correo no válido"));
        }

        if (existeCorreo(request.correo())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiMessageResponse("El correo ya está registrado"));
        }

        String sql = "INSERT INTO codigos_verificacion (correo, codigo) VALUES (?, ?) " +
                "ON DUPLICATE KEY UPDATE codigo = VALUES(codigo), fecha_generacion = CURRENT_TIMESTAMP";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            String codigo = generarCodigo();

            ps.setString(1, request.correo());
            ps.setString(2, codigo);
            ps.executeUpdate();

            emailService.enviarCodigoComprobacion(request.correo(), codigo);

            return ResponseEntity.ok(new ApiMessageResponse("Se ha enviado un código de verificación a tu correo"));
        }
    }

    @PostMapping("/email-verification/confirm")
    public ResponseEntity<?> confirmEmailVerification(@RequestBody CodeVerificationRequest request) throws SQLException {

        String sqlSelect = "SELECT codigo FROM codigos_verificacion WHERE correo = ?";
        String sqlDelete = "DELETE FROM codigos_verificacion WHERE correo = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect)) {

            psSelect.setString(1, request.correo());

            try (ResultSet rs = psSelect.executeQuery()) {

                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No hay ningún código registrado para este correo"));
                }

                String codigoBD = rs.getString("codigo");

                if (codigoBD == null || !codigoBD.equals(request.codigo())) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código incorrecto"));
                }
            }

            try (PreparedStatement psDelete = conn.prepareStatement(sqlDelete)) {
                psDelete.setString(1, request.correo());
                psDelete.executeUpdate();
            }

            return ResponseEntity.ok(new ApiMessageResponse("Código correcto"));
        }
    }

    @PostMapping("/password-reset/request")
    public ResponseEntity<?> requestPasswordReset(@RequestBody EmailRequest request) throws SQLException {

        String correo;
        try {
            correo = InputValidator.validateEmail(request.correo());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        String sqlSelect = "SELECT id FROM usuarios WHERE LOWER(correo) = ?";
        String sqlUpdate = "UPDATE usuarios SET codigo_reinicio = ? WHERE LOWER(correo) = ?";
        String sqlClear = "UPDATE usuarios SET codigo_reinicio = NULL WHERE LOWER(correo) = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {

            psSelect.setString(1, correo);

            try (ResultSet rs = psSelect.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No existe ningún usuario con ese correo"));
                }
            }

            String codigo = generarCodigo();

            psUpdate.setString(1, codigo);
            psUpdate.setString(2, correo);
            psUpdate.executeUpdate();

            try {
                emailService.enviarCodigoReinicio(correo, codigo);
            } catch (RuntimeException e) {
                try (PreparedStatement psClear = conn.prepareStatement(sqlClear)) {
                    psClear.setString(1, correo);
                    psClear.executeUpdate();
                }
                throw e;
            }

            return ResponseEntity.ok(new ApiMessageResponse("Se ha enviado un correo con el código de reinicio de contraseña"));
        }
    }

    @PostMapping("/password-reset/confirm")
    public ResponseEntity<?> confirmPasswordReset(@RequestBody PasswordResetConfirmRequest request) throws SQLException {

        String correo;
        try {
            correo = InputValidator.validateEmail(request.correo());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        if (request.codigo() == null || request.codigo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("El código es obligatorio"));
        }
        final String codigoIngresado = request.codigo().trim().toUpperCase();

        String sqlSelect = "SELECT codigo_reinicio FROM usuarios WHERE LOWER(correo) = ?";
        String sqlUpdate = "UPDATE usuarios SET contrasena = ?, codigo_reinicio = NULL WHERE LOWER(correo) = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {

            psSelect.setString(1, correo);

            try (ResultSet rs = psSelect.executeQuery()) {

                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No existe ningún usuario con ese correo"));
                }

                String codigoBD = rs.getString("codigo_reinicio");

                if (codigoBD == null || codigoBD.isBlank()) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("No hay ningún código registrado. Solicita uno nuevo."));
                }

                if (!codigoBD.trim().equalsIgnoreCase(codigoIngresado)) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código incorrecto"));
                }
            }

            String contrasenaEnc;
            try {
                contrasenaEnc = passwordHashService.hashForStorage(
                        InputValidator.validatePassword(request.nuevaContrasena())
                );
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
            }

            psUpdate.setString(1, contrasenaEnc);
            psUpdate.setString(2, correo);

            int filas = psUpdate.executeUpdate();

            if (filas <= 0) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(new ApiMessageResponse("No se ha podido actualizar la contraseña"));
            }

            return ResponseEntity.ok(new ApiMessageResponse("Contraseña cambiada correctamente"));
        }
    }

    @PostMapping("/email-change/request")
    public ResponseEntity<?> requestEmailChange(@RequestBody EmailChangeRequest request) throws SQLException {
        if (request.idUsuario() == null || request.idUsuario() <= 0) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());

        String nuevoCorreo;
        try {
            nuevoCorreo = InputValidator.validateEmail(request.nuevoCorreo());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        if (request.contrasenaActual() == null || request.contrasenaActual().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("La contraseña actual es obligatoria"));
        }

        ensureEmailChangeTable();

        try (Connection conn = DBConnection.getConnection()) {
            String sqlUser = "SELECT id, correo, contrasena, nickname, nivel, foto, codigo_reinicio FROM usuarios WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlUser)) {
                ps.setLong(1, request.idUsuario());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                .body(new ApiMessageResponse("Usuario no encontrado"));
                    }

                    String correoActual = rs.getString("correo");
                    if (correoActual != null && correoActual.equalsIgnoreCase(nuevoCorreo)) {
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(new ApiMessageResponse("El nuevo correo debe ser distinto del actual"));
                    }

                    if (!verifyCurrentPassword(conn, request.idUsuario(), request.contrasenaActual())) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                .body(new ApiMessageResponse("Contraseña actual incorrecta"));
                    }

                    if (rs.getString("codigo_reinicio") != null) {
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(new ApiMessageResponse(
                                        "Hay un reinicio de contraseña pendiente. Complétalo antes de cambiar el correo."));
                    }
                }
            }

            if (existeCorreo(nuevoCorreo)) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(new ApiMessageResponse("Ese correo ya está registrado en otra cuenta"));
            }

            String codigo = generarCodigo();
            String codigoCorreoActual = generarCodigo();
            String upsert = """
                    INSERT INTO usuario_cambio_correo_pendiente (id_usuario, nuevo_correo, codigo, codigo_correo_actual)
                    VALUES (?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE nuevo_correo = VALUES(nuevo_correo),
                                            codigo = VALUES(codigo),
                                            codigo_correo_actual = VALUES(codigo_correo_actual),
                                            creado_en = CURRENT_TIMESTAMP(3)
                    """;
            try (PreparedStatement ps = conn.prepareStatement(upsert)) {
                ps.setLong(1, request.idUsuario());
                ps.setString(2, nuevoCorreo);
                ps.setString(3, codigo);
                ps.setString(4, codigoCorreoActual);
                ps.executeUpdate();
            }

            emailService.enviarCodigoCambioCorreoNuevo(nuevoCorreo, codigo, nuevoCorreo);

            String correoAntiguo = loadCorreoById(conn, request.idUsuario());
            if (correoAntiguo != null && !correoAntiguo.isBlank()) {
                emailService.enviarCodigoCambioCorreoActual(correoAntiguo, codigoCorreoActual, nuevoCorreo);
            }

            return ResponseEntity.ok(new ApiMessageResponse(
                    "Te hemos enviado un código al nuevo correo y otro al correo actual"));
        }
    }

    @PostMapping("/email-change/confirm")
    public ResponseEntity<?> confirmEmailChange(@RequestBody EmailChangeConfirmRequest request) throws SQLException {
        if (request.idUsuario() == null || request.idUsuario() <= 0) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());

        String nuevoCorreo;
        try {
            nuevoCorreo = InputValidator.validateEmail(request.nuevoCorreo());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        if (request.codigo() == null || request.codigo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("El código del nuevo correo es obligatorio"));
        }
        if (request.codigoCorreoActual() == null || request.codigoCorreoActual().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("El código del correo actual es obligatorio"));
        }

        ensureEmailChangeTable();

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String selectPending = """
                        SELECT nuevo_correo, codigo, codigo_correo_actual, creado_en
                        FROM usuario_cambio_correo_pendiente
                        WHERE id_usuario = ?
                        FOR UPDATE
                        """;
                String codigoBd;
                String codigoCorreoActualBd;
                String correoPendiente;
                try (PreparedStatement ps = conn.prepareStatement(selectPending)) {
                    ps.setLong(1, request.idUsuario());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                    .body(new ApiMessageResponse("No hay ningún cambio de correo pendiente"));
                        }
                        correoPendiente = rs.getString("nuevo_correo");
                        codigoBd = rs.getString("codigo");
                        codigoCorreoActualBd = rs.getString("codigo_correo_actual");
                        if (rs.getTimestamp("creado_en") != null
                                && rs.getTimestamp("creado_en").toInstant().isBefore(
                                        java.time.Instant.now().minus(java.time.Duration.ofMinutes(15)))) {
                            conn.rollback();
                            return ResponseEntity.status(HttpStatus.GONE)
                                    .body(new ApiMessageResponse("El código ha caducado. Solicita uno nuevo."));
                        }
                    }
                }

                if (!nuevoCorreo.equalsIgnoreCase(correoPendiente)) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("El correo no coincide con la solicitud pendiente"));
                }

                if (codigoBd == null || !codigoBd.equalsIgnoreCase(request.codigo().trim())) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código del nuevo correo incorrecto"));
                }

                if (codigoCorreoActualBd == null
                        || !codigoCorreoActualBd.equalsIgnoreCase(request.codigoCorreoActual().trim())) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código del correo actual incorrecto"));
                }

                if (existeCorreo(conn, nuevoCorreo, request.idUsuario())) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.CONFLICT)
                            .body(new ApiMessageResponse("Ese correo ya está registrado en otra cuenta"));
                }

                String updateUser = "UPDATE usuarios SET correo = ? WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateUser)) {
                    ps.setString(1, nuevoCorreo);
                    ps.setLong(2, request.idUsuario());
                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                .body(new ApiMessageResponse("No se pudo actualizar el correo"));
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM usuario_cambio_correo_pendiente WHERE id_usuario = ?")) {
                    ps.setLong(1, request.idUsuario());
                    ps.executeUpdate();
                }

                UserResponse user = loadUserById(conn, request.idUsuario());
                conn.commit();

                emailService.enviarCorreoActualizado(nuevoCorreo, nuevoCorreo);

                return ResponseEntity.ok(new EmailChangeConfirmResponse(
                        "Correo actualizado correctamente",
                        user
                ));
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    @PostMapping("/nickname-change/request")
    public ResponseEntity<?> requestNicknameChange(@RequestBody NicknameChangeRequest request) throws SQLException {
        if (request.idUsuario() == null || request.idUsuario() <= 0) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());
        if (request.contrasenaActual() == null || request.contrasenaActual().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("La contraseña actual es obligatoria"));
        }

        String nuevoNickname;
        try {
            nuevoNickname = InputValidator.validateNickname(request.nuevoNickname());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        ensureNicknameChangeTable();

        try (Connection conn = DBConnection.getConnection()) {
            String sqlUser = """
                    SELECT id, correo, contrasena, nickname, codigo_reinicio
                    FROM usuarios WHERE id = ?
                    """;
            try (PreparedStatement ps = conn.prepareStatement(sqlUser)) {
                ps.setLong(1, request.idUsuario());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                .body(new ApiMessageResponse("Usuario no encontrado"));
                    }

                    String nicknameActual = rs.getString("nickname");
                    if (nicknameActual != null && nicknameActual.equals(nuevoNickname)) {
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(new ApiMessageResponse("El nuevo nickname debe ser distinto del actual"));
                    }

                    if (!verifyCurrentPassword(conn, request.idUsuario(), request.contrasenaActual())) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                .body(new ApiMessageResponse("Contraseña actual incorrecta"));
                    }

                    if (rs.getString("codigo_reinicio") != null) {
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(new ApiMessageResponse(
                                        "Hay un reinicio de contraseña pendiente. Complétalo antes de cambiar el nickname."));
                    }

                    String correo = rs.getString("correo");
                    if (correo == null || correo.isBlank()) {
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .body(new ApiMessageResponse("No hay un correo asociado para verificar el cambio"));
                    }
                }
            }

            if (existeNickname(conn, nuevoNickname, request.idUsuario())) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(new ApiMessageResponse("Ese nickname ya está en uso"));
            }

            String codigo = generarCodigo();
            String upsert = """
                    INSERT INTO usuario_cambio_nickname_pendiente (id_usuario, nuevo_nickname, codigo)
                    VALUES (?, ?, ?)
                    ON DUPLICATE KEY UPDATE nuevo_nickname = VALUES(nuevo_nickname),
                                            codigo = VALUES(codigo),
                                            creado_en = CURRENT_TIMESTAMP(3)
                    """;
            try (PreparedStatement ps = conn.prepareStatement(upsert)) {
                ps.setLong(1, request.idUsuario());
                ps.setString(2, nuevoNickname);
                ps.setString(3, codigo);
                ps.executeUpdate();
            }

            String correoUsuario = loadCorreoById(conn, request.idUsuario());
            emailService.enviarCodigoCambioNickname(correoUsuario, codigo, nuevoNickname);

            return ResponseEntity.ok(new ApiMessageResponse(
                    "Te hemos enviado un código de verificación a tu correo"));
        }
    }

    @PostMapping("/nickname-change/confirm")
    public ResponseEntity<?> confirmNicknameChange(@RequestBody NicknameChangeConfirmRequest request)
            throws SQLException {
        if (request.idUsuario() == null || request.idUsuario() <= 0) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Usuario no válido"));
        }
        AuthenticatedUser.assertSameUser(request.idUsuario());

        String nuevoNickname;
        try {
            nuevoNickname = InputValidator.validateNickname(request.nuevoNickname());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        }

        if (request.codigo() == null || request.codigo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("El código es obligatorio"));
        }

        ensureNicknameChangeTable();

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String selectPending = """
                        SELECT nuevo_nickname, codigo, creado_en
                        FROM usuario_cambio_nickname_pendiente
                        WHERE id_usuario = ?
                        FOR UPDATE
                        """;
                String codigoBd;
                String nicknamePendiente;
                try (PreparedStatement ps = conn.prepareStatement(selectPending)) {
                    ps.setLong(1, request.idUsuario());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                    .body(new ApiMessageResponse("No hay ningún cambio de nickname pendiente"));
                        }
                        nicknamePendiente = rs.getString("nuevo_nickname");
                        codigoBd = rs.getString("codigo");
                        if (rs.getTimestamp("creado_en") != null
                                && rs.getTimestamp("creado_en").toInstant().isBefore(
                                        java.time.Instant.now().minus(java.time.Duration.ofMinutes(15)))) {
                            conn.rollback();
                            return ResponseEntity.status(HttpStatus.GONE)
                                    .body(new ApiMessageResponse("El código ha caducado. Solicita uno nuevo."));
                        }
                    }
                }

                if (!nuevoNickname.equals(nicknamePendiente)) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("El nickname no coincide con la solicitud pendiente"));
                }

                if (codigoBd == null || !codigoBd.equalsIgnoreCase(request.codigo().trim())) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código incorrecto"));
                }

                if (existeNickname(conn, nuevoNickname, request.idUsuario())) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.CONFLICT)
                            .body(new ApiMessageResponse("Ese nickname ya está en uso"));
                }

                String updateUser = "UPDATE usuarios SET nickname = ? WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateUser)) {
                    ps.setString(1, nuevoNickname);
                    ps.setLong(2, request.idUsuario());
                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                .body(new ApiMessageResponse("No se pudo actualizar el nickname"));
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM usuario_cambio_nickname_pendiente WHERE id_usuario = ?")) {
                    ps.setLong(1, request.idUsuario());
                    ps.executeUpdate();
                }

                UserResponse user = loadUserById(conn, request.idUsuario());
                conn.commit();

                return ResponseEntity.ok(new EmailChangeConfirmResponse(
                        "Nickname actualizado correctamente",
                        user
                ));
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void ensureEmailChangeTable() throws SQLException {
        String sql = """
                CREATE TABLE IF NOT EXISTS usuario_cambio_correo_pendiente (
                    id_usuario BIGINT NOT NULL,
                    nuevo_correo VARCHAR(190) NOT NULL,
                    codigo VARCHAR(6) NOT NULL,
                    codigo_correo_actual VARCHAR(6) NULL,
                    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                    PRIMARY KEY (id_usuario),
                    CONSTRAINT fk_uccp_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
                )
                """;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "ALTER TABLE usuario_cambio_correo_pendiente ADD COLUMN codigo_correo_actual VARCHAR(6) NULL AFTER codigo")) {
            ps.executeUpdate();
        } catch (SQLException ignored) {
            // Columna ya existente.
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "CREATE INDEX IF NOT EXISTS idx_uccp_nuevo_correo ON usuario_cambio_correo_pendiente (nuevo_correo)")) {
            ps.executeUpdate();
        } catch (SQLException ignored) {
            // MySQL antiguo puede no soportar IF NOT EXISTS en índices; la tabla basta.
        }
    }

    private void ensureNicknameChangeTable() throws SQLException {
        String sql = """
                CREATE TABLE IF NOT EXISTS usuario_cambio_nickname_pendiente (
                    id_usuario BIGINT NOT NULL,
                    nuevo_nickname VARCHAR(24) NOT NULL,
                    codigo VARCHAR(6) NOT NULL,
                    creado_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                    PRIMARY KEY (id_usuario),
                    CONSTRAINT fk_ucnp_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE CASCADE
                )
                """;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "CREATE INDEX IF NOT EXISTS idx_ucnp_nickname ON usuario_cambio_nickname_pendiente (nuevo_nickname)")) {
            ps.executeUpdate();
        } catch (SQLException ignored) {
            // MySQL antiguo puede no soportar IF NOT EXISTS en índices.
        }
    }

    private void updateStoredPassword(Connection conn, long userId, String passwordHash) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("UPDATE usuarios SET contrasena = ? WHERE id = ?")) {
            ps.setString(1, passwordHash);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    private boolean verifyCurrentPassword(Connection conn, long userId, String plainPassword) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT contrasena FROM usuarios WHERE id = ?")) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                PasswordHashService.PasswordMatchResult match =
                        passwordHashService.verifyAndMaybeUpgrade(plainPassword, rs.getString("contrasena"));
                if (!match.matches()) {
                    return false;
                }
                if (match.upgradedHashIfAny() != null) {
                    updateStoredPassword(conn, userId, match.upgradedHashIfAny());
                }
                return true;
            }
        }
    }

    private UserResponse loadUserByIdSimple(long idUsuario) throws SQLException {
        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id, correo, nickname, nivel, foto FROM usuarios WHERE id = ?")) {
                ps.setLong(1, idUsuario);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return null;
                    }
                    return new UserResponse(
                            rs.getLong("id"),
                            rs.getString("correo"),
                            rs.getString("nickname"),
                            rs.getInt("nivel"),
                            LeagueAssetUrls.userPhotoIfStored(rs.getLong("id"), rs.getString("foto"))
                    );
                }
            }
        }
    }

    private String loadCorreoById(Connection conn, long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT correo FROM usuarios WHERE id = ?")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("correo") : null;
            }
        }
    }

    private UserResponse loadUserById(Connection conn, long idUsuario) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id, correo, nickname, nivel, foto FROM usuarios WHERE id = ?")) {
            ps.setLong(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return new UserResponse(
                        rs.getLong("id"),
                        rs.getString("correo"),
                        rs.getString("nickname"),
                        rs.getInt("nivel"),
                        LeagueAssetUrls.userPhotoIfStored(rs.getLong("id"), rs.getString("foto"))
                );
            }
        }
    }

    private boolean existeCorreo(Connection conn, String correo, long excludeUserId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM usuarios WHERE LOWER(correo) = LOWER(?) AND id <> ?")) {
            ps.setString(1, correo);
            ps.setLong(2, excludeUserId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private boolean existeNickname(Connection conn, String nickname, long excludeUserId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM usuarios WHERE nickname = ? AND id <> ?")) {
            ps.setString(1, nickname);
            ps.setLong(2, excludeUserId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private boolean existeCorreo(String correo) {
        String sql = "SELECT COUNT(*) FROM usuarios WHERE correo = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, correo);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    private String generarCodigo() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(6);

        for (int i = 0; i < 6; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }

        return sb.toString();
    }
}
