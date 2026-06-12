package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class NightMarketNotificationService {

    private static final Logger log = LoggerFactory.getLogger(NightMarketNotificationService.class);

    private final UserNotificationService userNotificationService;

    @Value("${app.push.market-awards.enabled:true}")
    private boolean enabled;

    public NightMarketNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
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

            Map<String, Object> datos = userNotificationService.datosBase(
                    award.idLigaJugador(),
                    award.idJugador(),
                    playerName,
                    LeagueAssetUrls.player(award.idJugador()),
                    null,
                    null,
                    null,
                    null,
                    null,
                    "squad",
                    0
            );
            if (teamName != null && !teamName.isBlank()) {
                datos.put("teamName", teamName);
            }
            String tipo = "market_award";
            String key = userNotificationService.idempotencyKey(
                    tipo,
                    String.valueOf(award.idLiga()),
                    String.valueOf(award.idLigaJugador()),
                    String.valueOf(award.idUsuario())
            );
            try {
                userNotificationService.notifyUser(
                        award.idUsuario(),
                        award.idLiga(),
                        tipo,
                        title,
                        body,
                        datos,
                        key,
                        userNotificationService.pushDataFromDatos(datos, tipo, award.idLiga())
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
