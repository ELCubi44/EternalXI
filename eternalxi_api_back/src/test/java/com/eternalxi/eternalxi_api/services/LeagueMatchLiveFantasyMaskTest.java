package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.league.LeagueMatchEventResponse;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LeagueMatchLiveFantasyMaskTest {

    @Test
    void eventosFuturosNoSonVisibles() {
        var redAt70 = event(1L, 70, 0, "TARJETA_ROJA", 99L);
        var all = List.of(redAt70);

        List<LeagueMatchEventResponse> visibleAt45 =
                LeagueMatchLiveFantasyMask.filterEventsVisibleNow(all, 45 * 60L, false);

        assertTrue(visibleAt45.isEmpty());

        List<LeagueMatchEventResponse> visibleAt70 =
                LeagueMatchLiveFantasyMask.filterEventsVisibleNow(all, 70 * 60L, false);

        assertEquals(1, visibleAt70.size());
        assertEquals("TARJETA_ROJA", visibleAt70.get(0).tipo());
    }

    @Test
    void rojaNoCuentaEnPuntosAntesDelMinutoVisible() {
        long idLj = 42L;
        var redAt70 = event(1L, 70, 0, "TARJETA_ROJA", idLj);
        var visibleAt45 = LeagueMatchLiveFantasyMask.filterEventsVisibleNow(
                List.of(redAt70),
                45 * 60L,
                false
        );
        LeagueMatchLiveFantasyMask.LiveVisibleDerivedCounts counts45 =
                LeagueMatchLiveFantasyMask.deriveVisibleCounts(idLj, visibleAt45);
        assertEquals(0, counts45.reds());
        assertFalse(counts45.injuredInMatch());

        var visibleAt70 = LeagueMatchLiveFantasyMask.filterEventsVisibleNow(
                List.of(redAt70),
                70 * 60L,
                false
        );
        LeagueMatchLiveFantasyMask.LiveVisibleDerivedCounts counts70 =
                LeagueMatchLiveFantasyMask.deriveVisibleCounts(idLj, visibleAt70);
        assertEquals(1, counts70.reds());
    }

    private static LeagueMatchEventResponse event(
            long id,
            int minuto,
            int segundo,
            String tipo,
            Long idLigaJugador
    ) {
        return new LeagueMatchEventResponse(
                id,
                minuto,
                segundo,
                tipo,
                null,
                idLigaJugador,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "test"
        );
    }
}
