package com.eternalxi.eternalxi_api.services;

/**
 * Curvas de valor dinámico (fantasy → precio de mercado). Extraído para pruebas y rebalanceo.
 * <p>
 * Diseño (v2, ligas maduras): par ajustado por posición (DEL≈MED), subidas de baratos más
 * contenidas, fatiga reduce el índice de rendimiento y la ventana de forma usa más partidos.
 */
public final class LeagueDynamicValuePolicy {

    /** Partidos recientes considerados para la media de forma (alineado con SQL en simulación). */
    public static final int RECENT_FORM_MATCH_LIMIT = 5;

    private LeagueDynamicValuePolicy() {
    }

    public static double fantasyParMeanPointsFromMarket(long currentValue) {
        return fantasyParMeanPointsFromMarket(currentValue, null);
    }

    /**
     * Par de puntos fantasy esperado según precio y posición.
     * DEL y MED comparten expectativa similar; DEF/POR compensan su reparto de puntos.
     */
    public static double fantasyParMeanPointsFromMarket(long currentValue, String position) {
        double mMillions = Math.max(
                LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE / 1_000_000.0,
                currentValue / 1_000_000.0);
        double par;
        if (mMillions >= 120.0) {
            par = 9.85;
        } else if (mMillions >= 100.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 100.0, 8.10, 120.0, 9.85);
        } else if (mMillions >= 90.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 90.0, 7.45, 100.0, 8.10);
        } else if (mMillions >= 70.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 70.0, 7.15, 90.0, 7.45);
        } else if (mMillions >= 50.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 50.0, 5.85, 70.0, 7.15);
        } else if (mMillions >= 10.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 10.0, 5.10, 50.0, 5.85);
        } else if (mMillions >= 2.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 2.0, 3.25, 10.0, 5.10);
        } else {
            double mLo = LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE / 1_000_000.0;
            par = lerpFantasyParAcrossMillions(mMillions, mLo, 3.05, 2.0, 3.25);
        }
        par = clamp(par * positionParMultiplier(position), 2.85, maxParPointsForPosition(position));
        return par;
    }

    /**
     * Techo de par de puntos (porteros acumulan más por paradas/portería a cero).
     */
    public static double maxParPointsForPosition(String position) {
        if (isPosition(position, "POR")) {
            return 13.5;
        }
        return 10.15;
    }

    /**
     * Multiplicador del par según posición.
     * POR necesita par alto: en simulación suman muchos puntos por paradas y portería a cero.
     */
    public static double positionParMultiplier(String position) {
        if (position == null) {
            return 1.0;
        }
        return switch (position.trim().toUpperCase()) {
            case "DEL" -> 0.98;
            case "MED" -> 1.00;
            case "DEF" -> 1.06;
            case "POR" -> 1.80;
            default -> 1.0;
        };
    }

    /**
     * Techo de OVR dinámico por posición (evita que todos los porteros acaben en 99).
     */
    public static double maxFantasyRatingCap(String position) {
        if (position == null) {
            return 99.0;
        }
        return switch (position.trim().toUpperCase()) {
            case "POR" -> 95.0;
            case "DEF" -> 97.0;
            default -> 99.0;
        };
    }

    /**
     * Escala de sensibilidad al mover valoración (porteros más estables).
     */
    public static double positionSensitivityScale(String position) {
        if (position == null) {
            return 1.0;
        }
        return switch (position.trim().toUpperCase()) {
            case "POR" -> 0.62;
            case "DEF" -> 0.88;
            default -> 1.0;
        };
    }

    public static double sensitivityByMarketProfile(long currentValue, double ovrRating, String position) {
        return sensitivityByMarketProfile(currentValue, ovrRating)
                * positionSensitivityScale(position);
    }

    /**
     * Fatiga alta reduce el índice de rendimiento (jugador agotado rinde peor en mercado).
     */
    public static double fatiguePerformanceModifier(int cansancio) {
        if (cansancio <= 0) {
            return 1.0;
        }
        double normalized = Math.min(100, Math.max(0, cansancio)) / 100.0;
        return 1.0 - Math.pow(normalized, 1.2) * 0.14;
    }

    public static double sensitivityByMarketProfile(long currentValue, double ovrRating) {
        double ovr = clamp(ovrRating, 55.0, 99.0);
        double s;
        if (currentValue < 2_000_000L) {
            s = 0.20;
        } else if (currentValue < 5_000_000L) {
            s = 0.18;
        } else if (currentValue < 10_000_000L) {
            s = 0.155;
        } else if (currentValue < 25_000_000L) {
            s = 0.125;
        } else if (currentValue < 60_000_000L) {
            s = 0.102;
        } else if (currentValue < 100_000_000L) {
            s = 0.085;
        } else {
            s = 0.070;
        }

        if (ovr >= 95.0) {
            s *= ovrDampFactor(currentValue, 0.42);
        } else if (ovr >= 93.0) {
            s *= ovrDampFactor(currentValue, 0.58);
        } else if (ovr >= 91.0) {
            s *= ovrDampFactor(currentValue, 0.72);
        } else if (ovr >= 89.0) {
            s *= ovrDampFactor(currentValue, 0.82);
        }

        if (currentValue < 10_000_000L) {
            s = Math.min(0.27, s * 1.08);
        }
        return s;
    }

  /**
     * En jugadores baratos el techo OVR frena menos la subida (canteranos baratos con buen rendimiento).
     */
    public static double maxPositiveDeltaRatingByOvr(double ovrRating, long currentValue) {
        double ovr = clamp(ovrRating, 55.0, 99.0);
        double maxUp;
        if (ovr >= 95.0) {
            maxUp = 0.050;
        } else if (ovr >= 93.0) {
            maxUp = 0.078;
        } else if (ovr >= 91.0) {
            maxUp = 0.11;
        } else if (ovr >= 88.0) {
            maxUp = 0.20;
        } else if (ovr >= 84.0) {
            maxUp = 0.28;
        } else {
            maxUp = 0.44;
        }

        if (currentValue < 2_000_000L) {
            maxUp = Math.max(maxUp, 0.48);
        } else if (currentValue < 5_000_000L) {
            maxUp = Math.max(maxUp, 0.42);
        } else if (currentValue < 10_000_000L) {
            maxUp = Math.max(maxUp, 0.36);
        } else if (currentValue < 25_000_000L) {
            maxUp = Math.max(maxUp, 0.32);
        }
        return maxUp;
    }

    public static double boostPositiveDeltaRating(double deltaRating, double maxUp, long currentValue) {
        if (deltaRating <= 0) {
            return deltaRating;
        }
        double boost = 1.0;
        if (currentValue < 2_000_000L) {
            boost = 1.14;
        } else if (currentValue < 5_000_000L) {
            boost = 1.10;
        } else if (currentValue < 10_000_000L) {
            boost = 1.07;
        } else if (currentValue < 25_000_000L) {
            boost = 1.04;
        }
        return Math.min(maxUp, deltaRating * boost);
    }

    public static double formMultiplier(double performanceIndex, long currentValue) {
        double base = baseFormMultiplier(performanceIndex);
        if (performanceIndex <= 10.25 || currentValue >= 25_000_000L) {
            return base;
        }
        double bargainBoost = 1.0;
        if (currentValue < 2_000_000L) {
            bargainBoost = 1.014;
        } else if (currentValue < 5_000_000L) {
            bargainBoost = 1.010;
        } else if (currentValue < 10_000_000L) {
            bargainBoost = 1.006;
        } else if (currentValue < 25_000_000L) {
            bargainBoost = 1.004;
        }
        return base * bargainBoost;
    }

    public static double maxPositiveDeltaRatingByOvr(double ovrRating, long currentValue, String position) {
        double maxUp = maxPositiveDeltaRatingByOvr(ovrRating, currentValue);
        double cap = maxFantasyRatingCap(position);
        if (ovrRating >= cap - 0.25) {
            maxUp *= 0.30;
        } else if (ovrRating >= cap - 1.5) {
            maxUp *= 0.50;
        } else if (ovrRating >= cap - 3.0) {
            maxUp *= 0.72;
        }
        return maxUp;
    }

    public static double movementLimitPercentage(long currentValue, boolean rising, String position) {
        double base = movementLimitPercentage(currentValue, rising);
        if (rising && isPosition(position, "POR")) {
            return base * 0.82;
        }
        return base;
    }

    private static boolean isPosition(String position, String expected) {
        return position != null && expected.equalsIgnoreCase(position.trim());
    }

    public static double movementLimitPercentage(long currentValue, boolean rising) {
        if (!rising) {
            return movementLimitPercentageFall(currentValue);
        }
        if (currentValue >= 150_000_000L) {
            return 0.028;
        }
        if (currentValue >= 100_000_000L) {
            return 0.026;
        }
        if (currentValue >= 70_000_000L) {
            return 0.024;
        }
        if (currentValue >= 40_000_000L) {
            return 0.023;
        }
        if (currentValue >= 25_000_000L) {
            return 0.022;
        }
        if (currentValue >= 15_000_000L) {
            return 0.020;
        }
        if (currentValue >= 10_000_000L) {
            return 0.019;
        }
        if (currentValue >= 5_000_000L) {
            return 0.036;
        }
        if (currentValue >= 2_000_000L) {
            return 0.044;
        }
        return 0.048;
    }

    public static long movementCapByValue(long currentValue, boolean rising) {
        long cap = movementCapByValueFall(currentValue);
        if (!rising) {
            return cap;
        }
        if (currentValue < 2_000_000L) {
            return Math.max(cap, 380_000L);
        }
        if (currentValue < 5_000_000L) {
            return Math.max(cap, 480_000L);
        }
        if (currentValue < 10_000_000L) {
            return Math.max(cap, 580_000L);
        }
        if (currentValue < 25_000_000L) {
            return Math.max(cap, 720_000L);
        }
        return cap;
    }

    public static long moveTowards(long currentValue, long targetValue, double limitPercentage) {
        long minV = LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE;
        if (currentValue <= 0) {
            return Math.max(targetValue, minV);
        }

        boolean rising = targetValue > currentValue;
        long maxByPercent = Math.max(minV, Math.round(currentValue * limitPercentage));
        long maxByCap = movementCapByValue(currentValue, rising);
        long maxDelta = Math.min(maxByPercent, maxByCap);

        if (rising) {
            long delta = Math.min(targetValue - currentValue, maxDelta);
            return currentValue + delta;
        }

        long delta = Math.min(currentValue - targetValue, maxDelta);
        return Math.max(minV, currentValue - delta);
    }

    private static double movementLimitPercentageFall(long currentValue) {
        if (currentValue >= 150_000_000L) {
            return 0.030;
        }
        if (currentValue >= 100_000_000L) {
            return 0.028;
        }
        if (currentValue >= 70_000_000L) {
            return 0.026;
        }
        if (currentValue >= 40_000_000L) {
            return 0.024;
        }
        if (currentValue >= 25_000_000L) {
            return 0.022;
        }
        if (currentValue >= 15_000_000L) {
            return 0.020;
        }
        if (currentValue >= 10_000_000L) {
            return 0.018;
        }
        if (currentValue >= 5_000_000L) {
            return 0.022;
        }
        if (currentValue >= 2_000_000L) {
            return 0.028;
        }
        return 0.036;
    }

    private static long movementCapByValueFall(long currentValue) {
        if (currentValue >= 150_000_000L) {
            return 4_500_000L;
        }
        if (currentValue >= 100_000_000L) {
            return 3_600_000L;
        }
        if (currentValue >= 70_000_000L) {
            return 2_800_000L;
        }
        if (currentValue >= 40_000_000L) {
            return 2_000_000L;
        }
        if (currentValue >= 25_000_000L) {
            return 1_400_000L;
        }
        if (currentValue >= 15_000_000L) {
            return 900_000L;
        }
        if (currentValue >= 10_000_000L) {
            return 650_000L;
        }
        if (currentValue >= 5_000_000L) {
            return 350_000L;
        }
        if (currentValue >= 2_000_000L) {
            return 220_000L;
        }
        return 260_000L;
    }

    private static double baseFormMultiplier(double performanceIndex) {
        if (performanceIndex <= 7.0) {
            return 0.985;
        }
        if (performanceIndex <= 8.5) {
            return 0.993;
        }
        if (performanceIndex <= 9.75) {
            return 0.998;
        }
        if (performanceIndex <= 10.25) {
            return 1.000;
        }
        if (performanceIndex <= 11.5) {
            return 1.006;
        }
        if (performanceIndex <= 13.25) {
            return 1.012;
        }
        if (performanceIndex <= 15.25) {
            return 1.018;
        }
        if (performanceIndex <= 17.25) {
            return 1.024;
        }
        if (performanceIndex <= 19.0) {
            return 1.030;
        }
        return 1.038;
    }

    /**
     * En baratos, el multiplicador OVR (freno) se acerca a 1 para no bloquear promesas económicas.
     */
    private static double ovrDampFactor(long currentValue, double fullDamp) {
        if (currentValue >= 25_000_000L) {
            return fullDamp;
        }
        double blend = currentValue < 5_000_000L ? 0.35 : 0.55;
        return 1.0 - (1.0 - fullDamp) * blend;
    }

    private static double lerpFantasyParAcrossMillions(
            double mMillions,
            double m0,
            double par0,
            double m1,
            double par1
    ) {
        if (m1 <= m0) {
            return par0;
        }
        double t = (mMillions - m0) / (m1 - m0);
        t = Math.max(0.0, Math.min(1.0, t));
        return par0 + t * (par1 - par0);
    }

    private static double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }
}
