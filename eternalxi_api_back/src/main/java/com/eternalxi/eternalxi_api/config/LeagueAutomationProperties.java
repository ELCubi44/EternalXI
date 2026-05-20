package com.eternalxi.eternalxi_api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Automatización de ligas (preparar alineaciones, simular, finalizar).
 * <p>
 * {@code allowedLeagueIds} vacío → todas las ligas (comportamiento legacy).
 * Si se rellena (p. ej. solo liga TEST {@code 7}), el scheduler ignora el resto.
 */
@Component
@ConfigurationProperties(prefix = "app.league.automation")
public class LeagueAutomationProperties {

    private boolean enabled = true;
    private List<Long> allowedLeagueIds = new ArrayList<>();

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public List<Long> getAllowedLeagueIds() {
        return allowedLeagueIds == null ? List.of() : allowedLeagueIds;
    }

    public void setAllowedLeagueIds(List<Long> allowedLeagueIds) {
        this.allowedLeagueIds = allowedLeagueIds;
    }

    public boolean isLeagueAllowed(Long idLiga) {
        if (idLiga == null) {
            return false;
        }
        List<Long> allowed = getAllowedLeagueIds();
        if (allowed.isEmpty()) {
            return true;
        }
        return allowed.contains(idLiga);
    }

    public Set<Long> allowedLeagueIdSet() {
        return Collections.unmodifiableSet(
                getAllowedLeagueIds().stream().collect(Collectors.toSet())
        );
    }
}
