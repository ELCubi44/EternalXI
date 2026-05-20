package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class InitialSquadSelectorTest {

    @Test
    void poolCompletoGeneraQuinceJugadoresEnBandaDeValor() {
        List<InitialSquadSelector.SquadCandidate> pool = buildRichPool();

        InitialSquadSelector.SelectionResult result = InitialSquadSelector.select(pool);

        assertEquals(15, result.assignedCount());
        assertFalse(result.incomplete());
        assertTrue(
                result.totalValue() >= InitialSquadSelector.MIN_INITIAL_SQUAD_VALUE,
                "valor=" + result.totalValue()
        );
        assertTrue(
                result.totalValue() <= InitialSquadSelector.MAX_INITIAL_SQUAD_VALUE,
                "valor=" + result.totalValue()
        );
        assertBalancedPositions(pool, result.leaguePlayerIds());
    }

    @Test
    void poolLimitadoSinDelanterosEntraSinExcepcion() {
        List<InitialSquadSelector.SquadCandidate> pool = new ArrayList<>();
        long id = 1L;
        for (int i = 0; i < 4; i++) {
            pool.add(candidate(id++, 1L, "POR", 75, 12_000_000L));
        }
        for (int i = 0; i < 8; i++) {
            pool.add(candidate(id++, 2L, "DEF", 78, 14_000_000L));
        }
        for (int i = 0; i < 6; i++) {
            pool.add(candidate(id++, 3L, "MED", 80, 15_000_000L));
        }
        pool.add(candidate(id++, 4L, "DEL", 82, 16_000_000L));

        InitialSquadSelector.SelectionResult result = InitialSquadSelector.select(pool);

        assertTrue(result.assignedCount() > 0);
        assertTrue(result.assignedCount() <= pool.size());
        assertTrue(result.incomplete());
    }

    @Test
    void poolVacioPermiteEntradaSinJugadores() {
        InitialSquadSelector.SelectionResult result = InitialSquadSelector.select(List.of());

        assertEquals(0, result.assignedCount());
        assertTrue(result.incomplete());
        assertEquals("EMPTY_POOL", result.strategy());
    }

    private static List<InitialSquadSelector.SquadCandidate> buildRichPool() {
        List<InitialSquadSelector.SquadCandidate> pool = new ArrayList<>();
        long id = 1L;
        long[] teamIds = {10L, 11L, 12L, 13L, 14L, 15L, 16L, 17L, 18L, 19L, 20L, 21L};

        for (int t = 0; t < teamIds.length; t++) {
            long teamId = teamIds[t];
            for (int i = 0; i < 2; i++) {
                pool.add(candidate(id++, teamId, "POR", 78 + t % 5, 11_000_000L + t * 200_000L));
            }
            for (int i = 0; i < 5; i++) {
                pool.add(candidate(id++, teamId, "DEF", 80 + t % 4, 12_000_000L + t * 250_000L));
            }
            for (int i = 0; i < 4; i++) {
                pool.add(candidate(id++, teamId, "MED", 82 + t % 3, 12_500_000L + t * 300_000L));
            }
            for (int i = 0; i < 4; i++) {
                pool.add(candidate(id++, teamId, "DEL", 84 + t % 2, 13_000_000L + t * 350_000L));
            }
        }
        return pool;
    }

    private static InitialSquadSelector.SquadCandidate candidate(
            long leaguePlayerId,
            long teamId,
            String position,
            int rating,
            long value
    ) {
        return new InitialSquadSelector.SquadCandidate(leaguePlayerId, teamId, position, rating, value);
    }

    private static void assertBalancedPositions(
            List<InitialSquadSelector.SquadCandidate> pool,
            List<Long> selectedIds
    ) {
        int por = 0;
        int def = 0;
        int med = 0;
        int del = 0;
        for (InitialSquadSelector.SquadCandidate candidate : pool) {
            if (!selectedIds.contains(candidate.leaguePlayerId())) {
                continue;
            }
            switch (candidate.position()) {
                case "POR" -> por++;
                case "DEF" -> def++;
                case "MED" -> med++;
                case "DEL" -> del++;
                default -> { }
            }
        }
        assertTrue(por >= 1 && por <= 3);
        assertTrue(def >= 3);
        assertTrue(med >= 3);
        assertTrue(del >= 2);
    }
}
