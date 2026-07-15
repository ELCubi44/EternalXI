package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class LeagueSeasonWrapNotificationScheduler {

    private static final Logger log = LoggerFactory.getLogger(LeagueSeasonWrapNotificationScheduler.class);

    private final LeagueSeasonService leagueSeasonService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.league.season-wrap-notifications.enabled:true}")
    private boolean enabled;

    public LeagueSeasonWrapNotificationScheduler(LeagueSeasonService leagueSeasonService) {
        this.leagueSeasonService = leagueSeasonService;
    }

    @Scheduled(
            cron = "${app.league.season-wrap-notifications.cron:0 15 10 * * *}",
            zone = "${app.league.season-wrap-notifications.zone:Europe/Madrid}"
    )
    public void processSeasonWrapNotifications() {
        if (!enabled) {
            return;
        }
        if (!running.compareAndSet(false, true)) {
            return;
        }
        try {
            int sent = leagueSeasonService.processSeasonWrapNotifications();
            if (sent > 0) {
                log.info("Notificaciones de fin de temporada enviadas: {}", sent);
            }
        } catch (Exception e) {
            log.warn("Fallo en cron de notificaciones de fin de temporada: {}", e.getMessage());
        } finally {
            running.set(false);
        }
    }
}
