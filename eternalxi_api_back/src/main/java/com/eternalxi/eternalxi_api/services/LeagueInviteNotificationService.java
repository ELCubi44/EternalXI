package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class LeagueInviteNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueInviteNotificationService.class);

    private final UserNotificationService userNotificationService;

    public LeagueInviteNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    public void notifyLeagueInvite(
            Long idAmigo,
            Long idAdmin,
            String adminNick,
            Long idLiga,
            String leagueName,
            String codigoInvitacion
    ) {
        if (idAmigo == null || idLiga == null) {
            return;
        }
        String admin = adminNick == null || adminNick.isBlank() ? "El administrador" : adminNick.trim();
        String liga = leagueName == null || leagueName.isBlank() ? "una liga" : leagueName.trim();
        String title = "Invitacion a liga";
        String body = admin + " te ha invitado a unirte a " + liga;
        try {
            Map<String, Object> datos = new HashMap<>();
            datos.put("idLiga", idLiga);
            datos.put("idUsuarioActor", idAdmin);
            datos.put("actorName", admin);
            datos.put("leagueName", liga);
            datos.put("codigoInvitacion", codigoInvitacion);
            datos.put("actionRoute", "join_league");

            String key = userNotificationService.idempotencyKey(
                    "LEAGUE_INVITE",
                    String.valueOf(idLiga),
                    String.valueOf(idAmigo)
            );

            Map<String, String> pushData = new HashMap<>();
            pushData.put("type", "LEAGUE_INVITE");
            pushData.put("idLiga", String.valueOf(idLiga));
            if (codigoInvitacion != null) {
                pushData.put("codigoInvitacion", codigoInvitacion);
            }
            pushData.put("actionRoute", "join_league");

            userNotificationService.notifyUser(
                    idAmigo,
                    idLiga,
                    "LEAGUE_INVITE",
                    title,
                    body,
                    datos,
                    key,
                    pushData
            );
        } catch (Exception e) {
            log.warn("No se pudo notificar invitacion de liga {} a usuario {}: {}",
                    idLiga, idAmigo, e.getMessage());
        }
    }
}
