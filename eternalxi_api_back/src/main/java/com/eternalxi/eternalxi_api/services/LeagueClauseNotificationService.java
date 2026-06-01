package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

@Service
public class LeagueClauseNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeagueClauseNotificationService.class);

    private final PushNotificationService pushNotificationService;

    public LeagueClauseNotificationService(PushNotificationService pushNotificationService) {
        this.pushNotificationService = pushNotificationService;
    }

    public void notifyClauseExecuted(
            Long idUsuarioVendedor,
            Long idUsuarioComprador,
            Long idLiga,
            Long idLigaJugador,
            String nombreJugador,
            String nicknameComprador,
            long importePagado
    ) {
        if (idUsuarioVendedor == null || Objects.equals(idUsuarioVendedor, idUsuarioComprador)) {
            return;
        }
        String comprador = nicknameComprador != null && !nicknameComprador.isBlank()
                ? nicknameComprador
                : "Un rival";
        String jugador = nombreJugador != null && !nombreJugador.isBlank() ? nombreJugador : "tu jugador";
        String title = "Te han clausulado un jugador";
        String body = comprador + " ha fichado a " + jugador + " por " + formatEuro(importePagado);
        send(idUsuarioVendedor, title, body, buildData(idLiga, idLigaJugador, idUsuarioComprador));
    }

    private Map<String, String> buildData(Long idLiga, Long idLigaJugador, Long idUsuarioComprador) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "CLAUSE_EXECUTED");
        data.put("idLiga", String.valueOf(idLiga));
        data.put("idLigaJugador", String.valueOf(idLigaJugador));
        data.put("buyerId", String.valueOf(idUsuarioComprador));
        return data;
    }

    private void send(Long idUsuario, String title, String body, Map<String, String> data) {
        try {
            pushNotificationService.sendToUser(idUsuario, title, body, data);
        } catch (Exception e) {
            log.warn("No se pudo enviar push de cláusula a usuario {}: {}", idUsuario, e.getMessage());
        }
    }

    private String formatEuro(long precio) {
        return String.format(Locale.ROOT, "%,d", precio).replace(',', '.') + " €";
    }
}
