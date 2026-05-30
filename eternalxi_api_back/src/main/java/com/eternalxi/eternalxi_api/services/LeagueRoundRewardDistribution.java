package com.eternalxi.eternalxi_api.services;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * Reparto descendente de puntos de recompensa por jornada según posición fantasy.
 * Ejemplo (10 participantes, mínimo 500): 950, 900, 850, …, 500 (+50 por puesto).
 */
public final class LeagueRoundRewardDistribution {

    public static final int STEP = 50;

    private LeagueRoundRewardDistribution() {
    }

    public record ParticipantRef(long idLigaParticipante, long idUsuario, String nickname) {}

    public record RankedRoundReward(
            long idLigaParticipante,
            long idUsuario,
            String nickname,
            int puntosFantasyJornada,
            int posicionJornada,
            int puntosRecompensaJornada
    ) {}

    public static int rewardForRank(int rank, int participantCount, int minReward) {
        if (participantCount < 1 || minReward < 0) {
            return Math.max(0, minReward);
        }
        int safeRank = Math.max(1, Math.min(rank, participantCount));
        return minReward + (participantCount - safeRank) * STEP;
    }

    public static List<RankedRoundReward> rankAndAssignRewards(
            List<ParticipantRef> participants,
            Map<Long, Integer> fantasyPointsByUser,
            int minReward,
            Map<Long, Integer> grantedRewardByUser
    ) {
        if (participants == null || participants.isEmpty()) {
            return List.of();
        }

        int participantCount = participants.size();
        List<ParticipantRef> sorted = new ArrayList<>(participants);
        sorted.sort(Comparator
                .comparingInt((ParticipantRef p) ->
                        fantasyPointsByUser.getOrDefault(p.idUsuario(), 0))
                .reversed()
                .thenComparing(ParticipantRef::nickname, String.CASE_INSENSITIVE_ORDER)
                .thenComparingLong(ParticipantRef::idUsuario));

        List<RankedRoundReward> result = new ArrayList<>(sorted.size());
        int index = 0;
        int rank = 0;
        Integer lastPoints = null;

        for (ParticipantRef participant : sorted) {
            index++;
            int fantasyPts = Math.max(0, fantasyPointsByUser.getOrDefault(participant.idUsuario(), 0));
            if (lastPoints == null || fantasyPts != lastPoints) {
                rank = index;
                lastPoints = fantasyPts;
            }

            int computedReward = rewardForRank(rank, participantCount, minReward);
            Integer stored = grantedRewardByUser != null
                    ? grantedRewardByUser.get(participant.idUsuario())
                    : null;
            int rewardPts = stored != null ? stored : computedReward;

            result.add(new RankedRoundReward(
                    participant.idLigaParticipante(),
                    participant.idUsuario(),
                    participant.nickname(),
                    fantasyPts,
                    rank,
                    rewardPts
            ));
        }

        return List.copyOf(result);
    }
}
