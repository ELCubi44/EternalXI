package com.eternalxi.eternalxi_api.services;

import org.junit.jupiter.api.Test;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LeagueCalendarPlannerTest {

    private static final LocalDate CREATION = LocalDate.of(2026, 5, 11);

    @Test
    void permiteEntresemanaFalse_todasLasJornadasSonFinDeSemana() {
        int rounds = 6;
        LeagueCalendarPlanner.PlannedCalendar plan = LeagueCalendarPlanner.plan(
                CREATION, rounds, false, false
        );

        assertEquals(rounds, plan.rounds().size());
        for (LeagueCalendarPlanner.RoundBlock block : plan.rounds()) {
            assertFalse(block.midweek());
            List<LocalDateTime> kickoffs = LeagueCalendarPlanner.buildKickoffSlots(
                    block.anchor(), false, 9
            );
            for (LocalDateTime kickoff : kickoffs) {
                assertTrue(LeagueCalendarPlanner.isWeekendKickoff(kickoff), kickoff::toString);
            }
        }
    }

    @Test
    void permiteEntresemanaTrue_alternaFindeYEntresemana() {
        int rounds = 6;
        LeagueCalendarPlanner.PlannedCalendar plan = LeagueCalendarPlanner.plan(
                CREATION, rounds, true, false
        );

        assertEquals(rounds, plan.rounds().size());
        assertFalse(plan.rounds().get(0).midweek());
        assertTrue(plan.rounds().get(1).midweek());
        assertFalse(plan.rounds().get(2).midweek());
        assertTrue(plan.rounds().get(3).midweek());

        for (int i = 0; i < rounds; i++) {
            LeagueCalendarPlanner.RoundBlock block = plan.rounds().get(i);
            List<LocalDateTime> kickoffs = LeagueCalendarPlanner.buildKickoffSlots(
                    block.anchor(), block.midweek(), 9
            );
            for (LocalDateTime kickoff : kickoffs) {
                if (block.midweek()) {
                    assertTrue(LeagueCalendarPlanner.isMidweekKickoff(kickoff), kickoff::toString);
                } else {
                    assertTrue(LeagueCalendarPlanner.isWeekendKickoff(kickoff), kickoff::toString);
                }
            }
        }
    }

    @Test
    void primeraJornadaSiempreEsFinDeSemana() {
        for (boolean entresemana : List.of(false, true)) {
            for (boolean semanaPrevia : List.of(false, true)) {
                LeagueCalendarPlanner.PlannedCalendar plan = LeagueCalendarPlanner.plan(
                        CREATION, 4, entresemana, semanaPrevia
                );
                LeagueCalendarPlanner.RoundBlock first = plan.rounds().get(0);
                assertFalse(first.midweek());
                assertEquals(DayOfWeek.FRIDAY, first.anchor().getDayOfWeek());
            }
        }
    }

    @Test
    void permiteEntresemanaTrue_noTodasLasJornadasSonEntresemana() {
        LeagueCalendarPlanner.PlannedCalendar plan = LeagueCalendarPlanner.plan(
                CREATION, 8, true, false
        );

        long weekendRounds = plan.rounds().stream().filter(b -> !b.midweek()).count();
        long midweekRounds = plan.rounds().stream().filter(LeagueCalendarPlanner.RoundBlock::midweek).count();

        assertTrue(weekendRounds >= 4);
        assertTrue(midweekRounds >= 3);
        assertFalse(midweekRounds == plan.rounds().size());
    }

    @Test
    void semanaPreviaFichajes_retrasaPrimeraJornadaUnaSemana() {
        LeagueCalendarPlanner.PlannedCalendar sinPrevia = LeagueCalendarPlanner.plan(
                CREATION, 3, false, false
        );
        LeagueCalendarPlanner.PlannedCalendar conPrevia = LeagueCalendarPlanner.plan(
                CREATION, 3, false, true
        );

        assertEquals(
                sinPrevia.rounds().get(0).anchor().plusWeeks(1),
                conPrevia.rounds().get(0).anchor()
        );
    }

    @Test
    void semanaPreviaConEntresemana_jornada2PuedeSerMartesMiercoles() {
        LeagueCalendarPlanner.PlannedCalendar plan = LeagueCalendarPlanner.plan(
                CREATION, 4, true, true
        );

        assertFalse(plan.rounds().get(0).midweek());
        assertTrue(plan.rounds().get(1).midweek());
        assertEquals(DayOfWeek.TUESDAY, plan.rounds().get(1).anchor().getDayOfWeek());

        Set<DayOfWeek> days = new HashSet<>();
        for (LocalDateTime kickoff : LeagueCalendarPlanner.buildKickoffSlots(
                plan.rounds().get(1).anchor(), true, 6
        )) {
            days.add(kickoff.getDayOfWeek());
        }
        assertTrue(days.contains(DayOfWeek.TUESDAY));
        assertTrue(days.contains(DayOfWeek.WEDNESDAY));
    }
}
