package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LeagueRoundRewardDistributionTest {

    @Test
    void rewardForRank_scalesByParticipantCount() {
        assertEquals(950, LeagueRoundRewardDistribution.rewardForRank(1, 10, 500));
        assertEquals(500, LeagueRoundRewardDistribution.rewardForRank(10, 10, 500));
        assertEquals(400, LeagueRoundRewardDistribution.rewardForRank(1, 4, 250));
        assertEquals(250, LeagueRoundRewardDistribution.rewardForRank(4, 4, 250));
    }

    @Test
    void rankAndAssignRewards_ordersByFantasyPoints() {
        var participants = List.of(
                new LeagueRoundRewardDistribution.ParticipantRef(1, 10, "A"),
                new LeagueRoundRewardDistribution.ParticipantRef(2, 20, "B"),
                new LeagueRoundRewardDistribution.ParticipantRef(3, 30, "C"),
                new LeagueRoundRewardDistribution.ParticipantRef(4, 40, "D")
        );
        var fantasy = Map.of(
                10L, 80,
                20L, 95,
                30L, 70,
                40L, 95
        );

        var ranked = LeagueRoundRewardDistribution.rankAndAssignRewards(
                participants,
                fantasy,
                250,
                Map.of()
        );

        assertEquals(4, ranked.size());
        assertEquals(20L, ranked.get(0).idUsuario());
        assertEquals(1, ranked.get(0).posicionJornada());
        assertEquals(400, ranked.get(0).puntosRecompensaJornada());
        assertEquals(40L, ranked.get(1).idUsuario());
        assertEquals(1, ranked.get(1).posicionJornada());
        assertEquals(30L, ranked.get(3).idUsuario());
        assertEquals(4, ranked.get(3).posicionJornada());
        assertEquals(250, ranked.get(3).puntosRecompensaJornada());
    }
}
