package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class FriendshipNotificationService {

    private static final Logger log = LoggerFactory.getLogger(FriendshipNotificationService.class);

    private final UserNotificationService userNotificationService;

    public FriendshipNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    public void notifyFriendRequest(
            Long idDestinatario,
            Long idSolicitante,
            String solicitanteNick,
            Long idAmistad
    ) {
        if (idDestinatario == null || idSolicitante == null || idAmistad == null) {
            return;
        }
        String nick = solicitanteNick == null || solicitanteNick.isBlank()
                ? "Un jugador"
                : solicitanteNick.trim();
        String title = "Nueva solicitud de amistad";
        String body = nick + " quiere ser tu amigo";
        try {
            Map<String, Object> datos = new HashMap<>();
            datos.put("idAmistad", idAmistad);
            datos.put("idUsuarioActor", idSolicitante);
            datos.put("actorName", nick);
            datos.put("actionRoute", "friends");

            String key = userNotificationService.idempotencyKey(
                    "FRIEND_REQUEST",
                    String.valueOf(idAmistad),
                    String.valueOf(idDestinatario)
            );

            Map<String, String> pushData = new HashMap<>();
            pushData.put("type", "FRIEND_REQUEST");
            pushData.put("idAmistad", String.valueOf(idAmistad));
            pushData.put("actionRoute", "friends");

            userNotificationService.notifyUser(
                    idDestinatario,
                    null,
                    "FRIEND_REQUEST",
                    title,
                    body,
                    datos,
                    key,
                    pushData
            );
        } catch (Exception e) {
            log.warn("No se pudo notificar solicitud de amistad a usuario {}: {}", idDestinatario, e.getMessage());
        }
    }
}
