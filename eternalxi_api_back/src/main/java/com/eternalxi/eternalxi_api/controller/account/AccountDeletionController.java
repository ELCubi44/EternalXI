package com.eternalxi.eternalxi_api.controller.account;

import com.eternalxi.eternalxi_api.dto.account.AccountDeletionConfirmRequest;
import com.eternalxi.eternalxi_api.dto.auth.ApiMessageResponse;
import com.eternalxi.eternalxi_api.exception.EmailDeliveryException;
import com.eternalxi.eternalxi_api.security.AuthenticatedUser;
import com.eternalxi.eternalxi_api.services.AccountDeletionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/api/v1/account/deletion")
public class AccountDeletionController {

    private final AccountDeletionService accountDeletionService;

    public AccountDeletionController(AccountDeletionService accountDeletionService) {
        this.accountDeletionService = accountDeletionService;
    }

    @PostMapping("/request")
    public ResponseEntity<?> requestDeletion() {
        Long userId = AuthenticatedUser.requireUserId();
        try {
            accountDeletionService.requestDeletion(userId);
            return ResponseEntity.ok(new ApiMessageResponse(
                    "Te hemos enviado un correo con un código y un enlace para confirmar la eliminación de tu cuenta."
            ));
        } catch (EmailDeliveryException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(new ApiMessageResponse(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiMessageResponse("No se pudo procesar la solicitud. Inténtalo más tarde."));
        }
    }

    @PostMapping("/confirm")
    public ResponseEntity<?> confirmDeletion(@RequestBody AccountDeletionConfirmRequest request) {
        Long userId = AuthenticatedUser.requireUserId();
        if (request == null || request.codigo() == null || request.codigo().isBlank()) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse("Código obligatorio"));
        }
        try {
            accountDeletionService.confirmDeletionByCode(userId, request.codigo());
            return ResponseEntity.ok(new ApiMessageResponse("Cuenta eliminada correctamente"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ApiMessageResponse(e.getMessage()));
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiMessageResponse("No se pudo eliminar la cuenta. Inténtalo más tarde."));
        }
    }

    @GetMapping(value = "/confirm", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> confirmDeletionByLink(@RequestParam(name = "token", required = false) String token) {
        try {
            String html = accountDeletionService.confirmDeletionByToken(token);
            return ResponseEntity.ok(html);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .contentType(MediaType.TEXT_HTML)
                    .body(accountDeletionService.invalidConfirmationLinkHtml());
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.TEXT_HTML)
                    .body("""
                            <!DOCTYPE html><html lang="es"><body style="font-family:sans-serif;padding:2rem;">
                            <h1>Error</h1><p>No se pudo eliminar la cuenta. Inténtalo desde la app Eternal XI.</p>
                            </body></html>
                            """);
        }
    }
}
