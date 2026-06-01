package com.eternalxi.eternalxi_api.exception;

/**
 * El servidor no pudo enviar un correo (SMTP no configurado o fallo de envío).
 */
public class EmailDeliveryException extends BusinessException {

    public EmailDeliveryException(String message) {
        super("EMAIL_UNAVAILABLE", message, 503);
    }

    public static EmailDeliveryException smtpNotConfigured() {
        return new EmailDeliveryException(
                "No se puede enviar el correo en este momento. El administrador debe configurar el servidor SMTP."
        );
    }

    public static EmailDeliveryException sendFailed(String destino) {
        return new EmailDeliveryException(
                "No se pudo enviar el correo a " + destino + ". Inténtalo de nuevo más tarde."
        );
    }
}
