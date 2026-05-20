package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Orquestación nocturna: descenso de cansancio a medianoche; luego (cron configurable) valor dinámico,
 * probabilidades titular y valoración coherente con mercado.
 */
@Component
public class LeagueNightlyMaintenanceScheduler {

    private static final Logger log = LoggerFactory.getLogger(LeagueNightlyMaintenanceScheduler.class);

    private final LeagueSimulationService leagueSimulationService;
    private final LeagueStarterProbabilityService leagueStarterProbabilityService;
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final AtomicBoolean fatigueDecayRunning = new AtomicBoolean(false);

    @Value("${app.league.nightly-maintenance.enabled:true}")
    private boolean enabled;

    @Value("${app.league.fatigue-midnight-decay.enabled:true}")
    private boolean fatigueMidnightDecayEnabled;

    public LeagueNightlyMaintenanceScheduler(
            LeagueSimulationService leagueSimulationService,
            LeagueStarterProbabilityService leagueStarterProbabilityService) {
        this.leagueSimulationService = leagueSimulationService;
        this.leagueStarterProbabilityService = leagueStarterProbabilityService;
    }

    /** Descenso global de cansancio ({@code -2} por jugador con cansancio &gt; 0). Por defecto 00:00:00 Europe/Madrid. */
    @Scheduled(
            cron = "${app.league.fatigue-midnight-decay.cron:0 0 0 * * *}",
            zone = "${app.league.fatigue-midnight-decay.zone:Europe/Madrid}"
    )
    public void runMidnightFatigueDecay() {
        if (!fatigueMidnightDecayEnabled) {
            return;
        }
        if (!fatigueDecayRunning.compareAndSet(false, true)) {
            log.warn("Descenso nocturno de cansancio ya en ejecución; tick omitido.");
            return;
        }
        try {
            int updated = leagueSimulationService.applyMidnightFatigueDecayAllLeaguePlayers();
            log.info("Cansancio nocturno OK | jugadores actualizados={}", updated);
        } catch (SQLException e) {
            log.error("Error aplicando descenso nocturno de cansancio", e);
        } finally {
            fatigueDecayRunning.set(false);
        }
    }

    @Scheduled(
            cron = "${app.league.nightly-maintenance.cron:0 2 0 * * *}",
            zone = "${app.league.nightly-maintenance.zone:Europe/Madrid}"
    )
    public void runNightlyLeagueMaintenance() {
        if (!enabled) {
            return;
        }
        if (!running.compareAndSet(false, true)) {
            log.warn("Mantenimiento nocturno de liga ya en ejecución; tick omitido.");
            return;
        }
        try {
            int dynamics = leagueSimulationService.applyDailyDynamicRatingsAndValuesForAllLeaguePlayers();
            leagueStarterProbabilityService.recalculateNextOpenRoundForAllLeagues();
            int synced = leagueSimulationService.syncValoracionActualFromValorForAllLeaguePlayers();
            log.info(
                    "Mantenimiento nocturno liga OK | dinámica jugadores={}, valoraciones sincronizadas={}",
                    dynamics,
                    synced);
        } catch (SQLException e) {
            log.error("Error en mantenimiento nocturno de liga", e);
        } finally {
            running.set(false);
        }
    }
}
