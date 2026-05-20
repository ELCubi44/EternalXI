package com.eternalxi.eternalxi_api.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
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
        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setFrom(from);
        mensaje.setTo(destino);
        mensaje.setSubject("Código de reinicio de contraseña");
        mensaje.setText("Tu código de reinicio es: " + codigo);

        mailSender.send(mensaje);
    }

    public void enviarCodigoComprobacion(String destino, String codigo) {
        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setFrom(from);
        mensaje.setTo(destino);
        mensaje.setSubject("Código de verificación de cuenta");
        mensaje.setText(
                "Estás intentando verificar que esta cuenta te pertenece.\n\n" +
                "Tu código de verificación es: " + codigo + "\n\n" +
                "Si no has solicitado este código, ignora este mensaje."
        );

        mailSender.send(mensaje);
    }
}