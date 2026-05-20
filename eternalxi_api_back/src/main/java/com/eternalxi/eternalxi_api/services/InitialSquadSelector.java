package com.eternalxi.eternalxi_api.services;

import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;

/**
 * Selección de plantilla inicial al crear/unirse a liga: calidad cuando hay pool suficiente,
 * sin bloquear la entrada si no se puede completar.
 */
public final class InitialSquadSelector {

    public static final int SQUAD_SIZE = 15;
    public static final long MIN_INITIAL_SQUAD_VALUE = 150_000_000L;
    public static final long MAX_INITIAL_SQUAD_VALUE = 220_000_000L;
    public static final long TARGET_INITIAL_SQUAD_VALUE = 185_000_000L;

    private static final int IDEAL_DRAFT_ATTEMPTS = 1_500;
    private static final int RELAXED_DRAFT_ATTEMPTS = 500;
    private static final int VALUE_TARGET_DRAFT_ATTEMPTS = 1_000;
    private static final int MAX_PLAYERS_PER_TEAM = 3;

    private static final Map<Position, Integer> IDEAL_QUOTAS = Map.of(
            Position.POR, 2,
            Position.DEF, 5,
            Position.MED, 4,
            Position.DEL, 4
    );

    private static final Map<Position, Integer> RELAXED_MIN_QUOTAS = Map.of(
            Position.POR, 1,
            Position.DEF, 3,
            Position.MED, 3,
            Position.DEL, 2
    );

    private InitialSquadSelector() {
    }

    public record SquadCandidate(
            long leaguePlayerId,
            long teamId,
            String position,
            int rating,
            long value
    ) {}

    public record SelectionResult(
            List<Long> leaguePlayerIds,
            long totalValue,
            boolean incomplete,
            String strategy
    ) {
        public int assignedCount() {
            return leaguePlayerIds.size();
        }
    }

    public static SelectionResult select(List<SquadCandidate> pool) {
        if (pool == null || pool.isEmpty()) {
            return new SelectionResult(List.of(), 0L, true, "EMPTY_POOL");
        }

        Random random = new Random(42L);

        DraftCandidate bestInValueRange = null;
        DraftCandidate bestIdeal = null;
        DraftCandidate bestRelaxed = null;
        DraftCandidate bestAnyFifteen = null;

        for (int i = 0; i < IDEAL_DRAFT_ATTEMPTS; i++) {
            List<SquadCandidate> draft = tryQuotaDraft(pool, IDEAL_QUOTAS, random);
            if (draft == null) {
                continue;
            }
            DraftCandidate candidate = toCandidate(draft, "IDEAL_DRAFT");
            bestIdeal = better(bestIdeal, candidate);
            bestAnyFifteen = betterClosestToTarget(bestAnyFifteen, candidate);
            if (isInValueRange(candidate.totalValue)) {
                bestInValueRange = betterInRange(bestInValueRange, candidate);
            }
        }

        if (bestInValueRange != null) {
            return toResult(bestInValueRange);
        }

        for (int i = 0; i < RELAXED_DRAFT_ATTEMPTS; i++) {
            List<SquadCandidate> draft = tryRelaxedDraft(pool, random);
            if (draft == null) {
                continue;
            }
            DraftCandidate candidate = toCandidate(draft, "RELAXED_DRAFT");
            bestRelaxed = better(bestRelaxed, candidate);
            bestAnyFifteen = betterClosestToTarget(bestAnyFifteen, candidate);
            if (isInValueRange(candidate.totalValue)) {
                bestInValueRange = betterInRange(bestInValueRange, candidate);
            }
        }

        if (bestInValueRange != null) {
            return toResult(bestInValueRange);
        }

        for (int i = 0; i < VALUE_TARGET_DRAFT_ATTEMPTS; i++) {
            List<SquadCandidate> draft = tryRandomFifteen(pool, random);
            if (draft == null) {
                continue;
            }
            DraftCandidate candidate = toCandidate(draft, "VALUE_TARGET_DRAFT");
            bestAnyFifteen = betterClosestToTarget(bestAnyFifteen, candidate);
            if (isInValueRange(candidate.totalValue)) {
                bestInValueRange = betterInRange(bestInValueRange, candidate);
            }
        }

        if (bestInValueRange != null) {
            return toResult(bestInValueRange);
        }

        if (bestAnyFifteen != null) {
            return toResult(bestAnyFifteen.withStrategy("CLOSEST_TO_TARGET_15"));
        }

        if (bestRelaxed != null) {
            return toResult(bestRelaxed.withStrategy("RELAXED_BEST_EFFORT"));
        }

        if (bestIdeal != null) {
            return toResult(bestIdeal.withStrategy("IDEAL_OUT_OF_VALUE_BAND"));
        }

        List<SquadCandidate> optimized = tryGreedyFifteenClosestToTarget(pool);
        if (optimized != null && optimized.size() == SQUAD_SIZE) {
            return toResult(toCandidate(optimized, "GREEDY_SWAP_TARGET"));
        }

        List<SquadCandidate> partial = tryBestPartialSquad(pool);
        boolean incomplete = partial.size() < SQUAD_SIZE;
        return new SelectionResult(
                partial.stream().map(SquadCandidate::leaguePlayerId).toList(),
                sumValue(partial),
                incomplete,
                incomplete ? "PARTIAL_BALANCED" : "PARTIAL_FULL_POOL"
        );
    }

    private static List<SquadCandidate> tryQuotaDraft(
            List<SquadCandidate> pool,
            Map<Position, Integer> quotas,
            Random random
    ) {
        Map<Position, List<SquadCandidate>> byPosition = groupByPosition(pool);
        for (Map.Entry<Position, Integer> entry : quotas.entrySet()) {
            if (byPosition.getOrDefault(entry.getKey(), List.of()).size() < entry.getValue()) {
                return null;
            }
        }

        List<Position> order = new ArrayList<>(quotas.keySet());
        Collections.shuffle(order, random);

        Set<Long> used = new HashSet<>();
        Map<Long, Integer> teamCount = new HashMap<>();
        List<SquadCandidate> squad = new ArrayList<>();

        for (Position position : order) {
            int need = quotas.get(position);
            List<SquadCandidate> candidates = new ArrayList<>(byPosition.get(position));
            Collections.shuffle(candidates, random);
            int picked = 0;
            for (SquadCandidate candidate : candidates) {
                if (picked >= need) {
                    break;
                }
                if (tryAdd(candidate, used, teamCount, squad)) {
                    picked++;
                }
            }
            if (picked < need) {
                return null;
            }
        }

        return squad.size() == SQUAD_SIZE ? squad : null;
    }

    private static List<SquadCandidate> tryRelaxedDraft(List<SquadCandidate> pool, Random random) {
        Map<Position, List<SquadCandidate>> byPosition = groupByPosition(pool);
        for (Map.Entry<Position, Integer> entry : RELAXED_MIN_QUOTAS.entrySet()) {
            if (byPosition.getOrDefault(entry.getKey(), List.of()).size() < entry.getValue()) {
                return null;
            }
        }

        List<Position> order = new ArrayList<>(RELAXED_MIN_QUOTAS.keySet());
        Collections.shuffle(order, random);

        Set<Long> used = new HashSet<>();
        Map<Long, Integer> teamCount = new HashMap<>();
        List<SquadCandidate> squad = new ArrayList<>();

        for (Position position : order) {
            int need = RELAXED_MIN_QUOTAS.get(position);
            List<SquadCandidate> candidates = new ArrayList<>(byPosition.get(position));
            Collections.shuffle(candidates, random);
            int picked = 0;
            for (SquadCandidate candidate : candidates) {
                if (picked >= need) {
                    break;
                }
                if (tryAdd(candidate, used, teamCount, squad)) {
                    picked++;
                }
            }
            if (picked < need) {
                return null;
            }
        }

        List<SquadCandidate> remaining = new ArrayList<>();
        for (SquadCandidate candidate : pool) {
            if (!used.contains(candidate.leaguePlayerId())) {
                remaining.add(candidate);
            }
        }
        remaining.sort((a, b) -> Long.compare(b.value(), a.value()));
        Collections.shuffle(remaining.subList(0, Math.min(remaining.size(), 40)), random);

        for (SquadCandidate candidate : remaining) {
            if (squad.size() >= SQUAD_SIZE) {
                break;
            }
            tryAdd(candidate, used, teamCount, squad);
        }

        return squad.size() == SQUAD_SIZE ? squad : null;
    }

    private static List<SquadCandidate> tryRandomFifteen(List<SquadCandidate> pool, Random random) {
        if (pool.size() < SQUAD_SIZE) {
            return null;
        }
        List<SquadCandidate> shuffled = new ArrayList<>(pool);
        Collections.shuffle(shuffled, random);

        Set<Long> used = new HashSet<>();
        Map<Long, Integer> teamCount = new HashMap<>();
        List<SquadCandidate> squad = new ArrayList<>();

        for (SquadCandidate candidate : shuffled) {
            if (squad.size() >= SQUAD_SIZE) {
                break;
            }
            tryAdd(candidate, used, teamCount, squad);
        }

        if (squad.size() < SQUAD_SIZE) {
            List<SquadCandidate> byValue = new ArrayList<>(pool);
            byValue.sort((a, b) -> Long.compare(b.value(), a.value()));
            for (SquadCandidate candidate : byValue) {
                if (squad.size() >= SQUAD_SIZE) {
                    break;
                }
                tryAdd(candidate, used, teamCount, squad);
            }
        }

        return squad.size() == SQUAD_SIZE ? squad : null;
    }

    private static List<SquadCandidate> tryGreedyFifteenClosestToTarget(List<SquadCandidate> pool) {
        if (pool.size() < SQUAD_SIZE) {
            return null;
        }

        List<SquadCandidate> sorted = new ArrayList<>(pool);
        sorted.sort((a, b) -> Long.compare(b.value(), a.value()));

        Set<Long> used = new HashSet<>();
        Map<Long, Integer> teamCount = new HashMap<>();
        List<SquadCandidate> squad = new ArrayList<>();

        for (SquadCandidate candidate : sorted) {
            if (squad.size() >= SQUAD_SIZE) {
                break;
            }
            tryAdd(candidate, used, teamCount, squad);
        }

        if (squad.size() < SQUAD_SIZE) {
            return null;
        }

        adjustTowardTarget(squad, pool);
        return squad.size() == SQUAD_SIZE ? squad : null;
    }

    private static void adjustTowardTarget(List<SquadCandidate> squad, List<SquadCandidate> pool) {
        for (int iteration = 0; iteration < 250; iteration++) {
            long total = sumValue(squad);
            if (total >= MIN_INITIAL_SQUAD_VALUE && total <= MAX_INITIAL_SQUAD_VALUE) {
                return;
            }

            boolean improved = false;
            if (total > MAX_INITIAL_SQUAD_VALUE) {
                improved = trySwap(squad, pool, true);
            } else if (total < MIN_INITIAL_SQUAD_VALUE) {
                improved = trySwap(squad, pool, false);
            }
            if (!improved) {
                break;
            }
        }
    }

    private static boolean trySwap(List<SquadCandidate> squad, List<SquadCandidate> pool, boolean reduceValue) {
        long currentTotal = sumValue(squad);
        Set<Long> inSquad = new HashSet<>();
        for (SquadCandidate player : squad) {
            inSquad.add(player.leaguePlayerId());
        }

        SquadCandidate bestOut = null;
        SquadCandidate bestIn = null;
        long bestDistance = Long.MAX_VALUE;

        for (SquadCandidate out : squad) {
            Map<Long, Integer> teamCountWithout = teamCountsExcluding(squad, out.leaguePlayerId());
            for (SquadCandidate in : pool) {
                if (inSquad.contains(in.leaguePlayerId())) {
                    continue;
                }
                if (!canAddWithCounts(in, teamCountWithout)) {
                    continue;
                }
                long newTotal = currentTotal - out.value() + in.value();
                if (reduceValue && newTotal >= currentTotal) {
                    continue;
                }
                if (!reduceValue && newTotal <= currentTotal) {
                    continue;
                }
                long distance = Math.abs(newTotal - TARGET_INITIAL_SQUAD_VALUE);
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestOut = out;
                    bestIn = in;
                }
            }
        }

        if (bestOut == null || bestIn == null) {
            return false;
        }

        squad.remove(bestOut);
        squad.add(bestIn);
        return true;
    }

    private static List<SquadCandidate> tryBestPartialSquad(List<SquadCandidate> pool) {
        Map<Position, List<SquadCandidate>> byPosition = groupByPosition(pool);
        Set<Long> used = new HashSet<>();
        Map<Long, Integer> teamCount = new HashMap<>();
        List<SquadCandidate> squad = new ArrayList<>();

        for (Position position : Position.values()) {
            int ideal = IDEAL_QUOTAS.get(position);
            int available = byPosition.getOrDefault(position, List.of()).size();
            int target = Math.min(ideal, available);
            pickBestForPosition(byPosition.getOrDefault(position, List.of()), target, used, teamCount, squad);
        }

        List<SquadCandidate> remaining = new ArrayList<>();
        for (SquadCandidate candidate : pool) {
            if (!used.contains(candidate.leaguePlayerId())) {
                remaining.add(candidate);
            }
        }
        remaining.sort((a, b) -> Long.compare(b.value(), a.value()));
        for (SquadCandidate candidate : remaining) {
            if (squad.size() >= SQUAD_SIZE) {
                break;
            }
            tryAdd(candidate, used, teamCount, squad);
        }

        return squad;
    }

    private static void pickBestForPosition(
            List<SquadCandidate> candidates,
            int count,
            Set<Long> used,
            Map<Long, Integer> teamCount,
            List<SquadCandidate> squad
    ) {
        List<SquadCandidate> sorted = new ArrayList<>(candidates);
        sorted.sort((a, b) -> Long.compare(b.value(), a.value()));
        int picked = 0;
        for (SquadCandidate candidate : sorted) {
            if (picked >= count) {
                return;
            }
            if (tryAdd(candidate, used, teamCount, squad)) {
                picked++;
            }
        }
    }

    private static boolean tryAdd(
            SquadCandidate candidate,
            Set<Long> used,
            Map<Long, Integer> teamCount,
            List<SquadCandidate> squad
    ) {
        if (used.contains(candidate.leaguePlayerId())) {
            return false;
        }
        if (teamCount.getOrDefault(candidate.teamId(), 0) >= MAX_PLAYERS_PER_TEAM) {
            return false;
        }
        used.add(candidate.leaguePlayerId());
        teamCount.put(candidate.teamId(), teamCount.getOrDefault(candidate.teamId(), 0) + 1);
        squad.add(candidate);
        return true;
    }

    private static boolean canAddWithCounts(SquadCandidate candidate, Map<Long, Integer> teamCount) {
        return teamCount.getOrDefault(candidate.teamId(), 0) < MAX_PLAYERS_PER_TEAM;
    }

    private static Map<Long, Integer> teamCountsExcluding(List<SquadCandidate> squad, long excludedLeaguePlayerId) {
        Map<Long, Integer> teamCount = new HashMap<>();
        for (SquadCandidate player : squad) {
            if (player.leaguePlayerId() == excludedLeaguePlayerId) {
                continue;
            }
            teamCount.put(player.teamId(), teamCount.getOrDefault(player.teamId(), 0) + 1);
        }
        return teamCount;
    }

    private static Map<Position, List<SquadCandidate>> groupByPosition(List<SquadCandidate> pool) {
        Map<Position, List<SquadCandidate>> grouped = new EnumMap<>(Position.class);
        for (Position position : Position.values()) {
            grouped.put(position, new ArrayList<>());
        }
        for (SquadCandidate candidate : pool) {
            Position position = Position.fromRaw(candidate.position());
            if (position != null) {
                grouped.get(position).add(candidate);
            }
        }
        return grouped;
    }

    private static long sumValue(List<SquadCandidate> squad) {
        long total = 0L;
        for (SquadCandidate player : squad) {
            total += player.value();
        }
        return total;
    }

    private static boolean isInValueRange(long totalValue) {
        return totalValue >= MIN_INITIAL_SQUAD_VALUE && totalValue <= MAX_INITIAL_SQUAD_VALUE;
    }

    private static double qualityScore(List<SquadCandidate> squad) {
        long total = sumValue(squad);
        double score = Math.abs(total - TARGET_INITIAL_SQUAD_VALUE) / 1_000_000.0;
        score += positionPenalty(squad) / 1_000_000.0;
        double avgRating = squad.stream().mapToInt(SquadCandidate::rating).average().orElse(0.0);
        score -= avgRating * 25_000.0;
        return score;
    }

    private static double positionPenalty(List<SquadCandidate> squad) {
        Map<Position, Integer> counts = new EnumMap<>(Position.class);
        for (Position position : Position.values()) {
            counts.put(position, 0);
        }
        for (SquadCandidate player : squad) {
            Position position = Position.fromRaw(player.position());
            if (position != null) {
                counts.put(position, counts.get(position) + 1);
            }
        }
        long penalty = 0L;
        for (Map.Entry<Position, Integer> entry : IDEAL_QUOTAS.entrySet()) {
            penalty += Math.abs(counts.get(entry.getKey()) - entry.getValue()) * 8_000_000L;
        }
        return penalty;
    }

    private static DraftCandidate toCandidate(List<SquadCandidate> squad, String strategy) {
        return new DraftCandidate(squad, sumValue(squad), qualityScore(squad), strategy);
    }

    private static DraftCandidate better(DraftCandidate current, DraftCandidate candidate) {
        if (current == null) {
            return candidate;
        }
        return candidate.qualityScore() < current.qualityScore() ? candidate : current;
    }

    private static DraftCandidate betterInRange(DraftCandidate current, DraftCandidate candidate) {
        if (current == null) {
            return candidate;
        }
        return candidate.qualityScore() < current.qualityScore() ? candidate : current;
    }

    private static DraftCandidate betterClosestToTarget(DraftCandidate current, DraftCandidate candidate) {
        if (current == null) {
            return candidate;
        }
        long d1 = Math.abs(current.totalValue() - TARGET_INITIAL_SQUAD_VALUE);
        long d2 = Math.abs(candidate.totalValue() - TARGET_INITIAL_SQUAD_VALUE);
        if (d2 != d1) {
            return d2 < d1 ? candidate : current;
        }
        return candidate.qualityScore() < current.qualityScore() ? candidate : current;
    }

    private static SelectionResult toResult(DraftCandidate candidate) {
        List<Long> ids = candidate.squad().stream().map(SquadCandidate::leaguePlayerId).toList();
        return new SelectionResult(ids, candidate.totalValue(), ids.size() < SQUAD_SIZE, candidate.strategy());
    }

    private enum Position {
        POR, DEF, MED, DEL;

        static Position fromRaw(String raw) {
            if (raw == null) {
                return null;
            }
            return switch (raw.trim().toUpperCase()) {
                case "POR" -> POR;
                case "DEF" -> DEF;
                case "MED" -> MED;
                case "DEL" -> DEL;
                default -> null;
            };
        }
    }

    private record DraftCandidate(
            List<SquadCandidate> squad,
            long totalValue,
            double qualityScore,
            String strategy
    ) {
        DraftCandidate withStrategy(String newStrategy) {
            return new DraftCandidate(squad, totalValue, qualityScore, newStrategy);
        }
    }
}
