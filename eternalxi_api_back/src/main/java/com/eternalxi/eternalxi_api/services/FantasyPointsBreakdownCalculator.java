package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.league.FantasyPointsBreakdownResponse;

/**
 * Única fuente de verdad para puntos fantasy y su desglose (simulación y lecturas API).
 */
public final class FantasyPointsBreakdownCalculator {

    private FantasyPointsBreakdownCalculator() {
    }

    public record Input(
            String posicion,
            int minutesPlayed,
            int goals,
            int assists,
            int dribbles,
            int recoveries,
            int saves,
            int goalsConceded,
            int yellowCards,
            int redCards,
            boolean injuredInMatch,
            /**
             * Nota de periódico persistida (1–5). {@code null} en directo sin nota → contribución 0
             * (equivalente a nota base 3 en la fórmula legacy).
             */
            Integer newspaperNotePersisted
    ) {
    }

    public record Breakdown(
            int minutos,
            int goles,
            int asistencias,
            int regates,
            int recuperaciones,
            int paradas,
            int porteriaCero,
            int golesEncajados,
            int notaPeriodico,
            int amarillas,
            int rojas,
            int lesion
    ) {
        public int total() {
            return minutos
                    + goles
                    + asistencias
                    + regates
                    + recuperaciones
                    + paradas
                    + porteriaCero
                    + golesEncajados
                    + notaPeriodico
                    + amarillas
                    + rojas
                    + lesion;
        }
    }

    public static Breakdown calculate(Input in) {
        String pos = in.posicion() == null ? "" : in.posicion();

        int minutos = 0;
        if (in.minutesPlayed() > 0) {
            minutos += 2;
        }
        if (in.minutesPlayed() >= 60) {
            minutos += 1;
        }

        int goles = switch (pos) {
            case "POR" -> in.goals() * 12;
            case "DEF" -> in.goals() * 10;
            case "MED" -> in.goals() * 7;
            case "DEL" -> in.goals() * 5;
            default -> in.goals() * 5;
        };

        int asistencias = in.assists() * 4;

        int regates = switch (pos) {
            case "POR" -> 0;
            case "DEF" -> in.dribbles() / 4;
            case "MED", "DEL" -> in.dribbles() / 3;
            default -> in.dribbles() / 3;
        };

        int recuperaciones = switch (pos) {
            case "POR" -> in.recoveries() / 5;
            case "DEF", "MED" -> in.recoveries() / 3;
            case "DEL" -> in.recoveries() / 5;
            default -> in.recoveries() / 5;
        };

        int paradas = "POR".equals(pos) ? in.saves() / 2 : 0;

        int porteriaCero = 0;
        if (in.minutesPlayed() >= 60 && in.goalsConceded() == 0) {
            if ("POR".equals(pos)) {
                porteriaCero = 5;
            } else if ("DEF".equals(pos)) {
                porteriaCero = 4;
            }
        }

        int golesEncajados = 0;
        if ("POR".equals(pos)) {
            golesEncajados = -(in.goalsConceded() / 2);
        } else if ("DEF".equals(pos) && in.goalsConceded() >= 2) {
            golesEncajados = -(in.goalsConceded() / 2);
        }

        int note = in.newspaperNotePersisted() == null ? 3 : in.newspaperNotePersisted();
        int notaPeriodico = (note - 3) * 2;

        int amarillas = in.yellowCards() > 0 ? -in.yellowCards() : 0;
        int rojas = in.redCards() > 0 ? -in.redCards() * 2 : 0;
        int lesion = in.injuredInMatch() ? -1 : 0;

        return new Breakdown(
                minutos,
                goles,
                asistencias,
                regates,
                recuperaciones,
                paradas,
                porteriaCero,
                golesEncajados,
                notaPeriodico,
                amarillas,
                rojas,
                lesion
        );
    }

    public static int totalPoints(Input in) {
        return calculate(in).total();
    }

    public static FantasyPointsBreakdownResponse toResponse(Breakdown b) {
        return new FantasyPointsBreakdownResponse(
                b.minutos(),
                b.goles(),
                b.asistencias(),
                b.regates(),
                b.recuperaciones(),
                b.paradas(),
                b.porteriaCero(),
                b.golesEncajados(),
                b.notaPeriodico(),
                b.amarillas(),
                b.rojas(),
                b.lesion(),
                b.total()
        );
    }
}
