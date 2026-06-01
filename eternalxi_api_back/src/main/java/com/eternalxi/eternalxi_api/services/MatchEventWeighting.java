package com.eternalxi.eternalxi_api.services;

/**
 * Pesos para repartir eventos de partido (regates, recuperaciones, paradas) según valoración.
 */
public final class MatchEventWeighting {

    static final double ATTACKER_EVENT_QUALITY_EXPONENT = 2.38;
    static final double DEFENSIVE_EVENT_QUALITY_EXPONENT = 1.82;
    static final double EVENT_RATING_BLEND_WEIGHT = 0.24;
    static final double QUALITY_IMPACT_MULTIPLIER = 1.30;

    private MatchEventWeighting() {
    }

    static double eventQualityScore(double selectionScore, double valoracionActual) {
        double ovr = clamp(valoracionActual, 60.0, 99.0);
        double blended = selectionScore * (1.0 - EVENT_RATING_BLEND_WEIGHT) + ovr * EVENT_RATING_BLEND_WEIGHT;
        if (ovr >= 84.0) {
            blended += (ovr - 84.0) * 0.07;
        }
        return blended;
    }

    static double pickWeight(
            double selectionScore,
            double valoracionActual,
            String posicion,
            boolean attackerProfile
    ) {
        double normalizedQuality = clamp(
                (eventQualityScore(selectionScore, valoracionActual) * QUALITY_IMPACT_MULTIPLIER) / 100.0,
                0.35,
                1.30
        );
        if (attackerProfile) {
            double positionWeight = switch (posicion == null ? "" : posicion) {
                case "DEL" -> 1.00;
                case "MED" -> 0.45;
                case "DEF" -> 0.12;
                case "POR" -> 0.01;
                default -> 0.08;
            };
            return Math.max(1.0, positionWeight * Math.pow(normalizedQuality, ATTACKER_EVENT_QUALITY_EXPONENT) * 10000.0);
        }
        double positionWeight = switch (posicion == null ? "" : posicion) {
            case "DEF" -> 1.40;
            case "MED" -> 1.08;
            case "POR" -> 0.90;
            case "DEL" -> 0.55;
            default -> 0.72;
        };
        return Math.max(1.0, positionWeight * Math.pow(normalizedQuality, DEFENSIVE_EVENT_QUALITY_EXPONENT) * 9000.0);
    }

    static double saveEventChance(double valoracionPortero, double baseChance) {
        double ovr = clamp(valoracionPortero, 60.0, 99.0);
        double bonus = Math.max(0.0, (ovr - 74.0) * 0.0035);
        return clamp(baseChance + bonus, 0.88, 0.96);
    }

    private static double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }
}
