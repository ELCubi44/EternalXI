package com.eternalxi.eternalxi_api.services;

final class EmailHtmlTemplates {

    private EmailHtmlTemplates() {}

    static String verificationCode(String code) {
        return layout(
                "Verifica tu correo",
                "Tu código de verificación para Eternal XI",
                """
                <p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#E8EAED;">
                  Estás verificando que esta dirección te pertenece antes de crear tu cuenta en <strong>Eternal XI</strong>.
                </p>
                %s
                <p style="margin:16px 0 0;font-size:14px;line-height:1.5;color:#9AA0A6;">
                  Si no has solicitado este código, puedes ignorar este mensaje con tranquilidad.
                </p>
                """.formatted(codeBlock(code))
        );
    }

    static String passwordResetCode(String code) {
        return layout(
                "Restablecer contraseña",
                "Código para restablecer tu contraseña en Eternal XI",
                """
                <p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#E8EAED;">
                  Hemos recibido una solicitud para restablecer la contraseña de tu cuenta en <strong>Eternal XI</strong>.
                </p>
                %s
                <p style="margin:16px 0 0;font-size:14px;line-height:1.5;color:#9AA0A6;">
                  El código caduca en breve. Si no fuiste tú, ignora este correo: tu contraseña no cambiará.
                </p>
                """.formatted(codeBlock(code))
        );
    }

    static String emailChangeNewAddress(String code, String nuevoCorreo) {
        return layout(
                "Confirma tu nuevo correo",
                "Verifica el cambio de correo en Eternal XI",
                """
                <p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#E8EAED;">
                  Quieres usar <strong>%s</strong> como nuevo correo de acceso en <strong>Eternal XI</strong>.
                  Introduce este código en la app para confirmar el cambio.
                </p>
                %s
                <p style="margin:16px 0 0;font-size:14px;line-height:1.5;color:#9AA0A6;">
                  El código caduca en 15 minutos. Si no solicitaste este cambio, ignora el mensaje.
                </p>
                """.formatted(escapeHtml(nuevoCorreo), codeBlock(code))
        );
    }

    static String emailChangeOldAddressAlert(String nuevoCorreo) {
        return layout(
                "Aviso de cambio de correo",
                "Se ha solicitado cambiar el correo de tu cuenta Eternal XI",
                """
                <p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#E8EAED;">
                  Alguien con acceso a tu cuenta ha solicitado cambiar el correo de acceso a:
                </p>
                <p style="margin:0 0 16px;font-size:18px;font-weight:700;color:#FFE082;">%s</p>
                <p style="margin:0;font-size:14px;line-height:1.5;color:#9AA0A6;">
                  Si no reconoces esta acción, inicia sesión y cambia tu contraseña cuanto antes.
                </p>
                """.formatted(escapeHtml(nuevoCorreo))
        );
    }

    static String emailChangedConfirmation(String nuevoCorreo) {
        return layout(
                "Correo actualizado",
                "Tu correo de Eternal XI se ha actualizado correctamente",
                """
                <p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#E8EAED;">
                  Tu cuenta de <strong>Eternal XI</strong> ya utiliza este correo para iniciar sesión:
                </p>
                <p style="margin:0;font-size:18px;font-weight:700;color:#81C784;">%s</p>
                """.formatted(escapeHtml(nuevoCorreo))
        );
    }

    private static String codeBlock(String code) {
        return """
                <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="margin:8px 0 0;">
                  <tr>
                    <td align="center" style="background:#1A2233;border:1px solid #394867;border-radius:14px;padding:20px;">
                      <span style="font-family:Consolas,Monaco,monospace;font-size:32px;font-weight:800;letter-spacing:6px;color:#FFD54F;">%s</span>
                    </td>
                  </tr>
                </table>
                """.formatted(escapeHtml(code));
    }

    private static String layout(String title, String preheader, String bodyHtml) {
        return """
                <!DOCTYPE html>
                <html lang="es">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>%s</title>
                </head>
                <body style="margin:0;padding:0;background:#0B0E16;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
                  <span style="display:none!important;visibility:hidden;opacity:0;height:0;width:0;">%s</span>
                  <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background:#0B0E16;padding:32px 12px;">
                    <tr>
                      <td align="center">
                        <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#12182A;border:1px solid #2A3348;border-radius:20px;overflow:hidden;">
                          <tr>
                            <td style="background:linear-gradient(135deg,#1A237E,#4527A0);padding:24px 28px;">
                              <div style="font-size:13px;font-weight:700;letter-spacing:1px;color:#C5CAE9;text-transform:uppercase;">Eternal XI</div>
                              <div style="margin-top:8px;font-size:24px;font-weight:800;color:#FFFFFF;">%s</div>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding:28px;">%s</td>
                          </tr>
                          <tr>
                            <td style="padding:0 28px 24px;font-size:12px;line-height:1.5;color:#6B7280;">
                              Este mensaje es automático. No respondas a este correo.
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </body>
                </html>
                """.formatted(escapeHtml(title), escapeHtml(preheader), escapeHtml(title), bodyHtml);
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
