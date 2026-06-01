package com.eternalxi.eternalxi_api.services;

/**
 * Curvas de valor dinámico (fantasy → precio de mercado). Extraído para pruebas y rebalanceo.
 * <p>
 * Diseño: fichajes baratos suben con más facilidad si rinden por encima del par; cracks caros
 * mantienen subidas/bajadas amortiguadas.
 */
public final class LeagueDynamicValuePolicy {

    private LeagueDynamicValuePolicy() {
    }

    public static double fantasyParMeanPointsFromMarket(long currentValue) {
        double mMillions = Math.max(
                LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE / 1_000_000.0,
                currentValue / 1_000_000.0);
        double par;
        if (mMillions >= 120.0) {
            par = 10.2;
        } else if (mMillions >= 100.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 100.0, 8.35, 120.0, 10.2);
        } else if (mMillions >= 90.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 90.0, 7.65, 100.0, 8.35);
        } else if (mMillions >= 70.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 70.0, 7.35, 90.0, 7.65);
        } else if (mMillions >= 50.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 50.0, 6.0, 70.0, 7.35);
        } else if (mMillions >= 10.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 10.0, 5.25, 50.0, 6.0);
        } else if (mMillions >= 2.0) {
            par = lerpFantasyParAcrossMillions(mMillions, 2.0, 3.35, 10.0, 5.25);
        } else {
            double mLo = LeaguePlayerPricingService.ABSOLUTE_MIN_MARKET_VALUE / 1_000_000.0;
            par = lerpFantasyParAcrossMillions(mMillions, mLo, 3.15, 2.0, 3.35);
        }
        return clamp(par, 3.15, 10.35);
    }

    public static double sensitivityByMarketProfile(long currentValue, double ovrRating) {
        double ovr = clamp(ovrRating, 55.0, 99.0);
        double s;
        if (currentValue < 2_000_000L) {
            s = 0.24;
        } else if (currentValue < 5_000_000L) {
            s = 0.21;
        } else if (currentValue < 10_000_000L) {
            s = 0.175;
        } else if (currentValue < 25_000_000L) {
            s = 0.135;
        } else if (currentValue < 60_000_000L) {
            s = 0.108;
        } else if (currentValue < 100_000_000L) {
            s = 0.088;
        } else {
            s = 0.072;
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
            s = Math.min(0.32, s * 1.12);
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
            maxUp = 0.055;
        } else if (ovr >= 93.0) {
            maxUp = 0.085;
        } else if (ovr >= 91.0) {
            maxUp = 0.12;
        } else if (ovr >= 88.0) {
            maxUp = 0.22;
        } else if (ovr >= 84.0) {
            maxUp = 0.32;
        } else {
            maxUp = 0.50;
        }

        if (currentValue < 2_000_000L) {
            maxUp = Math.max(maxUp, 0.58);
        } else if (currentValue < 5_000_000L) {
            maxUp = Math.max(maxUp, 0.50);
        } else if (currentValue < 10_000_000L) {
            maxUp = Math.max(maxUp, 0.42);
        } else if (currentValue < 25_000_000L) {
            maxUp = Math.max(maxUp, 0.36);
        }
        return maxUp;
    }

    public static double boostPositiveDeltaRating(double deltaRating, double maxUp, long currentValue) {
        if (deltaRating <= 0) {
            return deltaRating;
        }
        double boost = 1.0;
        if (currentValue < 2_000_000L) {
            boost = 1.28;
        } else if (currentValue < 5_000_000L) {
            boost = 1.20;
        } else if (currentValue < 10_000_000L) {
            boost = 1.14;
        } else if (currentValue < 25_000_000L) {
            boost = 1.08;
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
            bargainBoost = 1.022;
        } else if (currentValue < 5_000_000L) {
            bargainBoost = 1.016;
        } else if (currentValue < 10_000_000L) {
            bargainBoost = 1.010;
        } else if (currentValue < 25_000_000L) {
            bargainBoost = 1.006;
        }
        return base * bargainBoost;
    }

    public static double movementLimitPercentage(long currentValue, boolean rising) {
        if (!rising) {
            return movementLimitPercentageFall(currentValue);
        }
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
            return 0.023;
        }
        if (currentValue >= 15_000_000L) {
            return 0.021;
        }
        if (currentValue >= 10_000_000L) {
            return 0.020;
        }
        if (currentValue >= 5_000_000L) {
            return 0.042;
        }
        if (currentValue >= 2_000_000L) {
            return 0.050;
        }
        return 0.058;
    }

    public static long movementCapByValue(long currentValue, boolean rising) {
        long cap = movementCapByValueFall(currentValue);
        if (!rising) {
            return cap;
        }
        if (currentValue < 2_000_000L) {
            return Math.max(cap, 450_000L);
        }
        if (currentValue < 5_000_000L) {
            return Math.max(cap, 550_000L);
        }
        if (currentValue < 10_000_000L) {
            return Math.max(cap, 650_000L);
        }
        if (currentValue < 25_000_000L) {
            return Math.max(cap, 800_000L);
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
        return 0.038;
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
        return 280_000L;
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
            return 1.007;
        }
        if (performanceIndex <= 13.25) {
            return 1.014;
        }
        if (performanceIndex <= 15.25) {
            return 1.022;
        }
        if (performanceIndex <= 17.25) {
            return 1.030;
        }
        if (performanceIndex <= 19.0) {
            return 1.038;
        }
        return 1.048;
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
