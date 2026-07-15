package com.eternalxi.eternalxi_api.dto.user;

import java.util.List;

public record UserPublicProfileResponse(
        long id,
        String nickname,
        String foto,
        int nivel,
        int tagCode,
        String relacionAmistad,
        Long idAmistad,
        boolean soySolicitante,
        UserPublicStatsResponse stats,
        UserPublicFavoritePlayerResponse jugadorFavorito,
        List<UserPublicLeagueSummaryResponse> ligas
) {
}
