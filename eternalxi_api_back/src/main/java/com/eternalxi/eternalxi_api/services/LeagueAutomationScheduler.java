package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.config.LeagueAutomationProperties;
import com.eternalxi.eternalxi_api.dto.league.LeagueSimulationRunResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class LeagueAutomationScheduler {

    private static final Logger log = LoggerFactory.getLogger(LeagueAutomationScheduler.class);

    private final LeagueSimulationService leagueSimulationService;
    private final LeagueAutomationProperties leagueAutomationProperties;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.league.automation.enabled:true}")
    private boolean enabled;

    public LeagueAutomationScheduler(
            LeagueSimulationService leagueSimulationService,
            LeagueAutomationProperties leagueAutomationProperties
    ) {
        this.leagueSimulationService = leagueSimulationService;
        this.leagueAutomationProperties = leagueAutomationProperties;
    }

    @Scheduled(
        cron = "${app.league.automation.cron:0 * * * * *}",
        zone = "${app.league.automation.zone:Europe/Madrid}"
)
public void processLeagueAutomation() {
    if (!enabled) {
        return;
    }

    if (!leagueAutomationProperties.getAllowedLeagueIds().isEmpty()) {
        log.debug(
                "League automation: solo ligas permitidas {}",
                leagueAutomationProperties.getAllowedLeagueIds()
        );
    }

    if (!running.compareAndSet(false, true)) {
        log.warn("League automation ya está ejecutándose. Se omite este tick.");
        return;
    }

    int prepared = 0;
    int finalized = 0;
    LeagueSimulationRunResponse simulationResponse = null;

    try {
        try {
            prepared = leagueSimulationService.prepareDueLineups();
        } catch (Exception e) {
            log.error("Error preparando alineaciones pendientes", e);
        }

        try {
            simulationResponse = leagueSimulationService.runDueSimulations();
        } catch (Exception e) {
            log.error("Error simulando partidos pendientes", e);
        }

        try {
            finalized = leagueSimulationService.finalizeDueMatchesNow();
        } catch (Exception e) {
            log.error("Error finalizando partidos vencidos", e);
        }

        log.info(
                "League automation ejecutada. preparedLineups={}, finalizedMatches={}, simulationResponse={}",
                prepared,
                finalized,
                simulationResponse
        );
    } finally {
        running.set(false);
    }
    }
}