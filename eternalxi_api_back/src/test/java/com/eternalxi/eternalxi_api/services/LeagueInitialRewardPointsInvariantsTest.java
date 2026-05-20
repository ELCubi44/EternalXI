package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.rewards.RewardPackType;
import com.eternalxi.eternalxi_api.services.rewards.RewardPackCatalog;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Invariantes del saldo inicial de recompensa por liga (1000) frente a costes de sobre y ruleta.
 * La semilla real en BD la aplica {@link LeagueService#insertParticipant}; aquí se fijan los números del producto.
 */
class LeagueInitialRewardPointsInvariantsTest {

    @Test
    void semillaInicialEsMilCoincideConPuntosRecompensaUsuarioEnResumen() {
        assertEquals(1000L, LeagueService.INITIAL_LEAGUE_REWARD_POINTS);
    }

    @Test
    void abrirSobreBasicoDescuentaDesdeMil() {
        int coste = RewardPackCatalog.get(RewardPackType.BASIC_PACK).costePuntos();
        long resto = LeagueService.INITIAL_LEAGUE_REWARD_POINTS - coste;
        assertEquals(850L, resto);
    }

    @Test
    void ruletaDescuentaMilYDejaCero() {
        int coste = RewardPackCatalog.COSTE_RULETA_ENTRENADOR;
        assertEquals(LeagueService.INITIAL_LEAGUE_REWARD_POINTS, coste);
        long resto = LeagueService.INITIAL_LEAGUE_REWARD_POINTS - coste;
        assertEquals(0L, resto);
    }

    @Test
    void todosLosSobresCabenEnSaldoInicial() {
        for (RewardPackType t : RewardPackType.values()) {
            int c = RewardPackCatalog.get(t).costePuntos();
            assertTrue(c <= LeagueService.INITIAL_LEAGUE_REWARD_POINTS, t.name());
        }
    }
}
