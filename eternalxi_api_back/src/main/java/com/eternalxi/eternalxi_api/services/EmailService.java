package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.exception.EmailDeliveryException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;
    private final String from;
    private final boolean mailEnabled;

    public EmailService(
            @Autowired(required = false) JavaMailSender mailSender,
            @Value("${spring.mail.username:eternalxi@noreply.local}") String from
    ) {
        this.mailSender = mailSender;
        this.from = from;
        this.mailEnabled = mailSender != null;
        if (!mailEnabled) {
            log.warn("Correo SMTP no configurado (spring.mail.host). Códigos por email desactivados.");
        }
    }

    public void enviarCodigoReinicio(String destino, String codigo) {
        enviarHtml(
                destino,
                "Restablecer contraseña — Eternal XI",
                EmailHtmlTemplates.passwordResetCode(codigo),
                "Tu código de reinicio es: " + codigo
        );
    }

    public void enviarCodigoComprobacion(String destino, String codigo) {
        enviarHtml(
                destino,
                "Verifica tu correo — Eternal XI",
                EmailHtmlTemplates.verificationCode(codigo),
                "Tu código de verificación es: " + codigo
        );
    }

    public void enviarCodigoCambioCorreoNuevo(String destino, String codigo, String nuevoCorreo) {
        enviarHtml(
                destino,
                "Confirma tu nuevo correo — Eternal XI",
                EmailHtmlTemplates.emailChangeNewAddress(codigo, nuevoCorreo),
                "Tu código para confirmar el nuevo correo es: " + codigo
        );
    }

    public void enviarCodigoCambioCorreoActual(String destino, String codigo, String nuevoCorreo) {
        enviarHtml(
                destino,
                "Confirma desde tu correo actual — Eternal XI",
                EmailHtmlTemplates.emailChangeCurrentAddress(codigo, nuevoCorreo),
                "Tu código para confirmar el cambio desde el correo actual es: " + codigo
        );
    }

    public void enviarAvisoCambioCorreoAntiguo(String destino, String nuevoCorreo) {
        enviarHtml(
                destino,
                "Aviso de cambio de correo — Eternal XI",
                EmailHtmlTemplates.emailChangeOldAddressAlert(nuevoCorreo),
                "Se ha solicitado cambiar tu correo a: " + nuevoCorreo
        );
    }

    public void enviarCorreoActualizado(String destino, String nuevoCorreo) {
        enviarHtml(
                destino,
                "Correo actualizado — Eternal XI",
                EmailHtmlTemplates.emailChangedConfirmation(nuevoCorreo),
                "Tu correo de Eternal XI se ha actualizado a: " + nuevoCorreo
        );
    }

    public void enviarConfirmacionEliminacionCuenta(String destino, String codigo, String confirmUrl) {
        enviarHtml(
                destino,
                "Confirmar eliminación de cuenta — Eternal XI",
                EmailHtmlTemplates.accountDeletionConfirmation(codigo, confirmUrl),
                "Tu código para confirmar la eliminación de cuenta es: " + codigo
                        + ". Enlace: " + confirmUrl
        );
    }

    public void enviarCodigoCambioNickname(String destino, String codigo, String nuevoNickname) {
        enviarHtml(
                destino,
                "Confirma tu nuevo nickname — Eternal XI",
                EmailHtmlTemplates.nicknameChangeCode(codigo, nuevoNickname),
                "Tu código para confirmar el nuevo nickname es: " + codigo
        );
    }

    private void enviarHtml(String destino, String subject, String html, String textFallback) {
        if (!mailEnabled) {
            log.error("SMTP no configurado: no se envió correo a {} ({})", destino, subject);
            throw EmailDeliveryException.smtpNotConfigured();
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(from);
            helper.setTo(destino);
            helper.setSubject(subject);
            helper.setText(textFallback, html);
            mailSender.send(message);
        } catch (MailException e) {
            log.error("Fallo al enviar correo a {}: {}", destino, e.getMessage());
            String detail = e.getMessage() == null ? "" : e.getMessage().toLowerCase();
            if (detail.contains("authentication") || detail.contains("535")) {
                throw new EmailDeliveryException(
                        "No se pudo autenticar en el servidor de correo. Revisa en Nominalia el buzón no-reply@eternal.es y su contraseña."
                );
            }
            throw EmailDeliveryException.sendFailed(destino);
        } catch (MessagingException e) {
            log.error("Fallo al preparar correo a {}: {}", destino, e.getMessage());
            throw EmailDeliveryException.sendFailed(destino);
        }
    }
}
