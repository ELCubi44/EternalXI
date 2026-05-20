package com.eternalxi.eternalxi_api.dto.rewards;

import java.util.Map;

/**
 * Entrada del catálogo de sobres expuesta en {@code GET .../rewards/summary}.
 * <p>
 * {@code probabilidades} incluye siempre las cinco rarezas (peso 0 si no aplica) para un JSON estable en cliente.
 * </p>
 */
public record LeaguePackCatalogEntryResponse(
        String packType,
        String nombre,
        int costePuntos,
        long presupuestoMin,
        long presupuestoMax,
        Map<String, Integer> probabilidades
) {}
