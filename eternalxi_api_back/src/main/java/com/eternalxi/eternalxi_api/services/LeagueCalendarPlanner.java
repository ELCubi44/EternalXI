package com.eternalxi.eternalxi_api.services;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;

/**
 * Planificación de fechas de jornadas al crear una liga.
 * <p>
 * {@code permiteEntresemana} añade bloques martes/miércoles entre jornadas de fin de semana;
 * el fin de semana nunca desaparece y la jornada 1 siempre es de fin de semana.
 */
public final class LeagueCalendarPlanner {

    private static final LocalTime[] MIDWEEK_SLOT_TIMES = {
            LocalTime.of(17, 0), LocalTime.of(18, 30), LocalTime.of(20, 0), LocalTime.of(21, 30),
            LocalTime.of(17, 0), LocalTime.of(18, 30), LocalTime.of(20, 0), LocalTime.of(21, 30),
    };
    private static final int[] MIDWEEK_SLOT_DAY_OFFSET = {0, 0, 0, 0, 1, 1, 1, 1};

    private static final LocalTime[] WEEKEND_SLOT_TIMES = {
            LocalTime.of(17, 0), LocalTime.of(19, 0),
            LocalTime.of(17, 0), LocalTime.of(19, 0), LocalTime.of(21, 0),
            LocalTime.of(17, 0), LocalTime.of(19, 0), LocalTime.of(21, 0),
    };
    private static final int[] WEEKEND_SLOT_DAY_OFFSET = {0, 0, 1, 1, 1, 2, 2, 2};

    private LeagueCalendarPlanner() {
    }

    public record RoundBlock(LocalDate anchor, boolean midweek) {
    }

    public record PlannedCalendar(List<RoundBlock> rounds, LocalDate finLigaEn) {
    }

    public static PlannedCalendar plan(
            LocalDate creationDate,
            int totalRounds,
            boolean permiteEntresemana,
            boolean semanaPreviaFichajes
    ) {
        if (totalRounds <= 0) {
            throw new IllegalArgumentException("totalRounds debe ser positivo");
        }

        LocalDate firstWeekendFriday = calculateFirstWeekendFriday(creationDate);
        if (semanaPreviaFichajes) {
            firstWeekendFriday = firstWeekendFriday.plusWeeks(1);
        }

        List<RoundBlock> blocks = new ArrayList<>(totalRounds);
        for (int roundIndex = 0; roundIndex < totalRounds; roundIndex++) {
            blocks.add(resolveRoundBlock(roundIndex, firstWeekendFriday, permiteEntresemana));
        }

        RoundBlock last = blocks.get(blocks.size() - 1);
        LocalDate finLigaEn = roundEndDate(last.anchor(), last.midweek());
        return new PlannedCalendar(blocks, finLigaEn);
    }

    /**
     * Primer viernes de jornada competitiva (la jornada 1 siempre usa este ancla de fin de semana).
     */
    public static LocalDate calculateFirstWeekendFriday(LocalDate creationDate) {
        if (creationDate.getDayOfWeek() == DayOfWeek.SUNDAY) {
            return creationDate.with(TemporalAdjusters.next(DayOfWeek.FRIDAY));
        }
        return creationDate.with(TemporalAdjusters.next(DayOfWeek.FRIDAY)).plusWeeks(1);
    }

    static RoundBlock resolveRoundBlock(int roundIndex, LocalDate firstWeekendFriday, boolean permiteEntresemana) {
        if (!permiteEntresemana) {
            return new RoundBlock(firstWeekendFriday.plusWeeks(roundIndex), false);
        }
        if (roundIndex % 2 == 0) {
            return new RoundBlock(firstWeekendFriday.plusWeeks(roundIndex / 2), false);
        }
        return new RoundBlock(firstWeekendFriday.plusWeeks(roundIndex / 2).plusDays(4), true);
    }

    static LocalDate roundEndDate(LocalDate anchor, boolean midweek) {
        return midweek ? anchor.plusDays(1) : anchor.plusDays(2);
    }

    public static List<LocalDateTime> buildKickoffSlots(LocalDate anchor, boolean midweek, int matchCount) {
        List<LocalDateTime> base = buildBaseSlots(anchor, midweek);
        return assignKickoffsCircular(base, matchCount);
    }

    static List<LocalDateTime> buildBaseSlots(LocalDate anchor, boolean midweek) {
        List<LocalDateTime> slots = new ArrayList<>(8);
        if (midweek) {
            for (int i = 0; i < MIDWEEK_SLOT_TIMES.length; i++) {
                LocalDate day = anchor.plusDays(MIDWEEK_SLOT_DAY_OFFSET[i]);
                slots.add(LocalDateTime.of(day, MIDWEEK_SLOT_TIMES[i]));
            }
        } else {
            for (int i = 0; i < WEEKEND_SLOT_TIMES.length; i++) {
                LocalDate day = anchor.plusDays(WEEKEND_SLOT_DAY_OFFSET[i]);
                slots.add(LocalDateTime.of(day, WEEKEND_SLOT_TIMES[i]));
            }
        }
        return slots;
    }

    static List<LocalDateTime> assignKickoffsCircular(List<LocalDateTime> baseSlots, int matchCount) {
        List<LocalDateTime> kickoffs = new ArrayList<>(matchCount);
        for (int i = 0; i < matchCount; i++) {
            kickoffs.add(baseSlots.get(i % baseSlots.size()));
        }
        return kickoffs;
    }

    public static boolean isWeekendKickoff(LocalDateTime kickoff) {
        DayOfWeek day = kickoff.getDayOfWeek();
        return day == DayOfWeek.FRIDAY || day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
    }

    public static boolean isMidweekKickoff(LocalDateTime kickoff) {
        DayOfWeek day = kickoff.getDayOfWeek();
        return day == DayOfWeek.TUESDAY || day == DayOfWeek.WEDNESDAY;
    }
}
