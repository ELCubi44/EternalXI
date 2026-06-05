package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.util.LeagueAssetUrls;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Map;

@Service
public class LeagueOfferNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueOfferNotificationService.class);

    private final UserNotificationService userNotificationService;

    public LeagueOfferNotificationService(UserNotificationService userNotificationService) {
        this.userNotificationService = userNotificationService;
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
        dispatch(payload.idUsuarioVendedor(), "offer_received", title, body, payload, "market", 0);
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
        dispatch(payload.idUsuarioComprador(), "offer_accepted", title, body, payload, "squad", 0);
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
        dispatch(payload.idUsuarioComprador(), "offer_rejected", title, body, payload, "market", 0);
    }

    private void dispatch(
            Long idUsuario,
            String tipo,
            String title,
            String body,
            OfferNotificationPayload payload,
            String actionTab,
            int actionSegment
    ) {
        try {
            Map<String, Object> datos = userNotificationService.datosBase(
                    payload.idLigaJugador(),
                    payload.idJugador(),
                    payload.jugadorNombre(),
                    LeagueAssetUrls.player(payload.idJugador()),
                    payload.idUsuarioComprador(),
                    payload.compradorNombre(),
                    LeagueAssetUrls.userPhoto(payload.idUsuarioComprador()),
                    payload.idOferta(),
                    payload.precio(),
                    actionTab,
                    actionSegment
            );
            if ("offer_received".equals(tipo)) {
                datos.put("idUsuarioActor", payload.idUsuarioComprador());
                datos.put("actorName", payload.compradorNombre());
                datos.put("actorPhotoUrl", LeagueAssetUrls.userPhoto(payload.idUsuarioComprador()));
            }
            String key = userNotificationService.idempotencyKey(
                    tipo,
                    String.valueOf(payload.idOferta()),
                    String.valueOf(idUsuario)
            );
            userNotificationService.notifyUser(
                    idUsuario,
                    payload.idLiga(),
                    tipo,
                    title,
                    body,
                    datos,
                    key,
                    userNotificationService.pushDataFromDatos(datos, tipo, payload.idLiga())
            );
        } catch (Exception e) {
            log.error("Error enviando notificación de oferta. usuario={}, title={}", idUsuario, title, e);
        }
    }

    private String formatEuro(long precio) {
        return String.format(Locale.ROOT, "%,d", precio).replace(',', '.') + " €";
    }

    public record OfferNotificationPayload(
            Long idOferta,
            Long idLiga,
            Long idLigaJugador,
            Long idJugador,
            Long idUsuarioComprador,
            Long idUsuarioVendedor,
            String compradorNombre,
            String vendedorNombre,
            String jugadorNombre,
            Long precio
    ) {
    }
}
