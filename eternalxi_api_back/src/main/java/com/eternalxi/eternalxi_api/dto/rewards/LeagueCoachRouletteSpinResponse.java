package com.eternalxi.eternalxi_api.dto.rewards;

import java.util.List;

/**
 * Resultado del giro de ruleta de entrenador.
 * <p>
 * Si {@code alreadyUsed} es {@code false} y el giro se completó con entrenadores libres, {@code itemsRuleta} contiene
 * la lista completa de entrenadores disponibles en la liga en ese momento (incluye al ganador). Si la ruleta ya estaba
 * usada, {@code itemsRuleta} puede ir vacío; {@code entrenadorGanador} refleja el entrenador ya asignado por el giro
 * anterior cuando exista.
 * </p>
 */
public record LeagueCoachRouletteSpinResponse(
        boolean alreadyUsed,
        LeagueCoachRouletteItemResponse entrenadorGanador,
        List<LeagueCoachRouletteItemResponse> itemsRuleta,
        int costeRuleta,
        Long puntosRestantes
) {}
