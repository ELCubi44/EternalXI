package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class LeagueDynamicValueScheduler {

    private static final Logger log = LoggerFactory.getLogger(LeagueDynamicValueScheduler.class);

    private final LeagueSimulationService leagueSimulationService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.league.dynamic-value.scheduler.enabled:true}")
    private boolean enabled;

    public LeagueDynamicValueScheduler(LeagueSimulationService leagueSimulationService) {
        this.leagueSimulationService = leagueSimulationService;
    }

    /**
     * Repaso diario de valor/valoración (misma base que al cerrar partido). Omite jugadores cuyo equipo
     * en la liga aún no ha disputado ningún partido finalizado (evita mercado ficticio); con equipo ya
     * en juego, aplica también a suplentes sin minutos. Por defecto medianoche Europe/Madrid.
     */
    @Scheduled(
            cron = "${app.league.dynamic-value.cron:0 0 0 * * *}",
            zone = "${app.league.dynamic-value.zone:Europe/Madrid}"
    )
    public void applyDailyDynamicValues() {
        if (!enabled) {
            return;
        }
        if (!running.compareAndSet(false, true)) {
            log.warn("Valor dinámico diario ya en ejecución; se omite este tick.");
            return;
        }
        try {
            int n = leagueSimulationService.applyDailyDynamicRatingsAndValuesForAllLeaguePlayers();
            int synced = leagueSimulationService.syncValoracionActualFromValorForAllLeaguePlayers();
            log.info(
                    "Valor dinámico diario completado. Jugadores procesados: {}; valoraciones sincronizadas: {}",
                    n,
                    synced);
        } catch (SQLException e) {
            log.error("Error en valor dinámico diario", e);
        } finally {
            running.set(false);
        }
    }
}
