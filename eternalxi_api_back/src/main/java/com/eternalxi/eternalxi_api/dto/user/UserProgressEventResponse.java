package com.eternalxi.eternalxi_api.dto.user;

public record UserProgressEventResponse(
        Long id,
        String tipo,
        Integer cantidadXp,
        Integer nivelAnterior,
        Integer nivelNuevo,
        String codigoLogro,
        String tituloLogro,
        String descripcionLogro,
        Integer xpLogro,
        Long xpTotalDespues,
        Long xpEnNivelDespues,
        Long xpParaSiguienteDespues
) {}
