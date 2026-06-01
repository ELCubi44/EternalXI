package com.eternalxi.eternalxi_api.config;

import com.eternalxi.eternalxi_api.dto.error.ApiErrorResponse;
import com.eternalxi.eternalxi_api.exception.BusinessException;
import com.eternalxi.eternalxi_api.exception.EmailDeliveryException;
import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.sql.SQLException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiErrorResponse> handleAuth(AuthenticationException ex, HttpServletRequest req) {
        ApiErrorResponse body = new ApiErrorResponse(
                "UNAUTHORIZED",
                "Debes iniciar sesión para continuar.",
                401,
                req.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiErrorResponse> handleForbidden(AccessDeniedException ex, HttpServletRequest req) {
        ApiErrorResponse body = new ApiErrorResponse(
                "FORBIDDEN",
                "No tienes permiso para esta acción.",
                403,
                req.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
    }

    @ExceptionHandler(EmailDeliveryException.class)
    public ResponseEntity<ApiErrorResponse> handleEmailDelivery(EmailDeliveryException ex, HttpServletRequest req) {
        log.warn("Correo no enviado en {}: {}", req.getRequestURI(), ex.getMessage());
        ApiErrorResponse body = new ApiErrorResponse(
                ex.getErrorCode(),
                ex.getMessage(),
                ex.getHttpStatus(),
                req.getRequestURI()
        );
        return ResponseEntity.status(ex.getHttpStatus()).body(body);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiErrorResponse> handleBusiness(BusinessException ex, HttpServletRequest req) {
        ApiErrorResponse body = new ApiErrorResponse(
                ex.getErrorCode(),
                ex.getMessage(),
                ex.getHttpStatus(),
                req.getRequestURI()
        );
        return ResponseEntity.status(ex.getHttpStatus()).body(body);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiErrorResponse> handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest req) {
        ApiErrorResponse body = new ApiErrorResponse(
                "VALIDATION_ERROR",
                ex.getMessage(),
                400,
                req.getRequestURI()
        );
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiErrorResponse> handleUnreadable(HttpMessageNotReadableException ex, HttpServletRequest req) {
        String message = "El cuerpo de la petición no es válido.";
        String code = "VALIDATION_ERROR";

        Throwable cause = ex.getCause();
        if (cause instanceof InvalidFormatException ife) {
            Class<?> target = ife.getTargetType();
            if (target != null && isIntegerType(target)) {
                message = "El importe debe ser un número entero.";
                code = "AMOUNT_MUST_BE_INTEGER";
            }
        } else if (cause instanceof com.fasterxml.jackson.databind.exc.MismatchedInputException mie) {
            Class<?> target = mie.getTargetType();
            if (target != null && isIntegerType(target)) {
                message = "El importe debe ser un número entero.";
                code = "AMOUNT_MUST_BE_INTEGER";
            }
        }

        ApiErrorResponse body = new ApiErrorResponse(code, message, 400, req.getRequestURI());
        return ResponseEntity.badRequest().body(body);
    }

    private static boolean isIntegerType(Class<?> type) {
        return type == Long.class || type == long.class
                || type == Integer.class || type == int.class;
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest req) {
        String msg = "Parámetro '" + ex.getName() + "' no tiene un formato válido.";
        ApiErrorResponse body = new ApiErrorResponse("VALIDATION_ERROR", msg, 400, req.getRequestURI());
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiErrorResponse> handleMissingParam(MissingServletRequestParameterException ex, HttpServletRequest req) {
        String msg = "Falta el parámetro obligatorio: " + ex.getParameterName();
        ApiErrorResponse body = new ApiErrorResponse("VALIDATION_ERROR", msg, 400, req.getRequestURI());
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(SQLException.class)
    public ResponseEntity<ApiErrorResponse> handleSql(SQLException ex, HttpServletRequest req) {
        log.error("SQLException en {}: {}", req.getRequestURI(), ex.getMessage(), ex);
        ApiErrorResponse body = new ApiErrorResponse(
                "INTERNAL_ERROR",
                "Ha ocurrido un error interno. Inténtalo de nuevo.",
                500,
                req.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGeneric(Exception ex, HttpServletRequest req) {
        log.error("Excepción no controlada en {}: {}", req.getRequestURI(), ex.getMessage(), ex);
        ApiErrorResponse body = new ApiErrorResponse(
                "INTERNAL_ERROR",
                "Ha ocurrido un error interno. Inténtalo de nuevo.",
                500,
                req.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
