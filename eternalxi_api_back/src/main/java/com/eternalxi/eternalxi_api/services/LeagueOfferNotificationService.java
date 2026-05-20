package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

@Service
public class LeagueOfferNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueOfferNotificationService.class);

    private final PushNotificationService pushNotificationService;

    public LeagueOfferNotificationService(PushNotificationService pushNotificationService) {
        this.pushNotificationService = pushNotificationService;
    }

    public void notifyOfferReceived(OfferNotificationPayload payload) {
        if (payload == null || payload.idUsuarioVendedor() == null) {
            return;
        }
        String title = "Nueva oferta recibida";
        String body = payload.compradorNombre()
                + " te ha hecho una oferta por "
                + payload.jugadorNombre()
                + " de "
                + formatEuro(payload.precio());
        send(payload.idUsuarioVendedor(), title, body, buildData("offer_received", payload));
    }

    public void notifyOfferAccepted(OfferNotificationPayload payload) {
        if (payload == null || payload.idUsuarioComprador() == null) {
            return;
        }
        String title = "Oferta aceptada";
        String body = payload.vendedorNombre()
                + " ha aceptado tu oferta por "
                + payload.jugadorNombre()
                + " de "
                + formatEuro(payload.precio());
        send(payload.idUsuarioComprador(), title, body, buildData("offer_accepted", payload));
    }

    public void notifyOfferRejected(OfferNotificationPayload payload) {
        if (payload == null || payload.idUsuarioComprador() == null) {
            return;
        }
        String title = "Oferta rechazada";
        String body = payload.vendedorNombre()
                + " ha rechazado tu oferta por "
                + payload.jugadorNombre()
                + " de "
                + formatEuro(payload.precio());
        send(payload.idUsuarioComprador(), title, body, buildData("offer_rejected", payload));
    }

    private Map<String, String> buildData(String type, OfferNotificationPayload payload) {
        Map<String, String> data = new HashMap<>();
        data.put("type", type);
        data.put("idLiga", String.valueOf(payload.idLiga()));
        data.put("idLigaJugador", String.valueOf(payload.idLigaJugador()));
        data.put("idOferta", String.valueOf(payload.idOferta()));
        data.put("precio", String.valueOf(payload.precio()));
        data.put("playerName", payload.jugadorNombre());
        data.put("buyerId", String.valueOf(payload.idUsuarioComprador()));
        data.put("sellerId", String.valueOf(payload.idUsuarioVendedor()));
        return data;
    }

    private void send(Long idUsuario, String title, String body, Map<String, String> data) {
        try {
            pushNotificationService.sendToUser(idUsuario, title, body, data);
        } catch (Exception e) {
            log.error("Error enviando push de oferta. usuario={}, title={}", idUsuario, title, e);
        }
    }

    private String formatEuro(long precio) {
        return String.format(Locale.ROOT, "%,d", precio).replace(',', '.') + " €";
    }

    public record OfferNotificationPayload(
            Long idOferta,
            Long idLiga,
            Long idLigaJugador,
            Long idUsuarioComprador,
            Long idUsuarioVendedor,
            String compradorNombre,
            String vendedorNombre,
            String jugadorNombre,
            Long precio
    ) {
    }
}
