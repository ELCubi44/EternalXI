package com.eternalxi.eternalxi_api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class NightMarketScheduler {

    private static final Logger log = LoggerFactory.getLogger(NightMarketScheduler.class);

    private final NightMarketService nightMarketService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    @Value("${app.night-market.enabled:true}")
    private boolean enabled;

    public NightMarketScheduler(NightMarketService nightMarketService) {
        this.nightMarketService = nightMarketService;
    }

    @Scheduled(
            cron = "${app.night-market.cron:0 0 0 * * *}",
            zone = "${app.night-market.zone:Europe/Madrid}"
    )
    public void processNightMarket() {
        if (!enabled) {
            return;
        }

        if (!running.compareAndSet(false, true)) {
            log.warn("Night market ya está ejecutándose. Se omite este tick.");
            return;
        }

        try {
            NightMarketService.ProcessResult result = nightMarketService.processNightMarketNow();
            log.info(
                    "Night market procesado. fecha={}, resolvedItems={}, generatedItems={}",
                    result.fecha(),
                    result.resolvedItems(),
                    result.generatedItems()
            );
        } catch (Exception e) {
            log.error("Error procesando night market", e);
        } finally {
            running.set(false);
        }
    }
}