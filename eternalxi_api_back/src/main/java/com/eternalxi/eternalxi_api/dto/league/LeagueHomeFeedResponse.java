package com.eternalxi.eternalxi_api.dto.league;

import java.util.List;

public record LeagueHomeFeedResponse(
        Long idLiga,
        List<LeagueHomeNewsItemResponse> noticiasLesiones,
        List<LeagueHomeTopPlayerResponse> goleadores,
        List<LeagueHomeTopPlayerResponse> asistidores,
        List<LeagueHomeTopPlayerResponse> porteriasCero
) {}