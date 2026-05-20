package com.eternalxi.eternalxi_api.services.rewards;

import com.eternalxi.eternalxi_api.dto.rewards.CardRarity;
import com.eternalxi.eternalxi_api.dto.rewards.LeaguePackCatalogEntryResponse;
import com.eternalxi.eternalxi_api.dto.rewards.RewardPackType;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Configuración centralizada de sobres (coste, presupuesto y pesos de rareza).
 */
public final class RewardPackCatalog {

    private RewardPackCatalog() {}

    public static final int COSTE_RULETA_ENTRENADOR = 1_000;

    public record PackDefinition(
            RewardPackType type,
            String nombre,
            int costePuntos,
            long presupuestoMin,
            long presupuestoMax,
            Map<CardRarity, Integer> rarityWeights
    ) {}

    private static final EnumMap<RewardPackType, PackDefinition> DEFS = new EnumMap<>(RewardPackType.class);

    static {
        DEFS.put(
                RewardPackType.BASIC_PACK,
                new PackDefinition(
                        RewardPackType.BASIC_PACK,
                        "Sobre básico",
                        150,
                        500_000L,
                        2_000_000L,
                        weights(62, 25, 8, 3, 2)
                )
        );
        DEFS.put(
                RewardPackType.COMMON_PACK,
                new PackDefinition(
                        RewardPackType.COMMON_PACK,
                        "Sobre común",
                        400,
                        2_000_000L,
                        5_000_000L,
                        weights(30, 40, 20, 8, 2)
                )
        );
        DEFS.put(
                RewardPackType.PREMIUM_PACK,
                new PackDefinition(
                        RewardPackType.PREMIUM_PACK,
                        "Sobre premium",
                        900,
                        5_000_000L,
                        12_000_000L,
                        weights(5, 15, 35, 30, 15)
                )
        );
    }

    private static Map<CardRarity, Integer> weights(int b, int n, int s, int sr, int l) {
        EnumMap<CardRarity, Integer> m = new EnumMap<>(CardRarity.class);
        m.put(CardRarity.BASIC, b);
        m.put(CardRarity.NORMAL, n);
        m.put(CardRarity.SPECIAL, s);
        m.put(CardRarity.SUPER_RARE, sr);
        m.put(CardRarity.LEGENDARY, l);
        return m;
    }

    public static PackDefinition get(RewardPackType type) {
        PackDefinition d = DEFS.get(type);
        if (d == null) {
            throw new IllegalArgumentException("Tipo de sobre no válido");
        }
        return d;
    }

    public static List<LeaguePackCatalogEntryResponse> catalogEntries() {
        List<LeaguePackCatalogEntryResponse> out = new ArrayList<>();
        for (PackDefinition d : DEFS.values()) {
            Map<String, Integer> probs = new LinkedHashMap<>();
            for (CardRarity r : CardRarity.values()) {
                probs.put(r.name(), d.rarityWeights().getOrDefault(r, 0));
            }
            out.add(new LeaguePackCatalogEntryResponse(
                    d.type().name(),
                    d.nombre(),
                    d.costePuntos(),
                    d.presupuestoMin(),
                    d.presupuestoMax(),
                    probs
            ));
        }
        return out;
    }

    public static CardRarity rollRarity(PackDefinition def) {
        int total = 0;
        for (int w : def.rarityWeights().values()) {
            total += w;
        }
        if (total <= 0) {
            return CardRarity.BASIC;
        }
        int r = ThreadLocalRandom.current().nextInt(total);
        int acc = 0;
        for (Map.Entry<CardRarity, Integer> e : def.rarityWeights().entrySet()) {
            acc += e.getValue();
            if (r < acc) {
                return e.getKey();
            }
        }
        return CardRarity.BASIC;
    }

    public static long rollBudget(PackDefinition def) {
        long lo = def.presupuestoMin();
        long hi = def.presupuestoMax();
        if (hi <= lo) {
            return lo;
        }
        long span = hi - lo;
        return lo + ThreadLocalRandom.current().nextLong(span + 1);
    }
}
