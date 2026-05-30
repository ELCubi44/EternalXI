package com.eternalxi.eternalxi_api.services;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String from;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
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

    private void enviarHtml(String destino, String subject, String html, String textFallback) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(from);
            helper.setTo(destino);
            helper.setSubject(subject);
            helper.setText(textFallback, html);
            mailSender.send(message);
        } catch (MessagingException e) {
            throw new IllegalStateException("No se pudo enviar el correo a " + destino, e);
        }
    }
}
