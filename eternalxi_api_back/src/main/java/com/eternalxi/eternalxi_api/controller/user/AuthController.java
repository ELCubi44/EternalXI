package com.eternalxi.eternalxi_api.controller.user;

import com.eternalxi.eternalxi_api.config.DBConnection;
import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.dto.auth.AuthResponse;
import com.eternalxi.eternalxi_api.dto.auth.CodeVerificationRequest;
import com.eternalxi.eternalxi_api.dto.auth.EmailRequest;
import com.eternalxi.eternalxi_api.dto.auth.LoginRequest;
import com.eternalxi.eternalxi_api.dto.auth.PasswordResetConfirmRequest;
import com.eternalxi.eternalxi_api.dto.auth.RegisterRequest;
import com.eternalxi.eternalxi_api.dto.auth.RegisterResponse;
import com.eternalxi.eternalxi_api.dto.user.UserResponse;
import com.eternalxi.eternalxi_api.model.Usuario;
import com.eternalxi.eternalxi_api.services.EmailService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.eternalxi.eternalxi_api.validation.InputValidator;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private static final long DEFAULT_TEMPORADA_ID = 1L;

    private final EmailService emailService;

    public AuthController(EmailService emailService) {
        this.emailService = emailService;
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
                psUsuario.setString(2, Usuario.encriptarContrasena(contrasena));
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

                psUsuarioTemporada.setLong(1, id);
                psUsuarioTemporada.setLong(2, DEFAULT_TEMPORADA_ID);

                int filasTemporada = psUsuarioTemporada.executeUpdate();

                if (filasTemporada <= 0) {
                    conn.rollback();
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(new ApiMessageResponse("No se ha podido asignar la temporada inicial al usuario"));
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

        if (request.correo() == null || request.correo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Correo no válido"));
        }

        if (request.contrasena() == null || request.contrasena().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Contraseña no válida"));
        }

        String sql = "SELECT id, correo, contrasena, nickname, nivel, foto FROM usuarios WHERE correo = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, request.correo());

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new ApiMessageResponse("Correo o contraseña incorrectos"));
                }

                String contrasenaEnc = Usuario.encriptarContrasena(request.contrasena());

                if (!contrasenaEnc.equals(rs.getString("contrasena"))) {
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new ApiMessageResponse("Correo o contraseña incorrectos"));
                }

                UserResponse user = new UserResponse(
                        rs.getLong("id"),
                        rs.getString("correo"),
                        rs.getString("nickname"),
                        rs.getInt("nivel"),
                        rs.getString("foto")
                );

                AuthResponse response = new AuthResponse(
                        "token-temporal",
                        "refresh-temporal",
                        "Bearer",
                        user
                );

                return ResponseEntity.ok(response);
            }
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

        String sqlSelect = "SELECT id FROM usuarios WHERE correo = ?";
        String sqlUpdate = "UPDATE usuarios SET codigo_reinicio = ? WHERE correo = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {

            psSelect.setString(1, request.correo());

            try (ResultSet rs = psSelect.executeQuery()) {
                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No existe ningún usuario con ese correo"));
                }
            }

            String codigo = generarCodigo();

            psUpdate.setString(1, codigo);
            psUpdate.setString(2, request.correo());
            psUpdate.executeUpdate();

            emailService.enviarCodigoReinicio(request.correo(), codigo);

            return ResponseEntity.ok(new ApiMessageResponse("Se ha enviado un correo con el código de reinicio de contraseña"));
        }
    }

    @PostMapping("/password-reset/confirm")
    public ResponseEntity<?> confirmPasswordReset(@RequestBody PasswordResetConfirmRequest request) throws SQLException {

        String sqlSelect = "SELECT codigo_reinicio FROM usuarios WHERE correo = ?";
        String sqlUpdate = "UPDATE usuarios SET contrasena = ?, codigo_reinicio = NULL WHERE correo = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psSelect = conn.prepareStatement(sqlSelect);
             PreparedStatement psUpdate = conn.prepareStatement(sqlUpdate)) {

            psSelect.setString(1, request.correo());

            try (ResultSet rs = psSelect.executeQuery()) {

                if (!rs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ApiMessageResponse("No existe ningún usuario con ese correo"));
                }

                String codigoBD = rs.getString("codigo_reinicio");

                if (codigoBD == null) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("No hay ningún código registrado para este usuario"));
                }

                if (!codigoBD.equals(request.codigo())) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new ApiMessageResponse("Código incorrecto"));
                }
            }

            String contrasenaEnc = Usuario.encriptarContrasena(request.nuevaContrasena());

            psUpdate.setString(1, contrasenaEnc);
            psUpdate.setString(2, request.correo());

            int filas = psUpdate.executeUpdate();

            if (filas <= 0) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(new ApiMessageResponse("No se ha podido actualizar la contraseña"));
            }

            return ResponseEntity.ok(new ApiMessageResponse("Contraseña cambiada correctamente"));
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
