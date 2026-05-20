package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class StarterProbabilityScheduler {

    private static final Logger log = LoggerFactory.getLogger(StarterProbabilityScheduler.class);

    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final LeagueSimulationService leagueSimulationService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.league.starter-probability.scheduler.enabled:true}")
    private boolean enabled;

    public StarterProbabilityScheduler(
            LeagueStarterProbabilityService leagueStarterProbabilityService,
            LeagueSimulationService leagueSimulationService) {
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
        this.leagueSimulationService = leagueSimulationService;
    }

    @Scheduled(
            cron = "${app.league.starter-probability.cron:0 0 0 * * *}",
            zone = "${app.league.starter-probability.zone:Europe/Madrid}"
    )
    public void recalculateDaily() {
        if (!enabled) {
            return;
        }
        if (!running.compareAndSet(false, true)) {
            log.warn("Starter probability scheduler ya en ejecución; se omite este tick.");
            return;
        }
        try {
            leagueStarterProbabilityService.recalculateNextOpenRoundForAllLeagues();
            int synced = leagueSimulationService.syncValoracionActualFromValorForAllLeaguePlayers();
            log.info(
                    "Probabilidades de titularidad actualizadas; valoraciones sincronizadas con mercado: {}",
                    synced);
        } catch (SQLException e) {
            log.error("Error recalculando probabilidades de titularidad", e);
        } finally {
            running.set(false);
        }
    }
}
