package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NightMarketNotificationService {

    private static final Logger log = LoggerFactory.getLogger(NightMarketNotificationService.class);

    private final PushNotificationService pushNotificationService;

    @Value("${app.push.market-awards.enabled:true}")
    private boolean enabled;

    public NightMarketNotificationService(PushNotificationService pushNotificationService) {
        this.pushNotificationService = pushNotificationService;
    }

    public void notifyAwards(List<NightMarketService.MarketAward> awards) {
        if (!enabled || awards == null || awards.isEmpty()) {
            return;
        }

        for (NightMarketService.MarketAward award : awards) {
            if (award == null || award.idUsuario() == null) {
                continue;
            }

            String playerName = award.nombreMostradoJugador();
            if (playerName == null || playerName.isBlank()) {
                playerName = "tu nuevo jugador";
            }

            String teamName = award.nombreEquipo();

            String title = "Mercado resuelto";
            String body;
            if (teamName != null && !teamName.isBlank()) {
                body = "Te has llevado a " + playerName + " de " + teamName + ". Entra a alinearlo.";
            } else {
                body = "Te has llevado a " + playerName + ". Entra a alinearlo.";
            }

            Map<String, String> data = new HashMap<>();
            data.put("type", "market_award");
            data.put("idLiga", String.valueOf(award.idLiga()));
            data.put("idLigaJugador", String.valueOf(award.idLigaJugador()));
            data.put("playerName", playerName);

            if (teamName != null && !teamName.isBlank()) {
                data.put("teamName", teamName);
            }

            try {
                pushNotificationService.sendToUser(
                        award.idUsuario(),
                        title,
                        body,
                        data
                );
            } catch (Exception e) {
                log.error(
                        "Error enviando notificación de mercado. liga={}, usuario={}, jugador={}",
                        award.idLiga(),
                        award.idUsuario(),
                        award.idLigaJugador(),
                        e
                );
            }
        }
    }
}