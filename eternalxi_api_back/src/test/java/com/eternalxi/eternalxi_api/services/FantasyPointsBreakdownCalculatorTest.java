package com.eternalxi.eternalxi_api.services;

import com.eternalxi.eternalxi_api.dto.league.FantasyPointsBreakdownResponse;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class FantasyPointsBreakdownCalculatorTest {

    private static FantasyPointsBreakdownCalculator.Input porteroInput(int saves) {
        return new FantasyPointsBreakdownCalculator.Input(
                "POR",
                90,
                0,
                0,
                0,
                0,
                saves,
                0,
                0,
                0,
                false,
                3
        );
    }

    @Test
    void porteroSieteParadasSumaTresPuntos() {
        FantasyPointsBreakdownCalculator.Breakdown b =
                FantasyPointsBreakdownCalculator.calculate(porteroInput(7));
        assertEquals(3, b.paradas());
        assertEquals(b.total(), FantasyPointsBreakdownCalculator.totalPoints(porteroInput(7)));
    }

    @Test
    void porteroOchoParadasSumaCuatroPuntos() {
        FantasyPointsBreakdownCalculator.Breakdown b =
                FantasyPointsBreakdownCalculator.calculate(porteroInput(8));
        assertEquals(4, b.paradas());
    }

    @Test
    void toResponseTotalCoincideConPuntos() {
        FantasyPointsBreakdownCalculator.Breakdown b =
                FantasyPointsBreakdownCalculator.calculate(porteroInput(7));
        FantasyPointsBreakdownResponse response = FantasyPointsBreakdownCalculator.toResponse(b);
        assertEquals(b.total(), response.total());
        assertEquals(3, response.paradas());
    }

    @Test
    void delGolesYAsistenciasSumanCorrectamente() {
        FantasyPointsBreakdownCalculator.Input in = new FantasyPointsBreakdownCalculator.Input(
                "DEL",
                90,
                2,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                false,
                4
        );
        FantasyPointsBreakdownCalculator.Breakdown b = FantasyPointsBreakdownCalculator.calculate(in);
        assertEquals(10, b.goles());
        assertEquals(4, b.asistencias());
        assertEquals(2, b.notaPeriodico());
        assertEquals(b.total(), FantasyPointsBreakdownCalculator.totalPoints(in));
    }

    @Test
    void porteroParadasDosPorUno() {
        FantasyPointsBreakdownCalculator.Input in = new FantasyPointsBreakdownCalculator.Input(
                "POR",
                90,
                0,
                0,
                0,
                0,
                4,
                1,
                0,
                0,
                false,
                4
        );
        FantasyPointsBreakdownCalculator.Breakdown b = FantasyPointsBreakdownCalculator.calculate(in);
        assertEquals(2, b.paradas());
        assertEquals(b.total(), FantasyPointsBreakdownCalculator.totalPoints(in));
    }

    @Test
    void notaNullEnDirectoNoSumaNota() {
        FantasyPointsBreakdownCalculator.Input in = new FantasyPointsBreakdownCalculator.Input(
                "DEL",
                70,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                false,
                null
        );
        FantasyPointsBreakdownCalculator.Breakdown b = FantasyPointsBreakdownCalculator.calculate(in);
        assertEquals(0, b.notaPeriodico());
        assertEquals(8, b.total());
    }

    @Test
    void desgloseSumaIgualTotal() {
        FantasyPointsBreakdownCalculator.Input in = new FantasyPointsBreakdownCalculator.Input(
                "DEF",
                90,
                0,
                1,
                8,
                6,
                0,
                0,
                0,
                0,
                false,
                5
        );
        FantasyPointsBreakdownCalculator.Breakdown b = FantasyPointsBreakdownCalculator.calculate(in);
        assertEquals(b.total(), b.minutos() + b.goles() + b.asistencias() + b.regates() + b.recuperaciones()
                + b.paradas() + b.porteriaCero() + b.golesEncajados() + b.notaPeriodico() + b.amarillas()
                + b.rojas() + b.lesion());
    }
}
