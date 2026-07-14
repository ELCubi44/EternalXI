package com.eternalxi.eternalxi_api.services;

import org.springframework.stereotype.Service;

@Service
public class LeaguePlayerPricingService {

    /** Suelo absoluto de valor de mercado en liga (no puede bajar por debajo). */
    public static final long ABSOLUTE_MIN_MARKET_VALUE = 500_000L;

    public long calculateInitialValue(int rating, String position) {
        return calculateValueFromDynamicRating(rating, position);
    }

    public long calculateValueFromDynamicRating(double rating, String position) {
        double normalizedRating = clamp(rating, 60.0, 99.0);
        PriceBand band = resolveBand(normalizedRating);

        double ratio;
        if (band.maxRating == band.minRating) {
            ratio = 0.0;
        } else {
            ratio = (normalizedRating - band.minRating) / (band.maxRating - band.minRating);
        }

        double baseValue = band.minValue + ((band.maxValue - band.minValue) * ratio);
        double adjustedValue = baseValue * resolvePositionMultiplier(position);

        long rounded = roundToMarketStep(adjustedValue);
        long floor = getFloorValueForRating(normalizedRating);

        if (rounded < floor) {
            rounded = floor;
        }

        return rounded;
    }

    /**
     * Valoración (OVR de carta en liga) coherente con el precio actual: inversa de
     * {@link #calculateValueFromDynamicRating(double, String)} por posición.
     */
    public double estimateRatingFromMarketValue(long marketValue, String position) {
        String pos = position == null ? "MED" : position;
        double cap = LeagueDynamicValuePolicy.maxFantasyRatingCap(pos);
        long v = Math.max(ABSOLUTE_MIN_MARKET_VALUE, marketValue);
        long valueAtCap = calculateValueFromDynamicRating(cap, pos);
        if (v >= valueAtCap) {
            return cap;
        }
        long valueAt60 = calculateValueFromDynamicRating(60.0, pos);
        if (v <= valueAt60) {
            return 60.0;
        }
        double lo = 60.0;
        double hi = cap;
        for (int i = 0; i < 42; i++) {
            double mid = (lo + hi) / 2.0;
            long pv = calculateValueFromDynamicRating(mid, pos);
            if (pv <= v) {
                lo = mid;
            } else {
                hi = mid;
            }
        }
        double mid = (lo + hi) / 2.0;
        return Math.min(cap, Math.round(mid * 100.0) / 100.0);
    }

    public long getFloorValueForRating(double rating) {
        if (rating >= 90.0) {
            return 100_000_000L;
        }
        if (rating >= 88.0) {
            return 70_000_000L;
        }
        if (rating >= 86.0) {
            return 45_000_000L;
        }
        if (rating >= 84.0) {
            return 25_000_000L;
        }
        if (rating >= 82.0) {
            return 12_000_000L;
        }
        if (rating >= 80.0) {
            return 6_000_000L;
        }
        return 0L;
    }

    private PriceBand resolveBand(double rating) {
        if (rating >= 95.0) {
            return new PriceBand(95.0, 99.0, 180_000_000L, 260_000_000L);
        }
        if (rating >= 93.0) {
            return new PriceBand(93.0, 94.99, 145_000_000L, 180_000_000L);
        }
        if (rating >= 91.0) {
            return new PriceBand(91.0, 92.99, 115_000_000L, 145_000_000L);
        }
        if (rating >= 90.0) {
            return new PriceBand(90.0, 90.99, 100_000_000L, 115_000_000L);
        }
        if (rating >= 88.0) {
            return new PriceBand(88.0, 89.99, 70_000_000L, 95_000_000L);
        }
        if (rating >= 86.0) {
            return new PriceBand(86.0, 87.99, 45_000_000L, 65_000_000L);
        }
        if (rating >= 84.0) {
            return new PriceBand(84.0, 85.99, 25_000_000L, 40_000_000L);
        }
        if (rating >= 82.0) {
            return new PriceBand(82.0, 83.99, 12_000_000L, 22_000_000L);
        }
        if (rating >= 80.0) {
            return new PriceBand(80.0, 81.99, 6_000_000L, 12_000_000L);
        }
        if (rating >= 78.0) {
            return new PriceBand(78.0, 79.99, 3_000_000L, 6_000_000L);
        }
        if (rating >= 76.0) {
            return new PriceBand(76.0, 77.99, 1_500_000L, 3_000_000L);
        }
        return new PriceBand(60.0, 75.99, 400_000L, 1_500_000L);
    }

    private double resolvePositionMultiplier(String position) {
        if (position == null) {
            return 1.0;
        }

        return switch (position.trim().toUpperCase()) {
            case "DEL" -> 1.02;
            case "MED" -> 1.02;
            case "DEF" -> 1.00;
            case "POR" -> 0.96;
            default -> 1.0;
        };
    }

    private long roundToMarketStep(double value) {
        long step;

        if (value >= 20_000_000L) {
            step = 100_000L;
        } else if (value >= 5_000_000L) {
            step = 50_000L;
        } else {
            step = 25_000L;
        }

        return Math.max(ABSOLUTE_MIN_MARKET_VALUE, Math.round(value / (double) step) * step);
    }

    private double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private record PriceBand(
            double minRating,
            double maxRating,
            long minValue,
            long maxValue
    ) {
    }
}