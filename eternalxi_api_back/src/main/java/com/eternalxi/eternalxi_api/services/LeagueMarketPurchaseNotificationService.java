package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Map;

@Service
public class LeagueMarketPurchaseNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueMarketPurchaseNotificationService.class);

    private final UserNotificationService userNotificationService;

    public LeagueMarketPurchaseNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
    }

    public void notifyInstantMarketPurchase(
            Long idUsuario,
            Long idLiga,
            Long idLigaJugador,
            Long idJugador,
            String playerName,
            long importePagado
    ) {
        if (idUsuario == null || idLiga == null || idLigaJugador == null) {
            return;
        }
        String nombre = playerName == null || playerName.isBlank() ? "tu nuevo jugador" : playerName;
        String title = "Fichaje del mercado";
        String body = "Has fichado a " + nombre + " por " + formatEuro(importePagado);
        Map<String, Object> datos = userNotificationService.datosBase(
                idLigaJugador,
                idJugador,
                nombre,
                LeagueAssetUrls.player(idJugador),
                null,
                null,
                null,
                null,
                importePagado,
                "squad",
                0
        );
        String tipo = "MARKET_PURCHASE";
        String key = userNotificationService.idempotencyKey(
                tipo,
                String.valueOf(idLiga),
                String.valueOf(idLigaJugador),
                String.valueOf(idUsuario)
        );
        try {
            userNotificationService.notifyUser(
                    idUsuario,
                    idLiga,
                    tipo,
                    title,
                    body,
                    datos,
                    key,
                    userNotificationService.pushDataFromDatos(datos, tipo, idLiga)
            );
        } catch (Exception e) {
            log.warn(
                    "No se pudo notificar compra de mercado. liga={}, usuario={}, jugador={}: {}",
                    idLiga,
                    idUsuario,
                    idLigaJugador,
                    e.getMessage()
            );
        }
    }

    private String formatEuro(long precio) {
        return String.format(Locale.ROOT, "%,d", precio).replace(',', '.') + " €";
    }
}
