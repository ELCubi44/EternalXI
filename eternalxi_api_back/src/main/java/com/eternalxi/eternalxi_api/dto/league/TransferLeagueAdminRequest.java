package com.eternalxi.eternalxi_api.dto.league;

/**
 * Contrato app móvil: delegación de administrador.
 */
public record TransferLeagueAdminRequest(
        Long idAdminActual,
        Long idNuevoAdmin
) {}
