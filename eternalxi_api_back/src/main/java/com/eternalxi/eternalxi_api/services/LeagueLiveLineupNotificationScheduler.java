package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class LeagueLiveLineupNotificationScheduler {

    private static final Logger log = LoggerFactory.getLogger(LeagueLiveLineupNotificationScheduler.class);

    private final LeagueLineupAvailabilityNotificationService lineupAvailabilityNotificationService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.league.lineup-live-notifications.enabled:true}")
    private boolean enabled;

    public LeagueLiveLineupNotificationScheduler(
            LeagueLineupAvailabilityNotificationService lineupAvailabilityNotificationService
    ) {
        this.lineupAvailabilityNotificationService = lineupAvailabilityNotificationService;
    }

    @Scheduled(
            cron = "${app.league.lineup-live-notifications.cron:0 */1 * * * *}",
            zone = "${app.league.lineup-live-notifications.zone:Europe/Madrid}"
    )
    public void processLiveLineupNotifications() {
        if (!enabled) {
            return;
        }
        if (!running.compareAndSet(false, true)) {
            return;
        }
        try {
            int sent = lineupAvailabilityNotificationService.processLiveMatchNotifications();
            if (sent > 0) {
                log.info("Notificaciones live de bajas en alineación enviadas: {}", sent);
            }
        } catch (Exception e) {
            log.warn("Fallo en cron de notificaciones live de alineación: {}", e.getMessage());
        } finally {
            running.set(false);
        }
    }
}
