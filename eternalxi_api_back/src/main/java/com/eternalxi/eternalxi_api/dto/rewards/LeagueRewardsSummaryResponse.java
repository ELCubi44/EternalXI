package com.eternalxi.eternalxi_api.dto.rewards;

/**
 * Resumen de recompensas para una liga y usuario.
 * <p>
 * {@code ruletaEntrenadorUsada}: solo indica si el usuario ya consumió el giro de la ruleta de entrenador de esta liga.
 * {@code entrenadorActual}: entrenador marcado como activo en el inventario del participante (si existe), con
 * independencia de la ruleta (p. ej. asignación previa u otro flujo). Puede ser no nulo aunque la ruleta no esté usada.
 * </p>
 */
public record LeagueRewardsSummaryResponse(
        Long idLiga,
        Long idLigaParticipante,
        long puntosRecompensaUsuario,
        long dineroLiga,
        boolean ruletaEntrenadorUsada,
        int costeRuletaEntrenador,
        LeagueCoachRouletteItemResponse entrenadorActual,
        int cartasDisponibles,
        int cartasUsadas,
        java.util.List<LeaguePackCatalogEntryResponse> sobres
) {}
