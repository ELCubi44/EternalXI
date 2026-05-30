package com.eternalxi.eternalxi_api.dto.league;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LeagueCreationConfigTest {

    @Test
    void sinCamposOpcionalesUsaDefaultsLegacy() {
        CreateLeagueRequest request = new CreateLeagueRequest(
                "Liga test", 1L, 3L,
                null, null, null, null, null, null
        );

        LeagueCreationConfig config = LeagueCreationConfig.resolve(request);

        assertEquals(10, config.maxParticipantes());
        assertFalse(config.semanaPreviaFichajes());
        assertFalse(config.permiteEntresemana());
        assertTrue(config.idaYVuelta());
        assertEquals(150, config.recompensaBaseJornada());
        assertEquals(0, config.recompensaBonusGanador());
        assertEquals(100_000L, config.dineroPorPuntoFantasy());
    }

    @Test
    void aceptaConfiguracionNuevaCompleta() {
        CreateLeagueRequest request = new CreateLeagueRequest(
                "Liga nueva", 1L, 3L,
                12, true, true, false, 500, 200_000L
        );

        LeagueCreationConfig config = LeagueCreationConfig.resolve(request);

        assertEquals(12, config.maxParticipantes());
        assertTrue(config.semanaPreviaFichajes());
        assertTrue(config.permiteEntresemana());
        assertFalse(config.idaYVuelta());
        assertEquals(500, config.recompensaBaseJornada());
        assertEquals(200_000L, config.dineroPorPuntoFantasy());
    }

    @Test
    void rechazaMaxParticipantesInvalido() {
        CreateLeagueRequest request = new CreateLeagueRequest(
                "Liga", 1L, 3L,
                11, null, null, null, null, null
        );
        assertThrows(IllegalArgumentException.class, () -> LeagueCreationConfig.resolve(request));
    }

    @Test
    void rechazaRecompensaBaseFueraDeRangoCuandoVieneInformada() {
        CreateLeagueRequest request = new CreateLeagueRequest(
                "Liga", 1L, 3L,
                null, null, null, null, 299, null
        );
        assertThrows(IllegalArgumentException.class, () -> LeagueCreationConfig.resolve(request));
    }

    @Test
    void rechazaDineroPorPuntoInvalido() {
        CreateLeagueRequest request = new CreateLeagueRequest(
                "Liga", 1L, 3L,
                null, null, null, null, null, 150_000L
        );
        assertThrows(IllegalArgumentException.class, () -> LeagueCreationConfig.resolve(request));
    }
}
